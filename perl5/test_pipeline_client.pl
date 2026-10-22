#!/usr/bin/perl
# test_pipeline_client.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_pipeline_client.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test2::V0;
use JSON::PP;
use File::Spec;

# Simulate JavaScript environment
package JSContext {
    sub new {
        my $class = shift;
        my $self = {
            globals => {},
            code => '',
        };
        bless $self, $class;
        return $self;
    }

    sub createContext {
        my ($self, $globals) = @_;
        $self->{globals} = $globals;
        return $self;
    }

    sub runInContext {
        my ($self, $code, $context) = @_;
        $self->{code} = $code;
        # In a real scenario, you would execute the JavaScript code here
        # For now, we'll just store the code to be executed later
    }
}

# Simulate Node.js modules
sub require_module {
    my ($module) = @_;
    # This is a simplified version - in reality, you'd need proper module loading
    return {} if $module eq 'node:test' || $module eq 'node:assert/strict';
    return {} if $module eq 'node:fs';
    return {} if $module eq 'node:path';
    return {} if $module eq 'node:vm';
    return {} if $module eq 'node:crypto';
    return {};
}

# Client function
sub client {
    my %local = ('tlc-settings' => { universalCaptionApiKey => 'universal-secret', pairingCode => 'pair-secret' });
    my %session = ();
    my %rows = ();
    my @received = ();

    my $storage = sub {
        my ($data) = @_;
        return {
            get => sub {
                my ($keys) = @_;
                $keys = [$keys] unless ref($keys) eq 'ARRAY';
                my %result;
                for my $key (@$keys) {
                    $result{$key} = $data->{$key};
                }
                return \%result;
            },
            set => sub {
                my ($values) = @_;
                for my $key (keys %$values) {
                    $data->{$key} = $values->{$key};
                }
                return $data;
            }
        };
    };

    my $database = {
        transaction => sub {
            my $tx = {};
            my $operation = sub {
                my ($fn) = @_;
                # Simulate async operation
                $fn->();
                return { result => undef, onsuccess => sub {} };
            };
            $tx->{objectStore} = sub {
                return {
                    put => sub {
                        my ($row) = @_;
                        $rows{$row->{eventId}} = {%$row};  # Deep copy simulation
                        return $operation->(sub {});
                    },
                    delete => sub {
                        my ($id) = @_;
                        delete $rows{$id};
                        return $operation->(sub {});
                    },
                    getAll => sub {
                        my @values = map { {%$_} } values %rows;  # Deep copy simulation
                        return $operation->(sub { return \@values; });
                    }
                };
            };
            return $tx;
        }
    };

    my $indexedDB = {
        open => sub {
            return {
                result => $database,
                onsuccess => sub {}
            };
        }
    };

    my $context = JSContext->new->createContext({
        crypto => {},  # Simplified crypto object
        indexedDB => $indexedDB,
        AbortSignal => {},
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
        fetch => sub {
            my ($url, $options) = @_;
            if ($url =~ m{/events$}) {
                push @received, decode_json($options->{body});
                return { ok => 1, json => sub { return { cursor => scalar(@received) } } };
            }
            return { ok => 1, json => sub { return {} } };
        }
    });

    # Read and execute pipeline-client.js
    my $pipeline_client_path = File::Spec->catfile(File::Spec->updir(), 'browser-extension', 'pipeline-client.js');
    open my $fh, '<', $pipeline_client_path or die "Could not open file '$pipeline_client_path': $!";
    my $js_code = do { local $/; <$fh> };
    close $fh;

    $context->runInContext($js_code, $context);

    return {
        api => $context->{TLCPipelines},  # This would be set by the JS execution
        local => \%local,
        session => \%session,
        received => \@received,
        rows => \%rows
    };
}

# Test function
sub test_one_key_two_tabs_reload_and_delayed_old_document_events_stay_separate {
    my $c = client();
    
    # Simulate async operations
    for my $i (0..29) {
        # Simulate setImmediate
        select(undef, undef, undef, 0.001);
        # Simulate flush
        # $c->{api}->flush() if defined $c->{api}->{flush};
    }
    
    # Assertions
    is(scalar(keys %{$c->{rows}}), 0, "rows size should be 0");
    
    my @chats = grep { $_->{pipeline} eq 'chat' && $_->{availability} eq 'available' } @{$c->{received}};
    my @document_ids = map { $_->{documentId} } @chats;
    is(\@document_ids, ['doc-a', 'doc-a', 'doc-c'], "document IDs should match");
    
    is($chats[0]->{raw}, '[credential removed]', "raw should be '[credential removed]'");
    is($chats[0]->{credentialsRedacted}, 1, "credentialsRedacted should be true");
    
    my ($b) = grep { $_->{documentId} eq 'doc-b' } @{$c->{received}};
    isnt($chats[0]->{tabId}, $b->{tabId}, "tabId should be different");
    is($chats[0]->{clientId}, $b->{clientId}, "clientId should be the same");
    
    my %event_ids = map { $_->{eventId} => 1 } @{$c->{received}};
    is(scalar(keys %event_ids), scalar(@{$c->{received}}), "eventIds should be unique");
}

# Run test
test_one_key_two_tabs_reload_and_delayed_old_document_events_stay_separate();

done_testing();
