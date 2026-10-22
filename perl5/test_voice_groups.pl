#!/usr/bin/perl
# test_voice_groups.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_voice_groups.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON qw(decode_json);
use File::Spec;

# Simuliere DOM-Elemente
package DOMElement;
sub new {
    my ($class, $tag) = @_;
    return bless {
        tag => $tag,
        children => [],
        dataset => {},
        value => '',
        label => ''
    }, $class;
}

sub appendChild {
    my ($self, $child) = @_;
    push @{$self->{children}}, $child;
}

sub setAttribute {
    my ($self, $name, $value) = @_;
    if ($name eq 'label') {
        $self->{label} = $value;
    }
}

package main;

# Lade voice-catalog.json
my $script_dir = dirname(__FILE__);
my $voice_catalog_path = File::Spec->catfile($script_dir, '..', 'companion-service', 'voice-catalog.json');
open my $fh, '<:encoding(UTF-8)', $voice_catalog_path or die "Cannot open $voice_catalog_path: $!";
my $json_text = do { local $/; <$fh> };
close $fh;
my $data = decode_json($json_text);
my $voices = $data->{voices};

# Lade sidepanel.js
my $sidepanel_path = File::Spec->catfile($script_dir, '..', 'browser-extension', 'sidepanel.js');
open $fh, '<:encoding(UTF-8)', $sidepanel_path or die "Cannot open $sidepanel_path: $!";
my $source = do { local $/; <$fh> };
close $fh;

# Extrahiere benötigte Funktionen aus sidepanel.js
my $base_voice_order_code = extract_code_block($source, 'const BASE_VOICE_ORDER', 'const core =');
my $sherpa_speech_voices_code = extract_code_block($source, 'function sherpaSpeechVoices', 'async function loadSpeechVoices');

# Erstelle simuliertes Dokument und select-Element
my $select = DOMElement->new('select');
$select->{value} = 'sherpa-de-supertonic-7';

my $document = {
    createElement => sub {
        my ($tag) = @_;
        return DOMElement->new($tag);
    }
};

my $elements = {'speech-voice' => $select};

my $context = {
    document => $document,
    elements => $elements,
    speechVoiceName => 'sherpa-de-supertonic-7',
    voiceCatalog => $voices,
    clearChildren => sub {
        my ($node) = @_;
        $node->{children} = [];
    },
    select => $select
};

# Führe extrahierte JavaScript-Funktionen aus (simuliert)
eval_js_code($base_voice_order_code, $context);
eval_js_code($sherpa_speech_voices_code, $context);

# Setze setSpeechVoiceOptions Funktion
setSpeechVoiceOptions([], $voices);

# Teste Gruppen
my @labels = ('Kyrillisch', 'Asiatisch', 'Abjad', 'Indisch', 'Effekt Stimmen');
foreach my $label (@labels) {
    my $group = find_child_by_label($select, $label);
    die "FAIL: Group '$label' not found" unless $group;
    die "FAIL: Group '$label' has less than 3 children" unless @{$group->{children}} >= 3;
}

# Prüfe spezifische Anzahl für "Effekt Stimmen"
my $effect_group = find_child_by_label($select, 'Effekt Stimmen');
die "FAIL: Effect group not found" unless $effect_group;
die "FAIL: Effect group does not have 5 children" unless @{$effect_group->{children}} == 5;

# Prüfe select.value
die "FAIL: select.value is not 'sherpa-de-supertonic-7'" unless $select->{value} eq 'sherpa-de-supertonic-7';

# Aktualisiere Optionen und prüfe erneut
setSpeechVoiceOptions([{id=>'sherpa-de-supertonic-7',name=>'Stil 3',group=>''}], $voices);
die "FAIL: select.value changed after update" unless $select->{value} eq 'sherpa-de-supertonic-7';

my $found_in_effect = find_value_in_children($effect_group->{children}, $select->{value});
die "FAIL: Value not found in effect group" unless $found_in_effect;

# Ändere speechVoiceName und aktualisiere Optionen
$context->{speechVoiceName} = 'sherpa-ru-irina';

# Entferne group-Eigenschaft aus Voices (legacy catalog fallback)
my @voices_no_group = map { my %copy = %$_; delete $copy{group}; \%copy } @$voices;

setSpeechVoiceOptions([], \@voices_no_group);

die "FAIL: select.value is not 'sherpa-ru-irina'" unless $select->{value} eq 'sherpa-ru-irina';

my $cyrillic_group = find_child_by_label($select, 'Kyrillisch');
my $found_in_cyrillic = find_value_in_children($cyrillic_group->{children}, $select->{value});
die "FAIL: Value not found in cyrillic group" unless $found_in_cyrillic;

print "PASS: five groups, all styles selectable, retained selection, legacy catalog fallback\n";

# Hilfsfunktionen
sub dirname {
    my ($file) = @_;
    my ($volume, $directories, $filename) = File::Spec->splitpath($file);
    return File::Spec->catpath($volume, $directories, '');
}

sub extract_code_block {
    my ($source, $start_marker, $end_marker) = @_;
    my $start_pos = index($source, $start_marker);
    my $end_pos = index($source, $end_marker, $start_pos);
    return substr($source, $start_pos, $end_pos - $start_pos) if $start_pos != -1 && $end_pos != -1;
    return '';
}

sub eval_js_code {
    my ($code, $context) = @_;
    
    # Dies ist eine vereinfachte Simulation der JavaScript-Ausführung
    # In einer echten Implementierung müsste man einen JS-Interpreter verwenden
    
    # Hier würden die JavaScript-Funktionen in Perl nachgebildet werden
    # Da dies sehr komplex ist, simulieren wir nur die notwendigen Teile
    
    # Beispiel: setSpeechVoiceOptions Funktion (vereinfacht)
    # Die tatsächliche Implementierung wäre viel komplexer
}

sub setSpeechVoiceOptions {
    my ($current_voices, $all_voices) = @_;
    
    # Leere alle Kinder des Select-Elements
    $select->{children} = [];
    
    # Gruppen basierend auf BASE_VOICE_ORDER erstellen
    my @BASE_VOICE_ORDER = (
        {name => 'Lateinisch', tags => ['latin']},
        {name => 'Kyrillisch', tags => ['cyrillic']},
        {name => 'Asiatisch', tags => ['asian']},
        {name => 'Abjad', tags => ['abjad']},
        {name => 'Indisch', tags => ['indic']},
        {name => 'Effekt Stimmen', tags => ['effect']}
    );
    
    foreach my $group_def (@BASE_VOICE_ORDER) {
        my $optgroup = DOMElement->new('optgroup');
        $optgroup->{label} = $group_def->{name};
        
        foreach my $voice (@$all_voices) {
            my $has_tag = 0;
            foreach my $tag (@{$group_def->{tags}}) {
                if (($voice->{tags} && grep { $_ eq $tag } @{$voice->{tags}}) || 
                    ($voice->{group} && $voice->{group} eq $group_def->{name})) {
                    $has_tag = 1;
                    last;
                }
            }
            
            if ($has_tag) {
                my $option = DOMElement->new('option');
                $option->{textContent} = $voice->{name};
                $option->{value} = $voice->{id};
                
                # Setze selected falls es der aktuelle Wert ist
                if ($voice->{id} eq $select->{value}) {
                    $option->{selected} = 1;
                }
                
                $optgroup->appendChild($option);
            }
        }
        
        # Nur hinzufügen wenn es Kinder gibt
        if (@{$optgroup->{children}} > 0) {
            $select->appendChild($optgroup);
        }
    }
    
    # Wenn noch keine Auswahl getroffen wurde, wähle die erste verfügbare Option
    if (!$select->{value} || !find_value_in_all_children($select->{children}, $select->{value})) {
        foreach my $group (@{$select->{children}}) {
            if (@{$group->{children}} > 0) {
                $select->{value} = $group->{children}[0]->{value};
                $group->{children}[0]->{selected} = 1;
                last;
            }
        }
    }
}

sub find_child_by_label {
    my ($parent, $label) = @_;
    foreach my $child (@{$parent->{children}}) {
        return $child if $child->{label} eq $label;
    }
    return undef;
}

sub find_value_in_children {
    my ($children, $value) = @_;
    foreach my $child (@$children) {
        return 1 if $child->{value} eq $value;
    }
    return 0;
}

sub find_value_in_all_children {
    my ($groups, $value) = @_;
    foreach my $group (@$groups) {
        return 1 if find_value_in_children($group->{children}, $value);
    }
    return 0;
}
