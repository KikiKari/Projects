#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "fd23c0e3f140a2fd2eae9240eb925022153aeef3bddd196eb30f9cd3339c109e", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "perl5"}
# install_cron.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
# auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON qw(decode_json encode_json);
use File::Path qw(make_path);
use File::Spec;

# Installiert den DB-Maintainer als Cron-Job

my $CRON_JOB = <<'EOF';
# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1
EOF

sub trim {
    my ($str) = @_;
    $str =~ s/^\s+|\s+$//g;
    return $str;
}

sub install {
    my $workspace = "/home/openclaw/.openclaw/workspace";
    my $cron_dir = "$workspace/crons";
    my $cron_file = "$cron_dir/db-maintainer.cron";

    # Erstelle das Verzeichnis falls es nicht existiert
    make_path($cron_dir) unless -d $cron_dir;

    # Schreibe den Cron-Job in die Datei
    open(my $fh, '>', $cron_file) or die "Konnte $cron_file nicht öffnen: $!";
    print $fh trim($CRON_JOB);
    close($fh);

    print "✅ Cron-Job installiert: $cron_file\n";
    print "   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron\n";

    # Auch in OpenClaw cron registrieren
    my $jobs_json = "$workspace/.openclaw/cron/jobs.json";
    if (-f $jobs_json) {
        # Lese die bestehende JSON-Datei
        open(my $json_fh, '<', $jobs_json) or die "Konnte $jobs_json nicht öffnen: $!";
        local $/;
        my $json_text = <$json_fh>;
        close($json_fh);

        my $jobs = decode_json($json_text);

        # Aktualisiere oder füge den db-maintainer Job hinzu
        $jobs->{'db-maintainer'} = {
            schedule => '*/30 * * * *',
            command  => 'python3 skills/db-maintainer/scripts/db_maintainer.py',
            enabled  => JSON::true,
        };

        # Schreibe die aktualisierte JSON-Datei zurück
        open(my $out_fh, '>', $jobs_json) or die "Konnte $jobs_json nicht schreiben: $!";
        print $out_fh encode_json($jobs);
        close($out_fh);

        print "✅ In OpenClaw cron registriert\n";
    }
}

install() if __FILE__ eq $0;
