#!/usr/bin/env perl
# abstractions-publish-gateway-cron.sh — portiert nach perl5
# Quelle: shell, Projects@clawhub:clawhub/Scripts/abstractions-publish-gateway-cron.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Wrapper für Linux-crontab - setzt sauberes Environment
$ENV{HOME} = "/home/openclaw";
$ENV{PATH} = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";

my $LOG_DIR = "/home/openclaw/.openclaw/logs/abstractions-publish-gateway";
system("mkdir", "-p", $LOG_DIR);

my $CRON_LOG = "$LOG_DIR/linux-cron.log";

open(my $fh, ">>", $CRON_LOG) or die "Kann $CRON_LOG nicht öffnen: $!";

print $fh "\n";
print $fh "===== CRON START " . localtime() . " =====\n";

my $exit_code = system("/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh");

print $fh "===== CRON END (exit $exit_code) =====\n";

close($fh);
