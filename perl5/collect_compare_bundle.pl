#!/usr/bin/env perl
# collect_compare_bundle.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
# auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Path qw(make_path);
use File::Find;
use POSIX qw(strftime);

my $ROOT = "/home/openclaw/.openclaw";
my $OUT_DIR = "${ROOT}/workspace/vscode/compare";
my $TRANSFER_DIR = "${OUT_DIR}/transfer";
my $MD_FILE = "${OUT_DIR}/local-gateway-config.md";
my $TREE_FILE = "${OUT_DIR}/tree.txt";
my $BACKUP_FILE = "/home/openclaw/openclaw-backup.tar.gz";
my $NOW_LOCAL = strftime('%Y-%m-%d %H:%M:%S %Z', localtime);
my $NOW_UTC = strftime('%Y-%m-%dT%H:%M:%SZ', gmtime);
my $HOST = `hostname -f 2>/dev/null || hostname`;
chomp $HOST;

my $OPENCLAW_JSON = "${ROOT}/openclaw.json";
my $EXEC_APPROVALS_JSON = "${ROOT}/exec-approvals.json";
my $GATEWAY_SYSTEMD_ENV = "${ROOT}/gateway.systemd.env";
my $DOT_ENV = "${ROOT}/.env";
my $CONFIG_DIR = "${ROOT}/.config";
my $AGENTS_DIR = "${ROOT}/agents";

make_path($OUT_DIR);
make_path($TRANSFER_DIR);

unless (`which tree 2>/dev/null`) {
    print "Fehler: 'tree' ist nicht installiert.\n";
    exit 1;
}

sub append_file_verbatim {
    my ($label, $path, $lang) = @_;
    $lang //= "text";
    open(my $fh, ">>", $MD_FILE) or die "Kann $MD_FILE nicht öffnen: $!";
    print $fh "\n";
    print $fh "## ${label}\n";
    print $fh "\n";
    print $fh "Pfad: \\`${path}\\`\n";
    print $fh "\n";
    print $fh "\\`\\`\\`${lang}\n";
    if (-f $path) {
        open(my $file_fh, "<", $path) or die "Kann $path nicht öffnen: $!";
        while (my $line = <$file_fh>) {
            print $fh $line;
        }
        close($file_fh);
    } else {
        print $fh "[FEHLT] ${path}\n";
    }
    print $fh "\n";
    print $fh "\\`\\`\\`\n";
    close($fh);
}

sub append_env_verbatim {
    open(my $fh, ">>", $MD_FILE) or die "Kann $MD_FILE nicht öffnen: $!";
    print $fh "\n";
    print $fh "## Umgebungsvariablen (env)\n";
    print $fh "\n";
    print $fh "\\`\\`\\`text\n";
    my @env_vars = `env`;
    print $fh @env_vars;
    print $fh "\\`\\`\\`\n";
    close($fh);
}

sub append_dir_files_verbatim {
    my ($section, $dir) = @_;
    open(my $fh, ">>", $MD_FILE) or die "Kann $MD_FILE nicht öffnen: $!";
    print $fh "\n";
    print $fh "## ${section}\n";
    print $fh "\n";
    unless (-d $dir) {
        print $fh "[FEHLT] ${dir}\n";
        close($fh);
        return;
    }
    print $fh "Basisverzeichnis: \\`${dir}\\`\n";
    close($fh);

    my @files;
    find(sub {
        return unless -f $_;
        push @files, $File::Find::name;
    }, $dir);
    @files = sort @files;

    for my $f (@files) {
        open(my $fh, ">>", $MD_FILE) or die "Kann $MD_FILE nicht öffnen: $!";
        print $fh "\n";
        print $fh "### Datei: \\`${f}\\`\n";
        print $fh "\n";
        print $fh "\\`\\`\\`text\n";
        open(my $file_fh, "<", $f) or die "Kann $f nicht öffnen: $!";
        while (my $line = <$file_fh>) {
            print $fh $line;
        }
        close($file_fh);
        print $fh "\n";
        print $fh "\\`\\`\\`\n";
        close($fh);
    }
}

open(my $fh, ">", $MD_FILE) or die "Kann $MD_FILE nicht öffnen: $!";
print $fh "# Lokaler Gateway-Konfigurationsstand\n";
print $fh "\n";
print $fh "Generiert: ${NOW_LOCAL}\n";
print $fh "UTC: ${NOW_UTC}\n";
print $fh "Host: ${HOST}\n";
print $fh "\n";
print $fh "Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten.\n";
close($fh);

append_file_verbatim("openclaw.json", $OPENCLAW_JSON, "json");
append_file_verbatim("exec-approvals.json", $EXEC_APPROVALS_JSON, "json");
append_file_verbatim("gateway.systemd.env", $GATEWAY_SYSTEMD_ENV, "dotenv");
append_file_verbatim(".env", $DOT_ENV, "dotenv");
append_env_verbatim();
append_dir_files_verbatim(".config (alle Dateien rekursiv)", $CONFIG_DIR);
append_dir_files_verbatim("agents (alle Dateien rekursiv)", $AGENTS_DIR);

system("tree -a -L 6 \"${ROOT}\" > \"${TREE_FILE}\"");
system("openclaw backup create --output \"${BACKUP_FILE}\" --verify");
system("cp \"${BACKUP_FILE}\" \"${OUT_DIR}\"");

print "OK\n";
print "Erzeugt:\n";
print "- ${MD_FILE}\n";
print "- ${TREE_FILE}\n";
print "- ${BACKUP_FILE}\n";
print "- ${TRANSFER_DIR} (leer)\n";
