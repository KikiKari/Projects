#!/usr/bin/perl
# scrape_to_markdown.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/web-markdown-scraper/scripts/scrape_to_markdown.py
# auch in: OpenClaw@gateway2:skills/web-markdown-scraper/scripts/scrape_to_markdown.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON;
use URI;
use URI::Escape;
use File::Path qw(make_path);
use File::Basename;
use Getopt::Long;
use LWP::UserAgent;
use HTML::TreeBuilder;
use HTML::FormatText::WithLinks;

# SECURITY MANIFEST:
# Environment variables accessed: none
# External endpoints called: only URLs supplied by the user at runtime via --url / --url-file
# Local files read: --url-file path (if provided by user)
# Local files written: --output-dir/*.md, --output-dir/index.json (if --output-dir provided)
#                      Scrapling automatch SQLite DB (managed by Scrapling, local only)
# Credentials handled: --proxy value (never logged or transmitted beyond the proxy itself)
# Shell injection risk: none (pure Perl, no system calls or shell interpolation)

sub to_str {
    my ($value) = @_;
    return "" unless defined $value;
    if (ref($value) eq 'SCALAR' && ref($value) eq 'GLOB') {
        # Handle filehandle-like objects if needed
        return "";
    }
    return $$value if ref($value) eq 'SCALAR';
    return "$value";
}

sub slugify {
    my ($text, $max_len) = @_;
    $max_len //= 80;
    $text =~ s/[^\w\s-]//g;
    $text =~ s/[-\s]+/-/g;
    $text = lc($text);
    $text = substr($text, 0, $max_len);
    $text =~ s/^-+|-+$//g;
    return $text || "page";
}

sub extract_html {
    my ($obj) = @_;
    return "" unless defined $obj;
    
    my @attrs = qw(html raw_html content markup body inner_html);
    for my $attr (@attrs) {
        if (ref($obj) && $obj->can($attr)) {
            my $value = eval { $obj->$attr() };
            next if $@;
            my $text = to_str($value);
            return $text if $text && $text =~ /</ && $text =~ />/;
        }
    }
    
    my $text = to_str($obj);
    return ($text =~ /</ && $text =~ />/) ? $text : "";
}

sub extract_title {
    my ($html) = @_;
    return "" unless defined $html;
    
    if ($html =~ /<title[^>]*>(.*?)<\/title>/si) {
        my $title = $1;
        $title =~ s/<[^>]+>/ /g;
        $title =~ s/\s+/ /g;
        $title =~ s/^\s+|\s+$//g;
        return $title;
    }
    return "";
}

sub fetch_page {
    my ($url, $js, $wait_selector, $timeout, $automatch_domain) = @_;
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout($timeout // 30);
    my $response = $ua->get($url);
    
    if ($response->is_success) {
        return ($response->decoded_content, "LWP::UserAgent.get");
    } else {
        die "Failed to fetch $url: " . $response->status_line;
    }
}

sub pick_main_html {
    my ($page, $preferred_selector) = @_;
    
    my @selectors = ();
    push @selectors, $preferred_selector if $preferred_selector;
    push @selectors, qw(article main [role='main'] .post-content .entry-content .article-content body);
    
    # Simple implementation without CSS selection
    return (extract_html($page), undef);
}

sub html_to_markdown {
    my ($html, $preserve_links, $body_width) = @_;
    $body_width //= 0;
    
    my $h = HTML::FormatText::WithLinks->new(
        before_link => '',
        after_link => ' [%l]',
        footnote => $preserve_links ? '[%n] %l' : '',
        links_after_each_paragraph => 0,
        display_links => $preserve_links,
        remove_newlines => 1,
        with_emphasis => 1,
    );
    
    my $md = $h->parse($html);
    $md =~ s/\n{3,}/\n\n/g;
    $md =~ s/^\s+|\s+$//g;
    return $md;
}

sub load_urls {
    my ($url_args, $url_file) = @_;
    
    my @urls = @$url_args;
    
    if ($url_file && -f $url_file) {
        open my $fh, '<:encoding(UTF-8)', $url_file or die "Cannot open $url_file: $!";
        while (my $line = <$fh>) {
            chomp $line;
            $line =~ s/^\s+|\s+$//g;
            next if !$line || $line =~ /^#/;
            push @urls, $line;
        }
        close $fh;
    }
    
    my %seen;
    my @clean;
    for my $u (@urls) {
        if (!$seen{$u}) {
            push @clean, $u;
            $seen{$u} = 1;
        }
    }
    
    return @clean;
}

sub validate_url {
    my ($url) = @_;
    my $uri = URI->new($url);
    return ($uri->scheme =~ /^(http|https)$/i) && $uri->host;
}

sub main {
    my @urls;
    my $url_file = "";
    my $selector = "";
    my $js = 0;
    my $wait_selector = "";
    my $preserve_links = 0;
    my $body_width = 0;
    my $timeout = 30;
    my $output_dir = "outputs";
    my $automatch_domain = "";
    
    GetOptions(
        "url=s@" => \@urls,
        "url-file=s" => \$url_file,
        "selector=s" => \$selector,
        "js" => \$js,
        "wait-selector=s" => \$wait_selector,
        "preserve-links" => \$preserve_links,
        "body-width=i" => \$body_width,
        "timeout=i" => \$timeout,
        "output-dir=s" => \$output_dir,
        "automatch-domain=s" => \$automatch_domain,
    ) or die "Error in command line arguments\n";
    
    my @loaded_urls = load_urls(\@urls, $url_file);
    
    if (!@loaded_urls) {
        print encode_json({ok => JSON::false, error => "No URLs provided"}) . "\n";
        exit 1;
    }
    
    for my $u (@loaded_urls) {
        if (!validate_url($u)) {
            print encode_json({ok => JSON::false, error => "Invalid URL: $u"}) . "\n";
            exit 1;
        }
    }
    
    make_path($output_dir) unless -d $output_dir;
    
    my @results;
    
    for my $url (@loaded_urls) {
        my $item = {
            url => $url,
            ok => JSON::false,
            title => "",
            status => undef,
            selector_used => undef,
            backend => undef,
            markdown => "",
            preview => "",
            output_markdown_file => undef,
            error => undef,
        };
        
        eval {
            my ($page, $backend) = fetch_page(
                $url,
                $js,
                $wait_selector || undef,
                $timeout,
                $automatch_domain || undef,
            );
            
            my ($html, $selector_used) = pick_main_html($page, $selector || undef);
            die "No HTML content extracted from page" unless $html;
            
            my $title = extract_title($html) || do {
                my $uri = URI->new($url);
                $uri->host;
            };
            
            my $markdown = html_to_markdown(
                $html,
                $preserve_links,
                $body_width,
            );
            
            my $filename = slugify(URI->new($url)->host . "-$title") . ".md";
            my $md_path = "$output_dir/$filename";
            
            open my $fh, '>:encoding(UTF-8)', $md_path or die "Cannot write to $md_path: $!";
            print $fh $markdown;
            close $fh;
            
            $item->{ok} = JSON::true;
            $item->{title} = $title;
            $item->{status} = 200;  # Simplified
            $item->{selector_used} = $selector_used;
            $item->{backend} = $backend;
            $item->{markdown} = $markdown;
            $item->{preview} = substr($markdown, 0, 1200);
            $item->{output_markdown_file} = $md_path;
        };
        
        if ($@) {
            $item->{error} = "$@";
        }
        
        push @results, $item;
    }
    
    my $ok = grep { $_->{ok} } @results;
    my $index_path = "$output_dir/index.json";
    
    my $payload = {
        ok => $ok ? JSON::true : JSON::false,
        count => scalar(@results),
        success_count => scalar(grep { $_->{ok} } @results),
        failure_count => scalar(grep { !$_->{ok} } @results),
        output_index_file => $index_path,
        results => \@results,
    };
    
    open my $fh, '>:encoding(UTF-8)', $index_path or die "Cannot write to $index_path: $!";
    print $fh JSON->new->pretty->encode($payload);
    close $fh;
    
    print JSON->new->encode($payload) . "\n";
}

main() unless caller;
