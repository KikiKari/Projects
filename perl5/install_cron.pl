#!/usr/bin/env perl
# install_cron.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
# auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Path qw(make_path);
use File::Spec;

# Installiert den DB-Maintainer als Cron-Job

my $CRON_JOB = <<'EOF';
# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1
EOF

chomp $CRON_JOB;

sub install {
    my $workspace = "/home/openclaw/.openclaw/workspace";
    my $cron_file = File::Spec->catfile($workspace, "crons", "db-maintainer.cron");
    
    # Erstelle das Verzeichnis falls es nicht existiert
    my ($volume, $directories) = File::Spec->splitpath($cron_file);
    my @dirs = File::Spec->splitdir($directories);
    pop @dirs; # Entferne die Datei am Ende
    my $cron_dir = File::Spec->catpath($volume, File::Spec->catdir(@dirs), '');
    make_path($cron_dir) unless -d $cron_dir;
    
    # Schreibe die Cron-Job Datei
    open my $fh, '>', $cron_file or die "Kann $cron_file nicht öffnen: $!";
    print $fh $CRON_JOB;
    close $fh;
    
    print "✅ Cron-Job installiert: $cron_file\n";
    print "   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron\n";
    
    # Auch in OpenClaw cron registrieren
    my $jobs_json = File::Spec->catfile($workspace, ".openclaw", "cron", "jobs.json");
    if (-e $jobs_json) {
        # Lese die bestehende JSON-Datei
        open my $json_fh, '<', $jobs_json or die "Kann $jobs_json nicht öffnen: $!";
        local $/;
        my $json_text = <$json_fh>;
        close $json_fh;
        
        my $jobs = decode_json($json_text);
        
        $jobs->{'db-maintainer'} = {
            schedule => '*/30 * * * *',
            command  => 'python3 skills/db-maintainer/scripts/db_maintainer.py',
            enabled  => JSON::true
        };
        
        # Schreibe die aktualisierte JSON-Datei
        open my $out_fh, '>', $jobs_json or die "Kann $jobs_json nicht öffnen: $!";
        print $out_fh encode_json($jobs);
        close $out_fh;
        
        print "✅ In OpenClaw cron registriert\n";
    }
}

# Hauptprogramm
install() if !caller;

1;
