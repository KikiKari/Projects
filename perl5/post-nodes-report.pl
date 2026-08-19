#!/usr/bin/perl
# post-nodes-report.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway1:scripts/post-nodes-report.js
# auch in: OpenClaw@gateway2:scripts/post-nodes-report.js
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use Cwd qw(abs_path);
use JSON;

# Pfade
my $script_dir = dirname(abs_path($0));
my $DASHBOARD_PATH = File::Spec->catfile($script_dir, '..', 'dashboards', 'nodes-overview.md');
my $REPORT_LOG = File::Spec->catfile($script_dir, '..', 'logs', 'nodes-report.log');

# Farbcodes
my %C = (
  green => "\e[32m",
  yellow => "\e[33m",
  red => "\e[31m",
  reset => "\e[0m"
);

sub post_report {
  my $content;
  eval {
    open my $fh, '<:encoding(UTF-8)', $DASHBOARD_PATH or die "Kann Dashboard-Datei nicht öffnen: $!";
    local $/;
    $content = <$fh>;
    close $fh;
  };
  if ($@) {
    print STDERR "$C{red}❌ Fehler beim Lesen der Dashboard-Datei:$C{reset} $@\n";
    return;
  }

  # Nachricht über OpenClaw message senden
  # JSON-kodieren und neue Zeilen escapen
  my $json = JSON->new->allow_blessed->convert_blessed;
  my $json_content = $json->encode($content);
  $json_content =~ s/"/\\"/g;  # Escapen von Anführungszeichen für Shell
  $json_content =~ s/\n/\\n/g; # Escapen von newlines

  my $message_cmd = qq(openclaw message send --target=main --message "$json_content");

  my $output = qx($message_cmd 2>&1);
  my $exit_code = $? >> 8;

  if ($exit_code == 0) {
    print "$C{green}✅ Report erfolgreich im 'main'-Channel gepostet.$C{reset}\n";
    append_to_log("[$$] Report posted.\n");
  } else {
    print STDERR "$C{red}❌ Fehler beim Senden der Nachricht:$C{reset} $output\n";
    append_to_log("[$$] Failed to post: $output\n");
  }
}

sub append_to_log {
  my ($message) = @_;
  my $timestamp = get_iso_timestamp();
  eval {
    open my $log_fh, '>>:encoding(UTF-8)', $REPORT_LOG or die "Kann Logdatei nicht öffnen: $!";
    print $log_fh "[$timestamp] $message";
    close $log_fh;
  };
  if ($@) {
    print STDERR "Fehler beim Schreiben ins Log: $@\n";
  }
}

sub get_iso_timestamp {
  my ($sec,$min,$hour,$mday,$mon,$year) = gmtime(time);
  $year += 1900;
  $mon += 1;
  my $timestamp = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $year, $mon, $mday, $hour, $min, $sec);
  return $timestamp;
}

sub dirname {
  my ($file) = @_;
  my ($volume, $directories, $filename) = File::Spec->splitpath($file);
  return File::Spec->catpath($volume, $directories, '');
}

# Hauptausführung
print "$C{yellow}📤 Sende Nodes-Übersicht in 'main'...$C{reset}\n";
post_report();
