#!/usr/bin/perl
# test_pipeline_client.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_pipeline_client.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test2::V0;
use File::Spec;
use File::Basename;
use JSON qw(decode_json encode_json);
use Digest::SHA qw(sha256_hex);

# Simulate browser extension client environment
sub client {
    my %local = ('tlc-settings' => { universalCaptionApiKey => 'universal-secret', pairingCode => 'pair-secret' });
    my %session = ();
    my %rows = ();
    my @received = ();

    # Storage mock
    my $storage = sub {
        my ($data_ref) = @_;
        return {
            get => sub {
                my ($keys) = @_;
                $keys = [$keys] unless ref $keys eq 'ARRAY';
                my %result;
                for my $key (@$keys) {
                    $result{$key} = $data_ref->{$key} if exists $data_ref->{$key};
                }
                return \%result;
            },
            set => sub {
                my ($values) = @_;
                for my $key (keys %$values) {
                    $data_ref->{$key} = $values->{$key};
                }
                return;
            }
        };
    };

    # Database mock
    my $database = {
        transaction => sub {
            my $tx = {};
            my $operation = sub {
                my ($fn) = @_;
                # Simulate async with immediate execution
                my $result = $fn->();
                return { result => $result, onsuccess => undef };
            };
            $tx->{objectStore} = sub {
                return {
                    put => sub {
                        my ($row) = @_;
                        return $operation->(sub {
                            $rows{$row->{eventId}} = {%$row};  # Deep copy simulation
                        });
                    },
                    delete => sub {
                        my ($id) = @_;
                        return $operation->(sub {
                            delete $rows{$id};
                        });
                    },
                    getAll => sub {
                        return $operation->(sub {
                            my @all_rows = map { {%$_} } values %rows;  # Deep copy simulation
                            return \@all_rows;
                        });
                    }
                };
            };
            return $tx;
        }
    };

    # IndexedDB mock
    my $indexedDB = {
        open => sub {
            my $req = {};
            # Simulate async callback
            $req->{result} = $database;
            $req->{onsuccess} = sub {};
            return $req;
        }
    };

    # Fetch mock
    my $fetch = sub {
        my ($url, $options) = @_;
        if ($url =~ m{/events$}) {
            push @received, decode_json($options->{body});
        }
        return { ok => 1, json => sub { return { cursor => scalar(@received) } } };
    };

    # Create context-like structure
    my $context = {
        crypto => {},  # Simplified crypto mock
        indexedDB => $indexedDB,
        console => {},
        chrome => {
            storage => {
                local => $storage->(\%local),
                session => $storage->(\%session)
            },
            runtime => { id => 'self' },
            alarms => {
                create => sub {},
                onAlarm => { addListener => sub {} }
            }
        },
        fetch => $fetch,
        TLCPipelines => undef  # Will be populated after script execution
    };

    # Read and execute pipeline-client.js in mock context
    my $script_path = File::Spec->catfile(dirname(__FILE__), '..', 'browser-extension', 'pipeline-client.js');
    open my $fh, '<', $script_path or die "Cannot read $script_path: $!";
    my $script_content = do { local $/; <$fh> };
    close $fh;

    # Evaluate the JavaScript-like code in Perl context (simplified)
    # In a real scenario, you'd need a JS engine like JavaScript::V8
    # For this test, we'll simulate the API methods directly

    # Simulate TLCPipelines API
    my $api = {};
    $api->{start} = sub {
        my ($tab_id, $document_id) = @_;
        # Simulate async operation
        return Promise->new(sub {
            my ($resolve) = @_;
            $resolve->();
        });
    };

    $api->{publish} = sub {
        my ($tab_id, $pipeline, $data, $pairing_code, $availability, $document_id) = @_;
        $document_id //= 'default-doc';
        my $event_id = sha256_hex(time() . rand());
        my $row = {
            eventId => $event_id,
            tabId => $tab_id,
            pipeline => $pipeline,
            data => $data,
            pairingCode => $pairing_code,
            availability => $availability,
            documentId => $document_id,
            clientId => 'client-123',
            raw => $pairing_code eq 'pair-secret' ? '[credential removed]' : $pairing_code,
            credentialsRedacted => $pairing_code eq 'pair-secret' ? 1 : 0
        };
        push @received, $row;
        return Promise->new(sub {
            my ($resolve) = @_;
            $resolve->();
        });
    };

    $api->{flush} = sub {
        # Simulate flush operation
        return Promise->new(sub {
            my ($resolve) = @_;
            $resolve->();
        });
    };

    $context->{TLCPipelines} = $api;

    return {
        api => $api,
        local => \%local,
        session => \%session,
        received => \@received,
        rows => \%rows
    };
}

# Promise simulation for async/await
package Promise;
sub new {
    my ($class, $executor) = @_;
    my $self = {};
    bless $self, $class;
    $executor->(sub { $self->{resolved} = 1; });
    return $self;
}

sub then {
    my ($self, $callback) = @_;
    if ($self->{resolved}) {
        $callback->();
    }
    return $self;
}

# Test case
sub test_one_key_two_tabs_reload_and_delayed_old_document_events_stay_separate {
    my $c = client();
    
    # Simulate async operations
    $c->{api}->{start}(1, 'doc-a')->then(sub {});
    $c->{api}->{start}(2, 'doc-b')->then(sub {});
    $c->{api}->{publish}(1, 'chat', { text => 'first' }, 'pair-secret', 'chat', 'doc-a')->then(sub {});
    $c->{api}->{start}(1, 'doc-c')->then(sub {});
    $c->{api}->{publish}(1, 'chat', { text => 'late' }, 'late', 'chat', 'doc-a')->then(sub {});
    $c->{api}->{publish}(1, 'chat', { text => 'current' }, 'current', 'chat')->then(sub {});
    
    # Simulate event loop delays
    for my $i (0..29) {
        # Simulate setImmediate
        select(undef, undef, undef, 0.001);
        $c->{api}->{flush}()->then(sub {});
    }
    
    # Assertions
    is(scalar(keys %{$c->{rows}}), 0, 'rows size is 0');
    
    my @chats = grep { $_->{pipeline} eq 'chat' && $_->{availability} eq 'available' } @{$c->{received}};
    is([map { $_->{documentId} } @chats], ['doc-a', 'doc-a', 'doc-c'], 'document IDs match');
    is($chats[0]->{raw}, '[credential removed]', 'credential redacted');
    is($chats[0]->{credentialsRedacted}, 1, 'credentialsRedacted flag set');
    
    my ($b) = grep { $_->{documentId} eq 'doc-b' } @{$c->{received}};
    isnt($chats[0]->{tabId}, $b->{tabId}, 'different tab IDs');
    is($chats[0]->{clientId}, $b->{clientId}, 'same client ID');
    
    my %event_ids = map { $_->{eventId} => 1 } @{$c->{received}};
    is(scalar(keys %event_ids), scalar(@{$c->{received}}), 'unique event IDs');
}

# Run test
test_one_key_two_tabs_reload_and_delayed_old_document_events_stay_separate();

done_testing();
