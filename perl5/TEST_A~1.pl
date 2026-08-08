#!/usr/bin/perl
# TEST_A~1.PY — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:abstraction-manager/TEST_A~1.PY
# auch in: Projects@abstractions:abstractions/test_abstractions_manager.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use Digest::SHA qw(sha256_hex);
use JSON qw(decode_json encode_json);
use Test::More;
use Test::Exception;
use FindBin qw($Bin);
use lib $Bin;

# Simuliere Exceptions
package ValidationError {
    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
    sub message { $_[0]->{message} }
}

package PortationError {
    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
    sub message { $_[0]->{message} }
}

package ApiKeyError {
    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
    sub message { $_[0]->{message} }
}

package StateFileError {
    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
    sub message { $_[0]->{message} }
}

# Simuliere validators
package validators {
    our @ALLOWED_TARGET_LANGUAGES = qw(perl5 perl6 javascript python bash powershell go);
    our @ALLOWED_AI_MODELS = (
        'openrouter/anthropic/claude-3.5-sonnet:beta',
        'openrouter/google/gemini-pro-1.5',
        'openrouter/meta-llama/llama-3-70b-instruct',
        'openrouter/mistralai/mixtral-8x22b-instruct',
        'openrouter/openai/gpt-4-turbo-2024-04-09',
        'openrouter/qwen/qwen2-72b-instruct',
    );

    sub validate_source_file_path {
        my ($path) = @_;
        my $workspace = $ENV{OPENCLAW_WORKSPACE} || die "OPENCLAW_WORKSPACE nicht gesetzt";
        $path = File::Spec->rel2abs($path);
        die ValidationError->new("Datei nicht gefunden") unless -f $path;
        die ValidationError->new("kein reguläres File") if -d $path;
        die ValidationError->new("Pfad außerhalb des Workspaces") unless $path =~ /^\Q$workspace\E/;
        return $path;
    }

    sub validate_task_description {
        my ($task) = @_;
        $task =~ s/^\s+|\s+$//g;
        die ValidationError->new("Leere Task-Beschreibung") if $task eq '';
        die ValidationError->new("Task zu lang") if length($task) > 500;
        die ValidationError->new("Unerlaubte Shell-Metazeichen") if $task =~ /[;&`$()|<>]/;
        return $task;
    }

    sub validate_ai_model_name {
        my ($model) = @_;
        die ValidationError->new("Modell nicht erlaubt") unless grep { $_ eq $model } @ALLOWED_AI_MODELS;
        return $model;
    }

    sub validate_target_language {
        my ($lang) = @_;
        $lang = lc($lang);
        die ValidationError->new("Sprache nicht unterstützt") unless grep { $_ eq $lang } @ALLOWED_TARGET_LANGUAGES;
        return $lang;
    }

    sub validate_timeout_seconds {
        my ($timeout) = @_;
        die ValidationError->new("Timeout muss Integer sein") unless $timeout =~ /^\d+$/;
        die ValidationError->new("Timeout außerhalb 1–7200") unless $timeout >= 1 && $timeout <= 7200;
        return $timeout;
    }

    sub load_and_validate_api_key {
        my ($provider) = @_;
        my $key = $ENV{"${provider}_API_KEY"};
        die ApiKeyError->new("API-Key nicht gesetzt") unless defined $key;
        die ApiKeyError->new("API-Key zu kurz") if length($key) < 20;
        return $key;
    }
}

# Simuliere create_abstraction
package create_abstraction {
    our %LANGUAGE_FILE_EXTENSIONS = (
        perl5 => '.pl',
        perl6 => '.raku',
        javascript => '.js',
        python => '.py',
        bash => '.sh',
        powershell => '.ps1',
        go => '.go',
    );

    sub compute_file_sha256 {
        my ($file) = @_;
        open my $fh, '<', $file or die "Kann $file nicht öffnen: $!";
        binmode $fh;
        my $digest = sha256_hex(do { local $/; <$fh> });
        close $fh;
        return $digest;
    }

    sub has_source_file_changed {
        my ($file, $hash_cache) = @_;
        my $current_hash = compute_file_sha256($file);
        my $cached_hash = $hash_cache->{$file};
        return !defined $cached_hash || $current_hash ne $cached_hash;
    }

    sub load_abstraction_state {
        my ($state_file) = @_;
        return {} unless -f $state_file;
        open my $fh, '<', $state_file or die "Kann $state_file nicht öffnen: $!";
        my $json_text = do { local $/; <$fh> };
        close $fh;
        eval {
            return decode_json($json_text);
        } or do {
            die StateFileError->new("Kann State-Datei nicht parsen: $@");
        };
    }

    sub save_abstraction_state_atomically {
        my ($state_file, $state) = @_;
        my ($volume, $directories) = File::Spec->splitpath($state_file);
        make_path($directories) unless -d $directories;
        my $temp_file = $state_file . '.tmp';
        open my $fh, '>', $temp_file or die "Kann $temp_file nicht öffnen: $!";
        print $fh encode_json($state);
        close $fh;
        rename $temp_file, $state_file or die "Kann $temp_file nicht nach $state_file umbenennen: $!";
    }
}

# ===========================================================================
# Fixtures
# ===========================================================================

sub temp_workspace {
    my $tmp_path = tempdir(CLEANUP => 1);
    my $workspace = File::Spec->catdir($tmp_path, 'workspace');
    my $scripts_dir = File::Spec->catdir($workspace, 'skills', 'scripts');
    make_path($scripts_dir);
    return $workspace;
}

sub valid_perl_script {
    my ($temp_workspace) = @_;
    my $scripts_dir = File::Spec->catdir($temp_workspace, 'skills', 'scripts');
    my $script = File::Spec->catfile($scripts_dir, 'db_maintainer.pl');
    open my $fh, '>', $script or die "Kann $script nicht öffnen: $!";
    print $fh "# Test-Script\nprint 'hello world';\n";
    close $fh;
    return $script;
}

sub state_file_path {
    my $tmp_path = tempdir(CLEANUP => 1);
    return File::Spec->catfile($tmp_path, 'db', 'abstractions_state.json');
}

# ===========================================================================
# Tests: Path-Traversal-Schutz
# ===========================================================================

subtest 'Path-Traversal-Schutz' => sub {
    my $workspace = temp_workspace();
    my $script = valid_perl_script($workspace);
    local $ENV{OPENCLAW_WORKSPACE} = $workspace;

    lives_ok {
        validators::validate_source_file_path($script);
    } 'Gültiger Pfad innerhalb des erlaubten Verzeichnisses wird akzeptiert';

    throws_ok {
        validators::validate_source_file_path('/absolutely/nonexistent/path/script.pl');
    } 'FileNotFoundError', 'Nicht existente Datei löst FileNotFoundError aus';

    throws_ok {
        validators::validate_source_file_path($workspace);
    } 'ValidationError', 'Verzeichnis-Pfad statt Datei löst ValidationError aus';

    throws_ok {
        validators::validate_source_file_path('/etc/passwd');
    } ['ValidationError', 'FileNotFoundError'], 'Pfade außerhalb des Workspaces werden blockiert';
};

# ===========================================================================
# Tests: Shell-Injection-Prävention
# ===========================================================================

subtest 'Shell-Injection-Prävention' => sub {
    my @valid_tasks = (
        'Port db_maintainer.pl to Go',
        'Add error handling to json_processor',
        'Refactor websearch-crawl.sh for Perl 5',
        'Port check-live.js with full JSDoc',
        'Migrate log_collector.pl to Ruby',
    );

    for my $task (@valid_tasks) {
        lives_ok {
            validators::validate_task_description($task);
        } "Gültige Task-Beschreibung akzeptiert: $task";
    }

    my @malicious_inputs = (
        ['; rm -rf /',           'Semikolon + Befehl'],
        ['$(cat /etc/passwd)',   'Befehlssubstitution $(...)'],
        ['`whoami`',             'Backtick-Substitution'],
        ['task && evil_cmd',     '&&-Verkettung'],
        ['task | cat /etc/shadow', 'Pipe-Redirect'],
        ["task\ncommand",        'Newline-Injection'],
        ['task; exit 0',         'Semikolon-Injection'],
        ['task > /tmp/evil',     'Ausgabe-Redirect'],
    );

    for my $malicious (@malicious_inputs) {
        my ($input, $desc) = @$malicious;
        throws_ok {
            validators::validate_task_description($input);
        } 'ValidationError', "Shell-Metazeichen blockiert: $desc";
    }

    throws_ok {
        validators::validate_task_description('');
    } 'ValidationError', 'Leere Task-Beschreibung löst ValidationError aus';

    throws_ok {
        validators::validate_task_description('   ');
    } 'ValidationError', 'Nur-Leerzeichen Task löst ValidationError aus';

    my $max_length_task = 'a' x 500;
    lives_ok {
        validators::validate_task_description($max_length_task);
    } 'Task exakt an der Maximallänge (500 Zeichen) wird akzeptiert';

    my $too_long_task = 'a' x 501;
    throws_ok {
        validators::validate_task_description($too_long_task);
    } 'ValidationError', 'Task über 500 Zeichen löst ValidationError aus';
};

# ===========================================================================
# Tests: Modell-Allowlist
# ===========================================================================

subtest 'Modell-Allowlist' => sub {
    for my $model (@validators::ALLOWED_AI_MODELS) {
        lives_ok {
            validators::validate_ai_model_name($model);
        } "Modell aus Allowlist akzeptiert: $model";
    }

    my @invalid_models = (
        'gpt-4',                          # Ohne Provider-Prefix
        'unknown-model',                   # Unbekanntes Modell
        'openrouter/evil; rm -rf /',       # Injection-Versuch
        '',                               # Leer
        'claude-3-5-sonnet-20241022',     # Ohne openrouter/-Prefix
    );

    for my $model (@invalid_models) {
        throws_ok {
            validators::validate_ai_model_name($model);
        } 'ValidationError', "Unbekanntes Modell blockiert: $model";
    }
};

# ===========================================================================
# Tests: Zielsprachen-Validierung
# ===========================================================================

subtest 'Zielsprachen-Validierung' => sub {
    for my $lang (@validators::ALLOWED_TARGET_LANGUAGES) {
        lives_ok {
            validators::validate_target_language($lang);
        } "Sprache akzeptiert: $lang";
    }

    lives_ok {
        validators::validate_target_language('JavaScript');
    } 'Zielsprachen werden auf Kleinschreibung normalisiert';

    throws_ok {
        validators::validate_target_language('cobol');
    } 'ValidationError', 'Nicht unterstützte Sprachen werden blockiert';

    throws_ok {
        validators::validate_target_language('perl5; rm -rf /');
    } 'ValidationError', 'Injection-Versuche in Sprachen-Parameter werden blockiert';
};

# ===========================================================================
# Tests: Timeout-Validierung
# ===========================================================================

subtest 'Timeout-Validierung' => sub {
    my @valid_timeouts = (1, 60, 1800, 3600, 7200);
    for my $timeout (@valid_timeouts) {
        lives_ok {
            validators::validate_timeout_seconds($timeout);
        } "Gültiger Timeout akzeptiert: $timeout";
    }

    my @invalid_timeouts = (0, -1, 7201, 99999);
    for my $timeout (@invalid_timeouts) {
        throws_ok {
            validators::validate_timeout_seconds($timeout);
        } 'ValidationError', "Ungültiger Timeout abgelehnt: $timeout";
    }

    throws_ok {
        validators::validate_timeout_seconds(1800.5);
    } 'ValidationError', 'Float-Timeout (kein Integer) löst ValidationError aus';
};

# ===========================================================================
# Tests: API-Schlüssel-Validierung
# ===========================================================================

subtest 'API-Schlüssel-Validierung' => sub {
    local $ENV{ANTHROPIC_API_KEY} = 'sk-ant-api03-' . ('x' x 30);
    lives_ok {
        validators::load_and_validate_api_key('ANTHROPIC');
    } 'Gültiger API-Schlüssel aus Umgebungsvariable wird zurückgegeben';

    delete $ENV{ANTHROPIC_API_KEY};
    throws_ok {
        validators::load_and_validate_api_key('ANTHROPIC');
    } 'ApiKeyError', 'Fehlende Umgebungsvariable löst ApiKeyError aus';

    local $ENV{ANTHROPIC_API_KEY} = 'short';
    throws_ok {
        validators::load_and_validate_api_key('ANTHROPIC');
    } 'ApiKeyError', 'Zu kurzer API-Schlüssel (< 20 Zeichen) löst ApiKeyError aus';
};

# ===========================================================================
# Tests: File-Change-Detection
# ===========================================================================

subtest 'File-Change-Detection' => sub {
    my $tmp_path = tempdir(CLEANUP => 1);
    my $test_file = File::Spec->catfile($tmp_path, 'script.pl');
    open my $fh, '>', $test_file or die "Kann $test_file nicht öffnen: $!";
    print $fh "print('hello');\n";
    close $fh;

    my $current_hash = create_abstraction::compute_file_sha256($test_file);
    my %hash_cache = ($test_file => $current_hash);

    ok(!create_abstraction::has_source_file_changed($test_file, \%hash_cache), 'Unveränderte Datei wird nicht als geändert erkannt');

    open $fh, '>', $test_file or die "Kann $test_file nicht öffnen: $!";
    print $fh "print('changed!');\n";
    close $fh;

    ok(create_abstraction::has_source_file_changed($test_file, \%hash_cache), 'Geänderte Datei wird korrekt als geändert erkannt');

    my %empty_cache;
    ok(create_abstraction::has_source_file_changed($test_file, \%empty_cache), 'Datei ohne gespeicherten Hash wird als neu/geändert erkannt');

    my $file_a = File::Spec->catfile($tmp_path, 'a.pl');
    my $file_b = File::Spec->catfile($tmp_path, 'b.pl');
    open $fh, '>', $file_a or die "Kann $file_a nicht öffnen: $!";
    print $fh "content A\n";
    close $fh;
    open $fh, '>', $file_b or die "Kann $file_b nicht öffnen: $!";
    print $fh "content B\n";
    close $fh;

    isnt(create_abstraction::compute_file_sha256($file_a), create_abstraction::compute_file_sha256($file_b), 'Verschiedene Dateien haben unterschiedliche SHA-256 Hashes');

    my $identical_content = "identical content";
    open $fh, '>', $file_a or die "Kann $file_a nicht öffnen: $!";
    print $fh $identical_content;
    close $fh;
    open $fh, '>', $file_b or die "Kann $file_b nicht öffnen: $!";
    print $fh $identical_content;
    close $fh;

    is(create_abstraction::compute_file_sha256($file_a), create_abstraction::compute_file_sha256($file_b), 'Identischer Inhalt produziert identischen Hash');
};

# ===========================================================================
# Tests: Atomisches State-File
# ===========================================================================

subtest 'Atomisches State-File' => sub {
    my $state_file = state_file_path();
    my %test_state = (
        file_hashes => { 'script.pl' => 'abc123' },
        last_run => '2026-05-26T10:00:00',
    );

    create_abstraction::save_abstraction_state_atomically($state_file, \%test_state);
    my $loaded_state = create_abstraction::load_abstraction_state($state_file);

    is_deeply($loaded_state, \%test_state, 'State wird korrekt gespeichert und geladen');

    my $nonexistent_path = File::Spec->catfile(tempdir(CLEANUP => 1), 'nonexistent', 'state.json');
    my $result = create_abstraction::load_abstraction_state($nonexistent_path);
    is_deeply($result, {}, 'Fehlende State-Datei gibt leeres Dictionary zurück');

    my $deep_path = File::Spec->catfile(tempdir(CLEANUP => 1), 'a', 'b', 'c', 'state.json');
    create_abstraction::save_abstraction_state_atomically($deep_path, { key => 'value' });
    ok(-f $deep_path, 'Atomisches Schreiben erstellt fehlende Verzeichnisse');

    my $state_path = File::Spec->catfile(tempdir(CLEANUP => 1), 'state.json');
    create_abstraction::save_abstraction_state_atomically($state_path, { data => 1 });
    my @temp_files = glob("$state_path.tmp");
    is(scalar @temp_files, 0, 'Nach erfolgreichem Schreiben gibt es keine .tmp-Datei');

    my $corrupted_state = File::Spec->catfile(tempdir(CLEANUP => 1), 'state.json');
    open my $fh, '>', $corrupted_state or die "Kann $corrupted_state nicht öffnen: $!";
    print $fh "{ invalid json !!!";
    close $fh;

    throws_ok {
        create_abstraction::load_abstraction_state($corrupted_state);
    } 'StateFileError', 'Korrupte State-Datei löst StateFileError aus';
};

# ===========================================================================
# Tests: Sprachzuordnung
# ===========================================================================

subtest 'Sprachzuordnung' => sub {
    for my $language (@validators::ALLOWED_TARGET_LANGUAGES) {
        ok(exists $create_abstraction::LANGUAGE_FILE_EXTENSIONS{$language}, "Jede unterstützte Zielsprache hat eine zugeordnete Datei-Extension: $language");
    }

    my %expected_extensions = (
        perl5 => '.pl',
        perl6 => '.raku',
        javascript => '.js',
        python => '.py',
        bash => '.sh',
        powershell => '.ps1',
        go => '.go',
    );

    for my $language (keys %expected_extensions) {
        is($create_abstraction::LANGUAGE_FILE_EXTENSIONS{$language}, $expected_extensions{$language}, "Korrekte Datei-Extension für $language");
    }
};

done_testing();
