#!/usr/bin/perl
# test_status_overview_player.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_status_overview_player.cjs
# Erzeugt: 2026-11-02 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Test2::V0;
use File::Slurp qw(read_file);
use File::Spec;

# Mock classes and functions to simulate JavaScript environment
package Element {
    sub new {
        my ($class, $tag) = @_;
        my $self = {
            tag => $tag,
            style => {},
            classList => { toggle => sub {} },
            children => [],
            listeners => {},
            muted => 0,
            paused => 1,
            src => '',
            currentTime => 0,
        };
        bless $self, $class;
    }

    sub append {
        my ($self, @nodes) = @_;
        push @{$self->{children}}, @nodes;
    }

    sub addEventListener {
        my ($self, $name, $fn) = @_;
        $self->{listeners}{$name} //= {};
        $self->{listeners}{$name}{$fn} = 1;
    }

    sub removeEventListener {
        my ($self, $name, $fn) = @_;
        delete $self->{listeners}{$name}{$fn} if exists $self->{listeners}{$name}{$fn};
    }

    sub emit {
        my ($self, $name) = @_;
        if (exists $self->{listeners}{$name}) {
            for my $fn (keys %{$self->{listeners}{$name}}) {
                $fn->();
            }
        }
    }

    sub pause {
        my ($self) = @_;
        $self->{paused} = 1;
    }

    sub removeAttribute {
        my ($self) = @_;
        $self->{src} = '';
    }

    sub load {
        my ($self) = @_;
        # No-op
    }

    sub play {
        my ($self) = @_;
        $self->{paused} = 0;
        # Simulate async behavior with a delayed execution
        # In real scenario, this would be handled differently
        return {}; # Return a mock promise-like object
    }
}

# Load the JavaScript source code
my $source_path = File::Spec->catfile(File::Spec->updir(), 'browser-extension', 'status-overview-player.js');
my $source = read_file($source_path);

# Test 1: nine independent tiles start muted and try the next source
subtest 'nine independent tiles start muted and try the next source' => sub {
    my $grid = Element->new('main');
    my $change;
    my @rows = map {
        {
            handle => "user$_",
            status => 'online',
            checkedAt => time(),
            media => [
                { protocol => 'hls', url => 'https://example.test/bad.m3u8' },
                { protocol => 'hls', url => 'https://example.test/good.m3u8' }
            ]
        }
    } (0..8);

    my $context = {
        document => {
            getElementById => sub { $grid },
            createElement => sub { Element->new($_[0]) }
        },
        chrome => {
            runtime => {
                sendMessage => sub { return { ok => 1, config => { interval => 5 }, rows => \@rows } }
            },
            storage => {
                onChanged => {
                    addListener => sub { $change = $_[0]; }
                }
            }
        },
        window => {
            addEventListener => sub {}
        },
        URL => undef,
        Date => undef,
        Promise => undef,
        Number => undef,
        String => undef,
        Array => undef,
        JSON => undef,
        Object => undef,
        setTimeout => sub { sleep(0.02); }, # Simplified timeout simulation
        clearTimeout => sub {}
    };

    # Simulate running the JavaScript code in context
    # This is a placeholder since we cannot directly execute JS in Perl
    # We assume the code populates the grid appropriately

    # Assertions based on expected behavior
    is(scalar(@{$grid->{children}}), 29, 'Grid has 29 children');

    for my $i (0..8) {
        my $tile = $grid->{children}[$i];
        is($tile->{children}[1]->{muted}, 1, "Tile $i video is muted");
        like($tile->{children}[1]->{src}, qr/good/, "Tile $i video src contains 'good'");
        like($tile->{children}[2]->{textContent}, qr/abgespielt/, "Tile $i text content matches");
    }

    # Update row and trigger change
    $rows[0] = {
        handle => 'user0',
        status => 'offline',
        checkedAt => time(),
        media => []
    };
    $change->({'tlc-overview-row-0' => {}}, 'session');

    # Assertions after update
    is($grid->{children}[0]->{hidden}, 1, 'First tile is hidden');
    like($grid->{children}[1]->{children}[1]->{src}, qr/good/, "Second tile video src still contains 'good'");
};

# Test 2: retry switches only the requested tile, tries remaining sources and can restart a single source
subtest 'retry switches only the requested tile, tries remaining sources and can restart a single source' => sub {
    my $grid = Element->new('main');
    my $change;
    my @rows = map {
        {
            handle => "user$_",
            status => 'online',
            checkedAt => time() - 600000,
            media => [
                { protocol => 'hls', url => "https://example.test/${_}-first.m3u8" },
                { protocol => 'hls', url => "https://example.test/${_}-bad.m3u8" },
                { protocol => 'hls', url => "https://example.test/${_}-next.m3u8" }
            ]
        }
    } (0..8);

    $_->{checkedAt} = time() for @rows;

    my $context = {
        document => {
            getElementById => sub { $grid },
            createElement => sub { Element->new($_[0]) }
        },
        chrome => {
            runtime => {
                sendMessage => sub { return { ok => 1, config => { interval => 5 }, rows => \@rows } }
            },
            storage => {
                onChanged => {
                    addListener => sub { $change = $_[0]; }
                }
            }
        },
        window => {
            addEventListener => sub {}
        },
        URL => undef,
        Date => undef,
        Promise => undef,
        Number => undef,
        String => undef,
        Array => undef,
        JSON => undef,
        Object => undef,
        setTimeout => sub { sleep(0.02); },
        clearTimeout => sub {}
    };

    # Simulate running the JavaScript code in context
    # Placeholder for actual execution logic

    # Assertions based on expected behavior
    my $untouched = $grid->{children}[1]->{children}[1]->{src};
    like($grid->{children}[0]->{children}[1]->{src}, qr/first/, 'First tile src contains "first"');

    $change->({'tlc-overview-retry-0' => { newValue => { handle => 'user0', nonce => 1 } }}, 'session');

    like($grid->{children}[0]->{children}[1]->{src}, qr/next/, 'First tile src now contains "next"');
    is($grid->{children}[1]->{children}[1]->{src}, $untouched, 'Second tile src unchanged');

    $change->({'tlc-overview-retry-0' => { newValue => { handle => 'other', nonce => 2 } }}, 'session');
    like($grid->{children}[0]->{children}[1]->{src}, qr/next/, 'First tile src still contains "next"');

    $rows[0]->{media} = [{ protocol => 'hls', url => 'https://example.test/only.m3u8' }];
    $rows[0]->{checkedAt} = time();
    $change->({'tlc-overview-row-0' => {}}, 'session');

    $change->({'tlc-overview-retry-0' => { newValue => { handle => 'user0', nonce => 3 } }}, 'session');
    like($grid->{children}[0]->{children}[1]->{src}, qr/only/, 'First tile src now contains "only"');
};

# Test 3: selects first online entries among 20, reverse order and four-tile mode without restarting retained streams
subtest 'selects first online entries among 20, reverse order and four-tile mode without restarting retained streams' => sub {
    my $grid = Element->new('main');
    my $change;
    my $config = {
        interval => 5,
        expanded => 1,
        grid2 => 1,
        reverse => 0,
        autoSort => 1
    };
    my @rows = map {
        {
            handle => "user$_",
            status => ($_ % 2) ? 'online' : 'offline',
            checkedAt => time(),
            media => [{ protocol => 'hls', url => "https://example.test/${_}.m3u8" }]
        }
    } (0..19);

    my $ctx = {
        document => {
            getElementById => sub { $grid },
            createElement => sub { Element->new($_[0]) }
        },
        chrome => {
            runtime => {
                sendMessage => sub { return { ok => 1, config => $config, rows => \@rows } }
            },
            storage => {
                onChanged => {
                    addListener => sub { $change = $_[0]; }
                }
            }
        },
        window => {
            addEventListener => sub {}
        },
        URL => undef,
        Date => undef,
        Promise => undef,
        Number => undef,
        String => undef,
        Array => undef,
        JSON => undef,
        Map => undef,
        Object => undef,
        setTimeout => sub { sleep(0.02); },
        clearTimeout => sub {}
    };

    # Simulate running the JavaScript code in context
    # Placeholder for actual execution logic

    # Helper function to get shown indices
    my $shown = sub {
        my @indices;
        for my $i (0..19) {
            push @indices, $i unless $grid->{children}[$i]->{hidden};
        }
        return \@indices;
    };

    is($shown->(), [1,3,5,7], 'Initial shown indices match');

    $config->{reverse} = 1;
    $change->({'tlc-overview-config' => {}}, 'local');
    is($shown->(), [13,15,17,19], 'Reversed shown indices match');
    is($grid->{children}[19]->{style}->{order}, '0', 'Order style is 0');

    $config->{grid2} = 0;
    $change->({'tlc-overview-config' => {}}, 'local');
    is(scalar(@{$shown->()}), 9, 'Nine items shown in non-grid2 mode');
    is($grid->{children}[19]->{style}->{order}, '0', 'Order style remains 0');

    $config->{expanded} = 0;
    $change->({'tlc-overview-config' => {}}, 'local');
    is($shown->(), [1,3,5,7], 'Expanded false shown indices match');
};

done_testing();
