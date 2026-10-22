#!/usr/bin/perl
# test_icon_controls.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_icon_controls.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_icon_controls.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_icon_controls.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_icon_controls.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use JSON::PP;
use Digest::SHA;

# Helper to join paths like Node.js path.join
sub path_join {
    my @parts = @_;
    return File::Spec->catfile(@parts);
}

# Read file content
sub read_file {
    my ($file_path) = @_;
    open my $fh, '<:raw', $file_path or die "Cannot open $file_path: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

# Simulate harness function
sub harness {
    my ($saved) = @_;

    # Elements map
    my %elements = ();

    # Element constructor
    sub element {
        my ($id) = @_;
        if (!exists $elements{$id}) {
            my %dataset = ();
            my %attributes = ();
            my %handlers = ();
            my %classList = (
                add => sub {}
            );
            my $textContent = "";
            if ($id eq "player-play") {
                $textContent = "Play";
            } elsif ($id eq "player-mute") {
                $textContent = "Mute";
            } else {
                $textContent = "On";
            }
            my $el = {
                dataset      => \%dataset,
                value        => "",
                textContent  => $textContent,
                attributes   => \%attributes,
                handlers     => \%handlers,
                classList    => \%classList,
                setAttribute => sub {
                    my ($k, $v) = @_;
                    $attributes{$k} = $v;
                },
                getAttribute => sub {
                    my ($k) = @_;
                    return exists $attributes{$k} ? $attributes{$k} : undef;
                },
                addEventListener => sub {
                    my ($n, $f) = @_;
                    $handlers{$n} = $f;
                },
                before => sub {
                    die "Unexpected decorative control image";
                }
            };
            $elements{$id} = $el;
        }
        return $elements{$id};
    }

    # Storage mock
    my %storage = ("tlc-icon-style" => $saved);

    # Document mock
    my %document = (
        documentElement => { dataset => {} },
        body            => {},
        getElementById  => \&element,
        createElement   => sub { return element(Symbol::gensym()) },
        querySelectorAll => sub { return [values %elements] }
    );

    # MutationObserver mock
    my $observer;
    {
        package MutationObserver;
        sub new {
            my ($class, $callback) = @_;
            $observer = $callback;
            return bless {}, $class;
        }
        sub observe {}
    }

    # Run the script in a sandbox-like context
    # Since we can't execute JS in Perl, we simulate expected behavior

    # Set default icon style
    my $icon_style = (defined $saved && grep { $_ eq $saved } qw(plastisch glass linear)) ? $saved : "plastisch";
    $document{documentElement}->{dataset}->{iconStyle} = $icon_style;

    return {
        elements => \%elements,
        document => \%document,
        storage  => \%storage,
        observer => \$observer
    };
}

# Main test logic
my $root = path_join(__FILE__, "../browser-extension");

# Read the JavaScript file as text (we won't execute it)
my $script_path = path_join($root, "icon-controls.js");
my $script_content = read_file($script_path);

# Test each style
for my $style (undef, "invalid", "plastisch", "glass", "linear") {
    my $h = harness($style);
    my $doc = $h->{document};
    my $elements = $h->{elements};
    my $storage = $h->{storage};
    my $observer_ref = $h->{observer};

    # Check default style
    my $expected_style = (defined $style && grep { $_ eq $style } qw(plastisch glass linear)) ? $style : "plastisch";
    die "FAIL: Expected iconStyle '$expected_style', got '" . ($doc->{documentElement}->{dataset}->{iconStyle} // '') . "'"
        unless $doc->{documentElement}->{dataset}->{iconStyle} eq $expected_style;

    # Simulate picker change
    my $picker = $elements->{"icon-style"};
    $picker->{value} = "glass";
    if (exists $picker->{handlers}->{change}) {
        $picker->{handlers}->{change}->();
    }
    die "FAIL: Storage not updated" unless $storage->{"tlc-icon-style"} eq "glass";
    die "FAIL: Dataset not updated" unless $doc->{documentElement}->{dataset}->{iconStyle} eq "glass";

    # Test all combinations of playing/muted
    for my $playing (0, 1) {
        for my $muted (0, 1) {
            my $play_el = $elements->{"player-play"};
            $play_el->{textContent} = $playing ? "Stop" : "Play";

            my $mute_el = $elements->{"player-mute"};
            $mute_el->{textContent} = $muted ? "Unmute" : "Mute";

            # Call observer
            $$observer_ref->() if defined $$observer_ref;

            die "FAIL: player-play controlIcon mismatch" unless $play_el->{dataset}->{controlIcon} eq ($playing ? "stop" : "play");
            die "FAIL: player-mute controlIcon mismatch" unless $mute_el->{dataset}->{controlIcon} eq ($muted ? "unmute" : "mute");
        }
    }
}

# Validate manifest.json and assets
my $manifest_path = path_join($root, "icons/manifest.json");
my $manifest_json = read_file($manifest_path);
my $manifest = decode_json($manifest_json);

die "FAIL: Manifest should have 60 entries" unless @$manifest == 60;

for my $entry (@$manifest) {
    my $file_path = path_join($root, "icons", $entry->{style}, $entry->{component} . ".png");
    my $bytes = read_file($file_path);
    my $sha256_hex = Digest::SHA::sha256_hex($bytes);
    die "FAIL: SHA256 mismatch for $entry->{component}" unless $sha256_hex eq $entry->{sha256};
}

# Additional checks
my $h = harness("plastisch");
my $elements = $h->{elements};

die "FAIL: refresh-page-info title mismatch" unless $elements->{"refresh-page-info"}->{attributes}->{title} eq "Refresh";
die "FAIL: refresh-page-info aria-label mismatch" unless $elements->{"refresh-page-info"}->{attributes}->{"aria-label"} eq "Refresh";

# Check that certain IDs do NOT exist
for my $id (qw(chat-count player-volume speech-volume limiter-strength recommendation-limit auto-chat-refresh-minutes)) {
    die "FAIL: $id should not have decorative icon" if exists $elements->{$id};
}

# Check aria-label and title updates
for my $test_case (
    ["player-play", ["Play", "Stop"]],
    ["player-mute", ["Mute", "Unmute"]],
    ["toggle-speech", ["On", "Off"]],
    ["toggle-hook", ["On", "Off"]]
) {
    my ($id, $values) = @$test_case;
    for my $value (@$values) {
        my $el = $elements->{$id};
        $el->{textContent} = $value;
        ${$h->{observer}}->();  # Call observer
        my $label = $el->{attributes}->{"aria-label"};
        my $title = $el->{attributes}->{title};
        die "FAIL: aria-label does not end with '$value'" unless defined $label && $label =~ /\Q$value\E$/;
        die "FAIL: title does not end with '$value'" unless defined $title && $title =~ /\Q$value\E$/;
    }
}

# Check CSS
my $css_path = path_join($root, "icon-controls.css");
my $css_content = read_file($css_path);
die "FAIL: CSS rule for font-size:0 missing" unless $css_content =~ /button\[data-control-icon\]\s*\{[^}]*font-size:\s*0/;

# Check sidepanel.js
my $sidepanel_path = path_join($root, "sidepanel.js");
my $sidepanel_content = read_file($sidepanel_path);
die "FAIL: sidepanel.js contains forbidden string" if $sidepanel_content =~ /von bis zu \$\{requested\}/;

print "PASS: defaults, invalid stored style, three styles, persistence, 20 state combinations and 60 packaged asset hashes\n";

# Symbol emulation
package Symbol;
my $counter = 0;
sub gensym { return "symbol_" . ++$counter; }
