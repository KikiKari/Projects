#!/usr/bin/perl
# update_readme_stats.py — portiert nach perl5
# Quelle: python, OpenClaw@main:scripts/update_readme_stats.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use JSON qw(decode_json);
use Encode qw(decode);

# Fetch ClawHub stats and update README.md download counts and security status.

my $API_BASE = "https://clawhub.ai/api/v1";
my $TOKEN = $ENV{"CLAWHUB_TOKEN"} // "";

my @SKILLS = (
    ["Cluster Gateway",           "cluster-gateway"],
    ["MCP Tool Utils",            "mcp-tool-utils"],
    ["Reports Creator",           "reports-creator"],
    ["Relay Node",                "relay-node"],
    ["JSON Utils",                "json-utils"],
    ["Log Collector",             "log-collector"],
    ["TikTok Live Monitor",       "tiktok-live-monitor"],
    ["Doc Scraper",               "doc-scraper"],
    ["Workspace Database Manager","workspace-database-manager"],
    ["Scripting Utils",           "scripting-utils"],
);

sub fetch_skill {
    my ($slug) = @_;
    my $url = "$API_BASE/skills/$slug";
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $req = HTTP::Request->new(GET => $url);
    if ($TOKEN) {
        $req->header("Authorization" => "Bearer $TOKEN");
    }
    $req->header("Accept" => "application/json");
    my $res = $ua->request($req);
    if (!$res->is_success) {
        die "HTTP " . $res->code . ": " . $res->message;
    }
    return decode_json($res->content);
}

sub parse_skill {
    my ($data) = @_;
    my $skill   = $data->{"skill"} // {};
    my $stats   = $skill->{"stats"} // {};
    my $version_data = $data->{"latestVersion"} // {};
    my $version = $version_data->{"version"} // "1.0.0";
    my $mod     = $data->{"moderation"};

    my $downloads = $stats->{"downloads"} // 0;

    my $security;
    if (!defined $mod) {
        $security = "✅ Pass";
    } elsif ($mod->{"isMalwareBlocked"}) {
        $security = "🚫 Blocked";
    } else {
        $security = "🔍 Review";
    }

    return {
        "downloads" => $downloads,
        "version"   => $version =~ /^v/ ? $version : "v$version",
        "security"  => $security,
    };
}

sub main {
    my %stats = ();
    my $errors = 0;
    foreach my $entry (@SKILLS) {
        my ($name, $slug) = @$entry;
        eval {
            my $data = fetch_skill($slug);
            my $s = parse_skill($data);
            $stats{$slug} = $s;
            print "  OK  $slug: $s->{\"downloads\"} downloads, $s->{\"version\"}, $s->{\"security\"}\n";
        };
        if ($@) {
            print STDERR "  ERR $slug: $@\n";
            $errors++;
        }
    }

    if (keys %stats == 0) {
        print STDERR "No data fetched — aborting.\n";
        exit 1;
    }

    my $content;
    {
        open(my $fh, "<:encoding(UTF-8)", "README.md") or die "Cannot read README.md: $!";
        local $/;
        $content = <$fh>;
        close($fh);
    }

    foreach my $entry (@SKILLS) {
        my ($name, $slug) = @$entry;
        if (!exists $stats{$slug}) {
            next;
        }
        my $dl = $stats{$slug}->{"downloads"};
        # Escape special regex characters in the name
        my $escaped_name = quotemeta($name);
        my $pattern = qr/(\|\s*\[?$escaped_name\]?[^|]*\|[^|]*\|)\s*\d+\s*(\|)/i;
        my $replacement = "\$1 $dl \$2";
        my $new_content = $content;
        $new_content =~ s/$pattern/$replacement/g;
        if ($new_content ne $content) {
            $content = $new_content;
            print "  Updated: $name -> $dl\n";
        }
    }

    open(my $fh, ">:encoding(UTF-8)", "README.md") or die "Cannot write README.md: $!";
    print $fh $content;
    close($fh);
    print "Done: " . (scalar keys %stats) . " skills, $errors errors.\n";
}

main() unless caller;
