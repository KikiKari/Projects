#!/usr/bin/perl
# gateway_transport.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON qw(decode_json encode_json);
use URI::Split qw(uri_split);
use LWP::UserAgent;
use HTTP::Request;
use Time::HiRes qw(time sleep);
use File::Spec;
use File::HomeDir;

package TransportUnresolved {
    use parent 'Exception::Class::Base';
}

sub gateway_token {
    my $token = $ENV{'OPENCLAW_GATEWAY_TOKEN'} // '';
    $token =~ s/^\s+|\s+$//g;
    if ($token) {
        return $token;
    }
    my $config_path = $ENV{'OPENCLAW_CONFIG_PATH'};
    if (!$config_path) {
        my $home = File::HomeDir->my_home;
        $config_path = File::Spec->catfile($home, '.openclaw', 'openclaw.json');
    }
    if (!-f $config_path) {
        return '';
    }
    open my $fh, '<:encoding(UTF-8)', $config_path or return '';
    my $content = do { local $/; <$fh> };
    close $fh;
    my $config;
    eval {
        $config = decode_json($content);
    };
    if ($@) {
        return '';
    }
    $token = $config->{gateway}->{auth}->{token} // '';
    if (ref($token) || $token =~ /^\$\{/) {
        return '';
    }
    $token =~ s/^\s+|\s+$//g;
    return $token;
}

package GatewayTransport {
    sub new {
        my ($class, $state, $save, $url, $token, %args) = @_;
        my $timeout = $args{timeout} // 3900;
        my $interval = $args{interval} // 3;
        my $opener = $args{opener} // sub {
            my $req = shift;
            my $ua = LWP::UserAgent->new;
            $ua->timeout(150);
            return $ua->request($req);
        };
        my $clock = $args{clock} // sub { time() };
        my $sleep = $args{sleep} // sub { sleep(shift) };

        my ($scheme, $authority) = URI::Split::uri_split($url);
        if (($scheme ne 'http' && $scheme ne 'https') || !$authority) {
            die "invalid Gateway URL";
        }
        if ($scheme eq 'http' && $authority !~ /^(127\.0\.0\.1|localhost|\[::1\])$/) {
            die "unencrypted Gateway must use loopback";
        }
        if (!$token || $token =~ /^\s*$/ || $timeout <= 0 || $interval <= 0) {
            die "Gateway token and positive timeouts required";
        }
        $token =~ s/^\s+|\s+$//g;

        return bless {
            state => $state,
            save => $save,
            url => $url,
            token => $token,
            timeout => $timeout,
            interval => $interval,
            opener => $opener,
            clock => $clock,
            sleep => $sleep,
        }, $class;
    }

    sub _request {
        my ($self, $node, $request, $device_id) = @_;
        my $payload = encode_json({
            node => $node,
            device_id => $device_id,
            request => $request
        });
        my $req = HTTP::Request->new('POST' => $self->{url});
        $req->header('Authorization' => 'Bearer ' . $self->{token});
        $req->header('Content-Type' => 'application/json');
        $req->content($payload);

        my $timeout = ($node eq 'node4') ? 150 : 40;
        local $SIG{ALRM} = sub { die "TIMEOUT\n" };
        alarm($timeout);
        my $result = eval { $self->{opener}->($req) };
        alarm(0);
        if ($@ && $@ eq "TIMEOUT\n") {
            TransportUnresolved->throw("Gateway request failed");
        } elsif ($@) {
            TransportUnresolved->throw("Gateway request failed", $@);
        }

        if (!$result->is_success) {
            TransportUnresolved->throw("Gateway request failed");
        }

        my $raw = $result->decoded_content;
        if (length($raw) > 4_000_000) {
            TransportUnresolved->throw("response too large");
        }

        my $data;
        eval {
            $data = decode_json($raw);
        };
        if ($@) {
            TransportUnresolved->throw("invalid gateway response");
        }

        if (ref($data) ne 'HASH' || !exists $data->{result}) {
            TransportUnresolved->throw("invalid gateway response");
        }

        if (defined $device_id && exists $data->{device_id} && $data->{device_id} ne $device_id) {
            TransportUnresolved->throw("gateway device identity mismatch");
        }

        return $data->{result};
    }

    sub available {
        my ($self) = @_;
        my $result = $self->_request('node1', { operation => 'availability' });
        if (ref($result) ne 'HASH') {
            TransportUnresolved->throw("invalid node availability");
        }
        return $result;
    }

    sub _release {
        my ($self, $original, $entry) = @_;
        if ($entry->{released}) {
            return;
        }
        my $result;
        eval {
            $result = $self->_request($original->{selected_node}, {
                operation => 'release',
                job_id => $original->{job_id},
                attempt_id => $original->{attempt_id}
            }, $original->{selected_device_id});
        };
        if ($@) {
            return; # Retry cleanup later; the result is durable in manager state.
        }
        if (ref($result) eq 'HASH' && $result->{status} eq 'released' &&
            all_equal($result, $original, qw(job_id attempt_id selected_node target_language))) {
            $entry->{released} = 1;
            $self->{save}->($self->{state});
        }
    }

    sub release_pending {
        my ($self) = @_;
        my $entries = $self->{state}->{auftraege} // {};
        for my $entry (values %$entries) {
            if (ref($entry) eq 'HASH' && 
                ($entry->{status} eq 'completed' || $entry->{status} eq 'failed' || $entry->{status} eq 'unknown') &&
                ref($entry->{job}) eq 'HASH') {
                $self->_release($entry->{job}, $entry);
            }
        }
    }

    sub all_equal {
        my ($hash1, $hash2, @keys) = @_;
        for my $key (@keys) {
            return 0 if !exists $hash1->{$key} || !exists $hash2->{$key} || $hash1->{$key} ne $hash2->{$key};
        }
        return 1;
    }

    sub call {
        my ($self, $job) = @_;
        if (!$job->{source_sha256} || !$job->{target_language} || !$job->{selected_device_id}) {
            die "missing source identity";
        }
        my $key = $job->{source_sha256} . ':' . $job->{target_language};
        my $entries = $self->{state}->{auftraege} //= {};
        my $entry = $entries->{$key};
        my $fresh = !defined $entry;
        my $original;
        if ($fresh) {
            $original = { %$job, attempt_id => generate_uuid() };
            $entry = { job => $original, status => 'submitted' };
            $entries->{$key} = $entry;
            # If this write fails there must be no remote submission.
            $self->{save}->($self->{state});
        } else {
            $original = $entry->{job};
        }
        # The dispatcher verifies the job object after transport returns.
        @$job{keys %$original} = values %$original;
        if (defined $entry->{response}) {
            $self->_release($original, $entry);
            return $entry->{response};
        }
        if ($entry->{status} eq 'failed' || $entry->{status} eq 'unknown') {
            TransportUnresolved->throw("attempt requires reconciliation");
        }
        my $status;
        if ($fresh) {
            eval {
                $status = $self->_request($original->{selected_node}, { operation => 'execute', job => $original },
                                         $original->{selected_device_id});
            };
            if ($@) {
                # The request may have been accepted. Query, never resend.
            }
        }
        my $deadline = $self->{clock}->() + $self->{timeout};
        while (1) {
            if (!defined $status) {
                $status = $self->_request($original->{selected_node}, {
                    operation => 'status',
                    job_id => $original->{job_id},
                    attempt_id => $original->{attempt_id}
                }, $original->{selected_device_id});
            }
            if (ref($status) ne 'HASH') {
                TransportUnresolved->throw("attempt is not known by the node");
            }
            if (!all_equal($status, $original, qw(job_id attempt_id selected_node target_language))) {
                TransportUnresolved->throw("status identity mismatch");
            }
            my $state = $status->{status};
            if ($state eq 'completed') {
                my $response = $status->{response};
                if (ref($response) ne 'HASH' || $response->{status} ne 'ok' ||
                    !all_equal($response, $original, qw(job_id selected_node target_language)) ||
                    !defined $response->{code} || $response->{code} !~ /\S/) {
                    TransportUnresolved->throw("invalid translation result");
                }
                $entry->{response} = $response;
                $entry->{status} = 'completed';
                $self->{save}->($self->{state});
                $self->_release($original, $entry);
                return $response;
            }
            if ($state eq 'failed' || $state eq 'unknown') {
                $entry->{status} = $state;
                $self->{save}->($self->{state});
                $self->_release($original, $entry);
                TransportUnresolved->throw("attempt requires reconciliation");
            }
            if ($state ne 'running' || $self->{clock}->() >= $deadline) {
                TransportUnresolved->throw("attempt is unresolved");
            }
            $self->{sleep}->($self->{interval});
            $status = undef;
        }
    }

    sub generate_uuid {
        my @chars = ('a'..'f', 0..9);
        my $uuid = '';
        for (1..8) { $uuid .= $chars[rand @chars] }
        $uuid .= '-';
        for (1..4) { $uuid .= $chars[rand @chars] }
        $uuid .= '-';
        for (1..4) { $uuid .= $chars[rand @chars] }
        $uuid .= '-';
        for (1..4) { $uuid .= $chars[rand @chars] }
        $uuid .= '-';
        for (1..12) { $uuid .= $chars[rand @chars] }
        return $uuid;
    }
}

1;
