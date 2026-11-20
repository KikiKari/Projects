#!/usr/bin/perl
# gateway_transport.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
# Erzeugt: 2026-11-20 durch ABSTRACTIONS_MANAGER.py

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
    use parent 'Exporter';
    our @EXPORT_OK = qw(TransportUnresolved);
    sub TransportUnresolved {
        my ($message) = @_;
        die "TransportUnresolved: $message\n";
    }
}

sub gateway_token {
    my $token = $ENV{'OPENCLAW_GATEWAY_TOKEN'} // '';
    $token =~ s/^\s+|\s+$//g;
    return $token if $token;

    my $config_path = $ENV{'OPENCLAW_CONFIG_PATH'};
    unless ($config_path) {
        my $home = File::HomeDir->my_home;
        $config_path = File::Spec->catfile($home, '.openclaw', 'openclaw.json');
    }

    return '' unless -f $config_path;

    open my $fh, '<:encoding(UTF-8)', $config_path or return '';
    my $content = do { local $/; <$fh> };
    close $fh;

    eval {
        my $config = decode_json($content);
        $token = $config->{gateway}->{auth}->{token} // '';
        1;
    } or return '';

    $token =~ s/^\s+|\s+$//g;
    return ($token && !$token =~ /^\$\{/) ? $token : '';
}

package GatewayTransport;

sub new {
    my ($class, $state, $save, $url, $token, %args) = @_;
    my $timeout = $args{timeout} // 3900;
    my $interval = $args{interval} // 3;
    my $opener = $args{opener} // sub {
        my ($req, $timeout_val) = @_;
        my $ua = LWP::UserAgent->new;
        $ua->timeout($timeout_val);
        return $ua->request($req);
    };
    my $clock = $args{clock} // sub { time() };
    my $sleep = $args{sleep} // sub { sleep(shift) };

    my ($scheme, $authority) = uri_split($url);
    die "invalid Gateway URL" unless $scheme && $authority;
    die "invalid Gateway URL" unless $scheme eq 'http' || $scheme eq 'https';

    my ($host) = $authority =~ /^([^:]+)/;
    die "unencrypted Gateway must use loopback" if $scheme eq 'http' && $host !~ /^(127\.0\.0\.1|localhost|\[::1\])$/;

    die "Gateway token and positive timeouts required" unless $token && $timeout > 0 && $interval > 0;

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
    
    my $payload_data = {
        node => $node,
        device_id => $device_id,
        request => $request
    };
    my $payload = encode_json($payload_data);
    
    my $req = HTTP::Request->new('POST' => $self->{url});
    $req->header('Authorization' => 'Bearer ' . $self->{token});
    $req->header('Content-Type' => 'application/json');
    $req->content($payload);
    
    my $timeout_val = ($node eq 'node4') ? 150 : 40;
    my $result = $self->{opener}->($req, $timeout_val);
    
    die TransportUnresolved("Gateway request failed") unless $result->is_success;
    
    my $raw = $result->content;
    die "response too large" if length($raw) > 4_000_000;
    
    my $data = decode_json($raw);
    die "invalid gateway response" unless ref($data) eq 'HASH' && exists $data->{result};
    
    if (defined $device_id && (!exists $data->{device_id} || $data->{device_id} ne $device_id)) {
        die "gateway device identity mismatch";
    }
    
    return $data->{result};
}

sub available {
    my ($self) = @_;
    my $result = $self->_request('node1', { operation => 'availability' });
    die TransportUnresolved("invalid node availability") unless ref($result) eq 'HASH';
    return $result;
}

sub _release {
    my ($self, $original, $entry) = @_;
    return if $entry->{released};
    
    eval {
        my $result = $self->_request($original->{selected_node}, {
            operation => 'release',
            job_id => $original->{job_id},
            attempt_id => $original->{attempt_id}
        }, $original->{selected_device_id});
        
        if (ref($result) eq 'HASH' && $result->{status} eq 'released' &&
            $result->{job_id} eq $original->{job_id} &&
            $result->{attempt_id} eq $original->{attempt_id} &&
            $result->{selected_node} eq $original->{selected_node} &&
            $result->{target_language} eq $original->{target_language}) {
            $entry->{released} = 1;
            $self->{save}->($self->{state});
        }
    };
    # Ignore errors - retry cleanup later
}

sub release_pending {
    my ($self) = @_;
    my $auftraege = $self->{state}->{auftraege} // {};
    
    for my $key (keys %$auftraege) {
        my $entry = $auftraege->{$key};
        if (ref($entry) eq 'HASH' && 
            ($entry->{status} eq 'completed' || $entry->{status} eq 'rejected' || $entry->{status} eq 'failed') &&
            ref($entry->{job}) eq 'HASH') {
            $self->_release($entry->{job}, $entry);
        }
    }
}

sub reject {
    my ($self, $job, $reason) = @_;
    return unless $job->{source_sha256} && $job->{target_language};
    
    my $key = $job->{source_sha256} . ':' . $job->{target_language};
    my $entry = $self->{state}->{auftraege}->{$key};
    
    return unless ref($entry) eq 'HASH' && $entry->{status} eq 'completed';
    
    if (($entry->{job}//{})->{attempt_id} ne $job->{attempt_id}) {
        die TransportUnresolved("rejected attempt identity mismatch");
    }
    
    $entry->{status} = 'rejected';
    $entry->{validation_error} = substr("$reason", 0, 500);
    $self->{save}->($self->{state});
}

sub call {
    my ($self, $job) = @_;
    
    die "missing source identity" unless 
        $job->{source_sha256} && $job->{target_language} && $job->{selected_device_id};
    
    my $key = $job->{source_sha256} . ':' . $job->{target_language};
    my $entries = $self->{state}->{auftraege} //= {};
    my $entry = $entries->{$key};
    
    my $fresh = 0;
    my $original;
    
    if (ref($entry) eq 'HASH' && $entry->{status} eq 'rejected') {
        $self->_release($entry->{job}, $entry);
        
        if (!$entry->{released}) {
            die TransportUnresolved("rejected attempt release is unresolved");
        }
        
        my $previous = $entry;
        $original = { %$job, attempt_id => _generate_uuid() };
        $entry = {
            job => $original,
            status => 'submitted',
            previous_attempts => [
                @{$previous->{previous_attempts} // []},
                {
                    job_id => $previous->{job}->{job_id},
                    attempt_id => $previous->{job}->{attempt_id},
                    selected_node => $previous->{job}->{selected_node},
                    validation_error => $previous->{validation_error},
                }
            ]
        };
        $entries->{$key} = $entry;
        $self->{save}->($self->{state});
        $fresh = 1;
    } else {
        $fresh = !defined $entry;
    }
    
    if (!defined $entry) {
        $original = { %$job, attempt_id => _generate_uuid() };
        $entry = { job => $original, status => 'submitted' };
        $entries->{$key} = $entry;
        # If this write fails there must be no remote submission.
        $self->{save}->($self->{state});
    }
    
    $original = $entry->{job};
    # The dispatcher verifies the job object after transport returns.
    @$job{keys %$original} = values %$original;
    
    if (defined $entry->{response}) {
        $self->_release($original, $entry);
        return $entry->{response};
    }
    
    if ($entry->{status} eq 'failed' || $entry->{status} eq 'unknown') {
        die TransportUnresolved("attempt requires reconciliation");
    }
    
    my $status;
    if ($fresh) {
        eval {
            $status = $self->_request($original->{selected_node}, {
                operation => 'execute',
                job => $original
            }, $original->{selected_device_id});
        };
        # Ignore errors - the request may have been accepted. Query, never resend.
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
        
        die TransportUnresolved("attempt is not known by the node") unless ref($status) eq 'HASH';
        
        if ($status->{job_id} ne $original->{job_id} ||
            $status->{attempt_id} ne $original->{attempt_id} ||
            $status->{selected_node} ne $original->{selected_node} ||
            $status->{target_language} ne $original->{target_language}) {
            die TransportUnresolved("status identity mismatch");
        }
        
        my $state = $status->{status};
        
        if ($state eq 'completed') {
            my $response = $status->{response};
            
            if (ref($response) ne 'HASH' || 
                $response->{status} ne 'ok' ||
                $response->{job_id} ne $original->{job_id} ||
                $response->{selected_node} ne $original->{selected_node} ||
                $response->{target_language} ne $original->{target_language} ||
                ref($response->{code}) ne '' ||  # Check if it's not a string
                !$response->{code} || 
                $response->{code} =~ /^\s*$/) {
                die TransportUnresolved("invalid translation result");
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
            $self->_release($original, $entry) if $state eq 'failed';
            die TransportUnresolved("attempt requires reconciliation");
        }
        
        if ($state ne 'running' || $self->{clock}->() >= $deadline) {
            die TransportUnresolved("attempt is unresolved");
        }
        
        $self->{sleep}->($self->{interval});
        $status = undef;
    }
}

sub _generate_uuid {
    my @chars = ('a'..'f', '0'..'9');
    my $uuid = '';
    for my $i (0..31) {
        $uuid .= $chars[int(rand(@chars))];
        $uuid .= '-' if ($i == 7 || $i == 11 || $i == 15 || $i == 19);
    }
    return $uuid;
}

1;
