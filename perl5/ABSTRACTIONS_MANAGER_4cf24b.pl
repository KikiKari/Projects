#!/usr/bin/env perl
# ABSTRACTIONS_MANAGER.py — portiert nach perl5
# Quelle: python, Projects@abstractions:abstractions/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use 5.010;
use File::Find;
use File::Path qw(make_path);
use File::Temp qw(tempfile);
use File::Copy qw(move);
use Digest::SHA qw(sha256_hex);
use JSON qw(decode_json encode_json);
use LWP::UserAgent;
use HTTP::Request;
use Getopt::Long;
use Pod::Usage;
use Time::HiRes qw(sleep);
use POSIX qw(strftime);

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

my $WORKSPACE = $ENV{ABSTRACTIONS_WORKSPACE} // "/home/openclaw/.openclaw/workspace";
my $ABSTRACTIONS_REPO = "$WORKSPACE/git/Abstraktionen";
my $QUELLEN_DIR = "$WORKSPACE/git/quellen";
my $LOG_DIR = "$WORKSPACE/logs/abstractions-manager";
my $STATE_FILE = "$WORKSPACE/db/abstractions_state.json";

my $GITHUB_BENUTZER = "KikiKari";

my @QUELLEN = (
    { repo => "OpenClaw",   branches => ["main", "gateway1", "gateway2"] },
    { repo => "Projects",   branches => "alle" },
    { repo => "Onboarding", branches => ["main"] },
);

my %QUELLSPRACHEN = (
    ".pl" => "perl5", ".pm" => "perl5",
    ".ps1" => "powershell", ".psm1" => "powershell",
    ".sh" => "shell", ".bash" => "shell",
    ".tcl" => "tcl",
    ".html" => "html", ".htm" => "html",
    ".js" => "javascript", ".mjs" => "javascript", ".cjs" => "javascript",
    ".py" => "python",
    ".css" => "css",
);

my %ZIELSPRACHEN = (
    "javascript" => { ext => ".js",  bezeichnung => "JavaScript fuer Node 20" },
    "perl5"      => { ext => ".pl",  bezeichnung => "Perl 5 mit use strict und use warnings" },
    "powershell" => { ext => ".ps1", bezeichnung => "PowerShell 7" },
    "python"     => { ext => ".py",  bezeichnung => "Python 3.12" },
    "shell"      => { ext => ".sh",  bezeichnung => "Bash 5 mit set -euo pipefail" },
    "tcl"        => { ext => ".tcl", bezeichnung => "Tcl 8.6" },
);

my @AUSSCHLUSS = (
    "node_modules/", "/.git/", "__pycache__/", "dist/", "build/", "vendor/",
    ".venv/", "site-packages/", "python-hardener-workspace/", ".artifacts/",
    "coverage/", ".next/", "target/",
);
my $MAX_BYTES = 200_000;

my @MODELLE = (
    "qwen/qwen3-coder",
    "deepseek/deepseek-chat-v3.1",
    "z-ai/glm-4.6",
    "mistralai/codestral-2508",
    "qwen/qwen-2.5-coder-32b-instruct",
);
my $API_URL = "https://openrouter.ai/api/v1/chat/completions";
my $ZEITLIMIT = 240;
my $VERSUCHE = 3;

# ---------------------------------------------------------------------------
# Protokoll
# ---------------------------------------------------------------------------

sub _protokoll {
    # In Perl gibt es kein Logging-Framework wie in Python, daher verwenden wir einfache print-Anweisungen
    # und schreiben optional in eine Logdatei
    return sub {
        my ($level, $message) = @_;
        my $timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
        my $log_line = "$timestamp | $level | $message\n";
        print STDOUT $log_line;
        eval {
            make_path($LOG_DIR) unless -d $LOG_DIR;
            open my $fh, '>>:encoding(UTF-8)', "$LOG_DIR/manager.log" or die "Cannot open log file: $!";
            print $fh $log_line;
            close $fh;
        };
        warn "Protokolldatei nicht verfuegbar ($@) — es wird nur nach stdout geschrieben" if $@;
    };
}

my $logger = _protokoll();

# ---------------------------------------------------------------------------
# Zustand
# ---------------------------------------------------------------------------

sub zustand_laden {
    if (-f $STATE_FILE) {
        eval {
            open my $fh, '<:encoding(UTF-8)', $STATE_FILE or die "Cannot open state file: $!";
            my $content = do { local $/; <$fh> };
            close $fh;
            return decode_json($content);
        };
        $logger->("WARNING", "Zustand unlesbar ($@) — es wird neu begonnen") if $@;
    }
    return { erledigt => {}, statistik => {} };
}

sub zustand_speichern {
    my ($zustand) = @_;
    eval {
        make_path(dirname($STATE_FILE)) unless -d dirname($STATE_FILE);
        my ($fh, $tempfile) = tempfile(DIR => dirname($STATE_FILE), PREFIX => ".zustand_", SUFFIX => ".tmp");
        print $fh encode_json($zustand);
        close $fh;
        move($tempfile, $STATE_FILE) or die "Cannot move tempfile to state file: $!";
    };
    $logger->("ERROR", "Zustand konnte nicht gespeichert werden: $@") if $@;
}

# ---------------------------------------------------------------------------
# Quellen holen
# ---------------------------------------------------------------------------

sub _git {
    my (@args) = @_;
    my @cmd = ("git", @args);
    my $result = `@cmd 2>&1`;
    return { stdout => $result, returncode => $? };
}

sub quellen_holen {
    make_path($QUELLEN_DIR) unless -d $QUELLEN_DIR;
    my @baeume;

    for my $eintrag (@QUELLEN) {
        my $repo = $eintrag->{repo};
        my $spiegel = "$QUELLEN_DIR/${repo}.git";
        my $url = "https://github.com/$GITHUB_BENUTZER/${repo}.git";

        if (!-d $spiegel) {
            $logger->("INFO", "$repo wird geholt");
            my $ergebnis = _git("clone", "--mirror", "--filter=blob:none", $url, $spiegel);
            if ($ergebnis->{returncode} != 0) {
                $logger->("ERROR", "$repo konnte nicht geholt werden: " . substr($ergebnis->{stdout}, 0, 200));
                next;
            }
        } else {
            my $ergebnis = _git("-C", $spiegel, "remote", "update", "--prune");
            if ($ergebnis->{returncode} != 0) {
                $logger->("WARNING", "$repo konnte nicht aktualisiert werden: " . substr($ergebnis->{stdout}, 0, 200));
            }
        }

        my $gewuenscht = $eintrag->{branches};
        my @branches;
        if ($gewuenscht eq "alle") {
            my $aus = _git("-C", $spiegel, "for-each-ref", "--format=%(refname:short)", "refs/heads");
            @branches = map { chomp; $_ } split /\n/, $aus->{stdout};
        } else {
            @branches = @$gewuenscht;
        }

        for my $branch (@branches) {
            my $baum = "$QUELLEN_DIR/baeume/$repo/" . ($branch =~ s|/|_|gr);
            make_path($baum) unless -d $baum;
            my $ergebnis = _git("--work-tree", $baum, "-C", $spiegel, "checkout", "-f", $branch, "--", ".");
            if ($ergebnis->{returncode} != 0) {
                $logger->("WARNING", "$repo\@$branch: Arbeitsbaum fehlgeschlagen: " . substr($ergebnis->{stdout}, 0, 160));
                next;
            }
            push @baeume, [$repo, $branch, $baum];
        }
    }

    $logger->("INFO", "Quellen bereit: " . scalar(@baeume) . " Arbeitsbaeume");
    return \@baeume;
}

# ---------------------------------------------------------------------------
# Inventar
# ---------------------------------------------------------------------------

sub _prioritaet {
    my ($pfad, $sprache) = @_;
    return "low" if $sprache =~ /^(html|css)$/;
    return "high" if $pfad =~ m|^scripts/| || $pfad =~ m|/scripts/|;
    return "medium";
}

sub inventar_bauen {
    my ($baeume) = @_;
    my %dateien;

    for my $baum_ref (@$baeume) {
        my ($repo, $branch, $baum) = @$baum_ref;
        find(sub {
            return unless -f $_;
            my $rel = $File::Find::name;
            $rel =~ s|^\Q$baum\E/||;
            $rel =~ s|\\|/|g;
            return if grep { "/$rel" =~ /\Q$_\E/ } @AUSSCHLUSS;
            my ($suffix) = $_ =~ /(\.[^.]+)$/;
            return unless defined $suffix;
            my $sprache = $QUELLSPRACHEN{lc $suffix};
            return unless $sprache;
            eval {
                open my $fh, '<:raw', $_ or die "Cannot open file: $!";
                my $roh;
                my $size = -s $_;
                return if $size == 0 || $size > $MAX_BYTES;
                read $fh, $roh, $size;
                close $fh;
                my $schluessel = substr(sha256_hex($roh), 0, 16);
                my $eintrag = $dateien{$schluessel};
                if (!defined $eintrag) {
                    $eintrag = {
                        hash => $schluessel,
                        name => $_,
                        stamm => (split /\./, $_)[0],
                        sprache => $sprache,
                        bytes => length($roh),
                        pfad => $File::Find::name,
                        herkunft => [],
                        prioritaet => _prioritaet($rel, $sprache),
                    };
                    $dateien{$schluessel} = $eintrag;
                }
                push @{$eintrag->{herkunft}}, "$repo\@$branch:$rel";
            };
        }, $baum);
    }

    my @liste = values %dateien;
    @liste = sort {
        my $rang_a = ($a->{prioritaet} eq "high") ? 0 : ($a->{prioritaet} eq "medium") ? 1 : 2;
        my $rang_b = ($b->{prioritaet} eq "high") ? 0 : ($b->{prioritaet} eq "medium") ? 1 : 2;
        $rang_a <=> $rang_b || $a->{name} cmp $b->{name}
    } @liste;

    $logger->("INFO", "Inventar: " . scalar(@liste) . " eindeutige Quelldateien aus " . 
              (map { scalar(@{$_->{herkunft}}) } @liste) . " Fundstellen");
    return \@liste;
}

# ---------------------------------------------------------------------------
# Uebersetzung
# ---------------------------------------------------------------------------

my $ANWEISUNG = <<'END_ANWEISUNG';
Du portierst Quellcode zwischen Programmiersprachen.

Regeln:
1. Gib ausschliesslich den vollstaendigen Code der Zielsprache aus. Keine
   Erklaerung davor oder danach, keine Code-Zaeune.
2. Uebersetze die gesamte Funktionalitaet. Kein TODO, kein "hier waere",
   kein leerer Rumpf, kein Platzhalter.
3. Erhalte Verhalten, Ein- und Ausgaben, Aufrufparameter und Rueckgabewerte.
4. Verwende die Mittel der Zielsprache statt einer woertlichen Abschrift.
   Wo eine Bibliothek fehlt, loese es mit Bordmitteln der Zielsprache.
5. Kommentare uebernimmst du sinngemaess in der Sprache des Originals.
6. Beginne mit der passenden Shebang-Zeile.
END_ANWEISUNG

my $MARKUP_HINWEIS = <<'END_MARKUP';
Das Original ist {sprache}. Erzeuge ein Programm in der
Zielsprache, das dieses Dokument erzeugt und ueber einen Parameter in eine
Datei schreibt — kein blosses Einbetten als Zeichenkette, sondern eine
nachvollziehbare Erzeugung der Struktur.
END_MARKUP

sub _zaeune_entfernen {
    my ($text) = @_;
    my @zeilen = split /\n/, $text;
    @zeilen = grep { !/^\s*```/ } @zeilen;
    return join("\n", @zeilen) . "\n";
}

sub modell_fragen {
    my ($quelle, $quellsprache, $zielsprache, $name, $schluessel) = @_;
    my $ziel = $ZIELSPRACHEN{$zielsprache}{bezeichnung};
    my $auftrag = "Portiere die folgende Datei $name von $quellsprache nach $ziel.\n";
    if ($quellsprache =~ /^(html|css)$/) {
        $auftrag .= $MARKUP_HINWEIS;
        $auftrag =~ s/\{sprache\}/uc($quellsprache)/ge;
    }
    $auftrag .= "\n----- Beginn $name -----\n$quelle\n----- Ende $name -----";

    my @modelle = $ENV{ABSTRACTIONS_MODELL} ? ($ENV{ABSTRACTIONS_MODELL}) : @MODELLE;

    for my $modell (@modelle) {
        for my $versuch (1..$VERSUCHE) {
            my $json_data = encode_json({
                model => $modell,
                messages => [
                    { role => "system", content => $ANWEISUNG },
                    { role => "user", content => $auftrag },
                ],
                temperature => 0.1,
                max_tokens => 8000,
            });
            my $ua = LWP::UserAgent->new;
            $ua->timeout($ZEITLIMIT);
            my $req = HTTP::Request->new(POST => $API_URL);
            $req->header('Authorization' => "Bearer $schluessel");
            $req->header('Content-Type' => 'application/json');
            $req->header('HTTP-Referer' => 'https://github.com/KikiKari/Projects');
            $req->header('X-Title' => 'Abstractions Manager');
            $req->content($json_data);

            my $res = $ua->request($req);
            if ($res->is_success) {
                my $daten = decode_json($res->decoded_content);
                my $inhalt = $daten->{choices}[0]{message}{content};
                if ($inhalt && $inhalt =~ /\S/) {
                    return _zaeune_entfernen($inhalt);
                }
                $logger->("WARNING", "$name -> $zielsprache: leere Antwort von $modell");
            } else {
                my $text = substr($res->decoded_content, 0, 200);
                $logger->("WARNING", "$name -> $zielsprache: HTTP " . $res->code . " von $modell ($text)");
                last if $res->code =~ /^(400|401|402|404)$/;
            }
            sleep(min(2 ** $versuch, 20));
        }
    }

    $logger->("ERROR", "$name -> $zielsprache: kein Modell hat geliefert");
    return undef;
}

# ---------------------------------------------------------------------------
# Pruefung der Erzeugnisse
# ---------------------------------------------------------------------------

my %PRUEFBEFEHLE = (
    javascript => ["node", "--check"],
    perl5      => ["perl", "-c"],
    powershell => ["pwsh", "-NoProfile", "-Command"],
    shell      => ["bash", "-n"],
    tcl        => ["tclsh"],
);

my @VERDACHT = ("TODO: Implementiere", "TODO: implement", "not implemented",
               "hier waere", "Platzhalter", "your code here", "pass  # TODO");

sub erzeugnis_pruefen {
    my ($code, $zielsprache, $quelle) = @_;
    $quelle //= "";
    my @quellzeilen = split /\n/, $quelle;
    my @zeilen = grep { /\S/ } split /\n/, $code;
    my $mindestens = max(2, min(6, int(@quellzeilen / 3))) || 5;
    if (@zeilen < $mindestens) {
        return (0, "zu kurz (" . @zeilen . " statt mindestens $mindestens Zeilen)");
    }

    my $niedrig = lc($quelle);
    for my $muster (@VERDACHT) {
        if (index(lc($code), lc($muster)) != -1 && index($niedrig, lc($muster)) == -1) {
            return (0, "unfertig ($muster)");
        }
    }

    if ($zielsprache eq "python") {
        eval {
            require Python::Compiler;
            Python::Compiler::compile($code, "<erzeugnis>", "exec");
            return (1, "syntax ok");
        };
        if ($@) {
            my ($line) = $@ =~ /line (\d+)/;
            return (0, "Syntaxfehler Zeile " . ($line // "unbekannt"));
        }
    }

    my $befehl = $PRUEFBEFEHLE{$zielsprache};
    return (1, "ohne Syntaxpruefung angenommen") unless $befehl;

    my $endung = $ZIELSPRACHEN{$zielsprache}{ext};
    my ($fh, $tempfile) = tempfile(SUFFIX => $endung);
    print $fh $code;
    close $fh;

    my @aufruf;
    if ($zielsprache eq "powershell") {
        @aufruf = (@$befehl, "\$null = [ScriptBlock]::Create((Get-Content -Raw '$tempfile'))");
    } elsif ($zielsprache eq "tcl") {
        my $result = `tclsh -c "if {\[catch {info complete \[read \[open $tempfile\]\]}\]} {exit 1}" 2>&1`;
        unlink $tempfile;
        return ($? == 0, ($? == 0 ? "syntax ok" : "Syntaxfehler"));
    } else {
        @aufruf = (@$befehl, $tempfile);
    }

    my $result = `@aufruf 2>&1`;
    my $exit_code = $? >> 8;
    unlink $tempfile;

    if ($exit_code == 0) {
        return (1, "syntax ok");
    }

    my $meldung = $result;
    if ($meldung =~ /Can't locate|Cannot find module/) {
        return (1, "Fremdmodul fehlt hier — Syntax nicht abschliessend geprueft");
    }
    my ($erste) = split /\n/, $meldung;
    $erste = substr($erste, 0, 90) if defined $erste;
    return (0, "Syntaxfehler: " . ($erste // "unbekannt"));
}

# ---------------------------------------------------------------------------
# Ablage
# ---------------------------------------------------------------------------

sub _zieldatei {
    my ($eintrag, $zielsprache, $belegt) = @_;
    my $endung = $ZIELSPRACHEN{$zielsprache}{ext};
    my $stamm = $eintrag->{stamm};
    my $schluessel = "$zielsprache/$stamm";
    my $vorher = $belegt->{$schluessel};
    if (defined $vorher && $vorher ne $eintrag->{hash}) {
        $stamm = $stamm . "_" . substr($eintrag->{hash}, 0, 6);
    } else {
        $belegt->{$schluessel} = $eintrag->{hash};
    }
    return "$ABSTRACTIONS_REPO/$zielsprache/${stamm}${endung}";
}

sub _kopf {
    my ($eintrag, $zielsprache) = @_;
    my $zeichen = ($zielsprache eq "javascript") ? "//" : "#";
    my $heute = strftime "%Y-%m-%d", gmtime;
    my @zeilen = (
        "$zeichen $eintrag->{name} — portiert nach $zielsprache",
        "$zeichen Quelle: $eintrag->{sprache}, $eintrag->{herkunft}[0]",
    );
    for my $weitere (@{$eintrag->{herkunft}}[1..3]) {
        push @zeilen, "$zeichen auch in: $weitere";
    }
    if (@{$eintrag->{herkunft}} > 4) {
        push @zeilen, "$zeichen auch in: " . (@{$eintrag->{herkunft}} - 4) . " weiteren Fundstellen";
    }
    push @zeilen, "$zeichen Erzeugt: $heute durch ABSTRACTIONS_MANAGER.py";
    return join("\n", @zeilen) . "\n";
}

sub ablegen {
    my ($eintrag, $zielsprache, $code, $belegt) = @_;
    my $ziel = _zieldatei($eintrag, $zielsprache, $belegt);
    eval {
        make_path(dirname($ziel)) unless -d dirname($ziel);
        my @zeilen = split /\n/, $code;
        my $inhalt;
        if (@zeilen && $zeilen[0] =~ /^#!/) {
            $inhalt = $zeilen[0] . "\n" . _kopf($eintrag, $zielsprache) . "\n" . join("\n", @zeilen[1..$#zeilen]) . "\n";
        } else {
            $inhalt = _kopf($eintrag, $zielsprache) . "\n" . $code;
        }
        my ($fh, $tempfile) = tempfile(DIR => dirname($ziel), PREFIX => ".neu_", SUFFIX => $ZIELSPRACHEN{$zielsprache}{ext});
        print $fh $inhalt;
        close $fh;
        move($tempfile, $ziel) or die "Cannot move tempfile to target: $!";
        return $ziel;
    };
    $logger->("ERROR", "$ziel konnte nicht abgelegt werden: $@") if $@;
    return undef;
}

# ---------------------------------------------------------------------------
# Durchlauf
# ---------------------------------------------------------------------------

sub uebersetzen {
    my ($inventar, $zustand, $prioritaet, $anzahl, $probelauf, $schluessel) = @_;
    my %zaehler = (erzeugt => 0, uebersprungen => 0, verworfen => 0, dateien => 0);
    my %belegt;
    my $erledigt = $zustand->{erledigt} //= {};

    my @offen = grep { $prioritaet eq "alle" || $_->{prioritaet} eq $prioritaet } @$inventar;
    $logger->("INFO", "Prioritaet $prioritaet: " . @offen . " Quelldateien im Bestand");

    for my $eintrag (@offen) {
        last if $zaehler{dateien} >= $anzahl;

        my %fertig = map { $_ => 1 } @{$erledigt->{$eintrag->{hash}} // []};
        my @ziele = grep { $_ ne $eintrag->{sprache} && !$fertig{$_} } keys %ZIELSPRACHEN;
        next unless @ziele;

        my $quelle;
        eval {
            open my $fh, '<:encoding(UTF-8)', $eintrag->{pfad} or die "Cannot open file: $!";
            $quelle = do { local $/; <$fh> };
            close $fh;
        };
        if ($@) {
            $logger->("WARNING", "$eintrag->{name} nicht lesbar: $@");
            next;
        }

        $zaehler{dateien}++;
        $logger->("INFO", "[$eintrag->{prioritaet}] $eintrag->{name} ($eintrag->{sprache}, $eintrag->{bytes} B) -> " . join(", ", @ziele));

        for my $zielsprache (@ziele) {
            if ($probelauf) {
                $logger->("INFO", "  $zielsprache: Probelauf, nichts gesendet");
                $zaehler{uebersprungen}++;
                next;
            }

            my $code = modell_fragen($quelle, $eintrag->{sprache}, $zielsprache, $eintrag->{name}, $schluessel);
            if (!defined $code) {
                $zaehler{verworfen}++;
                next;
            }

            my ($angenommen, $grund) = erzeugnis_pruefen($code, $zielsprache, $quelle);
            if (!$angenommen) {
                $logger->("WARNING", "  $zielsprache: verworfen — $grund");
                $zaehler{verworfen}++;
                next;
            }

            my $ziel = ablegen($eintrag, $zielsprache, $code, \%belegt);
            if (!defined $ziel) {
                $zaehler{verworfen}++;
                next;
            }

            $logger->("INFO", "  $zielsprache: $ziel (basename) ($grund)");
            $zaehler{erzeugt}++;
            push @{$erledigt->{$eintrag->{hash}}}, $zielsprache;
        }

        @{$erledigt->{$eintrag->{hash}}} = sort @{$erledigt->{$eintrag->{hash}}};
    }

    return \%zaehler;
}

# ---------------------------------------------------------------------------
# Bericht und Veroeffentlichung
# ---------------------------------------------------------------------------

sub bericht_schreiben {
    my ($inventar, $zustand, $zaehler) = @_;
    return unless -d $ABSTRACTIONS_REPO;

    my %je_sprache;
    for my $sprache (keys %ZIELSPRACHEN) {
        my $verzeichnis = "$ABSTRACTIONS_REPO/$sprache";
        if (-d $verzeichnis) {
            opendir my $dh, $verzeichnis or die "Cannot open directory: $!";
            my @files = grep { -f "$verzeichnis/$_" } readdir($dh);
            closedir $dh;
            $je_sprache{$sprache} = scalar @files;
        } else {
            $je_sprache{$sprache} = 0;
        }
    }

    my %rang = (high => 0, medium => 1, low => 2);
    my %je_prio = map { $_ => scalar(grep { $_->{prioritaet} eq $_ } @$inventar) } keys %rang;
    my $erledigt = $zustand->{erledigt} // {};
    my $offen = 0;
    for my $e (@$inventar) {
        $offen += scalar(grep { $_ ne $e->{sprache} } keys %ZIELSPRACHEN) - scalar(@{$erledigt->{$e->{hash}} // []});
    }

    my @zeilen = (
        "# Script Abstractions — Status",
        "",
        "**Letzter Lauf:** " . strftime("%Y-%m-%d %H:%M", gmtime) . " UTC",
        "",
        "Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.",
        "Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige",
        "Syntax oder mit Platzhaltern werden verworfen.",
        "",
        "## Bestand",
        "",
        "| Zielsprache | Dateien |",
        "|---|---:|",
        (map { "| $_ | $je_sprache{$_} |" } sort keys %je_sprache),
        "| **gesamt** | **" . (reduce { $a + $b } values %je_sprache) . "** |",
        "",
        "## Quellen",
        "",
        "| Prioritaet | Quelldateien | Bedeutung |",
        "|---|---:|---|",
        "| high | $je_prio{high} | Betriebsscripte aus scripts-Verzeichnissen |",
        "| medium | $je_prio{medium} | uebriger ausfuehrbarer Code |",
        "| low | $je_prio{low} | Markup und Stilvorlagen |",
        "| **gesamt** | **" . scalar(@$inventar) . "** | nach Inhalt dedupliziert |",
        "",
        "Noch offene Sprachpaare: **$offen**",
        "",
        "## Letzter Lauf",
        "",
        "- bearbeitete Quelldateien: $zaehler->{dateien}",
        "- erzeugte Uebersetzungen: $zaehler->{erzeugt}",
        "- verworfen: $zaehler->{verworfen}",
        "",
        "## Herkunft",
        "",
        "- `KikiKari/OpenClaw` — main, gateway1, gateway2",
        "- `KikiKari/Projects` — alle Branches",
        "- `KikiKari/Onboarding` — main",
        "",
        "Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.",
        "",
    );

    eval {
        open my $fh, '>:encoding(UTF-8)', "$ABSTRACTIONS_REPO/STATUS.md" or die "Cannot open STATUS.md: $!";
        print $fh join("\n", @zeilen);
        close $fh;
        $logger->("INFO", "STATUS.md fortgeschrieben");
    };
    $logger->("ERROR", "STATUS.md konnte nicht geschrieben werden: $@") if $@;
}

sub veroeffentlichen {
    my ($nachricht) = @_;
    return unless -d "$ABSTRACTIONS_REPO/.git";

    my $stand = `cd '$ABSTRACTIONS_REPO' && git status --porcelain`;
    return unless $stand =~ /\S/;

    for my $sprache (keys %ZIELSPRACHEN) {
        system("cd '$ABSTRACTIONS_REPO' && git add '$sprache'");
    }
    system("cd '$ABSTRACTIONS_REPO' && git add 'STATUS.md'");

    my $ergebnis = `cd '$ABSTRACTIONS_REPO' && git commit -m '$nachricht' 2>&1`;
    if ($? != 0) {
        $logger->("WARNING", "Commit fehlgeschlagen: " . substr($ergebnis, 0, 200));
        return;
    }
    $logger->("INFO", "Commit gesetzt: $nachricht");

    my $token = $ENV{GITHUB_TOKEN} // $ENV{ABSTRACTIONS_PUSH_TOKEN};
    return unless $token;

    my $url = "https://x-access-token:$token\@github.com/$GITHUB_BENUTZER/Projects.git";
    $ergebnis = `cd '$ABSTRACTIONS_REPO' && git push '$url' HEAD:abstractions 2>&1`;
    if ($? == 0) {
        $logger->("INFO", "Nach Projects\@abstractions veroeffentlicht");
    } else {
        $ergebnis =~ s/\Q$token\E/\*\*\*/g;
        $logger->("ERROR", "Push fehlgeschlagen: " . substr($ergebnis, 0, 200));
    }
}

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

sub main {
    my ($prioritaet, $anzahl, $probelauf);
    GetOptions(
        "prioritaet=s" => \$prioritaet,
        "anzahl=i"     => \$anzahl,
        "probelauf"    => \$probelauf,
    ) or pod2usage(2);

    $anzahl //= $ENV{ABSTRACTIONS_ANZAHL} // 40;

    $logger->("INFO", "Abstractions Manager gestartet — Arbeitsverzeichnis $WORKSPACE");

    my $schluessel = $ENV{OPENROUTER_API_KEY} // "";
    $schluessel =~ s/^\s+|\s+$//g;
    if (!$probelauf) {
        if (!$schluessel) {
            $logger->("ERROR", "OPENROUTER_API_KEY ist leer oder besteht nur aus Leerraum — ohne Schluessel keine Uebersetzung");
            return 2;
        }
        if ($schluessel !~ /^sk-or-/) {
            $logger->("ERROR", "OPENROUTER_API_KEY sieht nicht nach einem OpenRouter-Schluessel aus (" . length($schluessel) . " Zeichen, beginnt mit '" . substr($schluessel, 0, 6) . "') — erwartet wird sk-or-...");
            return 2;
        }
        $logger->("INFO", "Schluessel erkannt: " . length($schluessel) . " Zeichen");
    }

    my $zustand = zustand_laden();
    my $baeume = quellen_holen();
    return 1 unless @$baeume;

    my $inventar = inventar_bauen($baeume);
    return 1 unless @$inventar;

    $prioritaet //= $zustand->{naechste_prioritaet} // "high";
    my $zaehler = uebersetzen($inventar, $zustand, $prioritaet, $anzahl, $probelauf, $schluessel);

    my %reihum = (high => "medium", medium => "low", low => "high", alle => "alle");
    $zustand->{naechste_prioritaet} = $reihum{$prioritaet};
    $zustand->{statistik} = {
        letzter_lauf => strftime("%Y-%m-%dT%H:%M:%S", gmtime),
        quelldateien => scalar(@$inventar),
        %$zaehler,
    };

    bericht_schreiben($inventar, $zustand, $zaehler);
    zustand_speichern($zustand);

    if ($zaehler->{erzeugt} && !$probelauf) {
        veroeffentlichen(
            "auto: $zaehler->{erzeugt} Uebersetzungen ($prioritaet) aus $zaehler->{dateien} Quelldateien"
        );
    }

    $logger->("INFO", "Abgeschlossen: $zaehler->{erzeugt} erzeugt, $zaehler->{verworfen} verworfen, $zaehler->{dateien} Quelldateien bearbeitet");
    return 0;
}

exit main() unless caller;

__END__

=head1 NAME

ABSTRACTIONS_MANAGER.pl - Portiert Quellcode in sechs Zielsprachen

=head1 SYNOPSIS

ABSTRACTIONS_MANAGER.pl [options]

 Options:
   --prioritaet high|medium|low|alle  Nur diese Stufe bearbeiten
   --anzahl N                         Hoechst
