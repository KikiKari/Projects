#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "f4ef6dc63b6a35e4efec808324cf75de66ede90c98fa0ae73d3ce4a978d2dbda", "source_sha256": "32c553ff84db01353f38346d4062c20eca53266e73641dd91fab7299527d9d37", "target_language": "tcl"}
# eval-review.html — portiert nach tcl
# Quelle: html, Projects@python-hardener:python-hardener/eval-review.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl/Tk GUI zur Darstellung eines HTML-Dokuments
# Dieses Skript erstellt eine grafische Oberfläche, die dem Inhalt der 
# HTML-Datei eval-review.html nachempfunden ist. Es verwendet Tk für die 
# GUI-Komponenten und simuliert das Layout sowie einige Interaktionen.

package require Tk

# Hauptfenster konfigurieren
wm title . "Eval Review"
wm geometry . 1000x700

# Globale Variablen
set skill_name "python-hardener"
set current_index 0
set visited_runs {}
set feedback_map {}

# Beispiel-Datenstruktur (simuliert den eingebetteten JavaScript-Datenblock)
# In einer realen Anwendung würden diese Daten dynamisch geladen werden.
set runs_data {
    {
        id "eval-0-job-runner-with_skill"
        prompt "This job_runner.py script is used in production cron jobs. Can you do a full review and fix — security, error handling, logging, and docstrings? It currently opens the log file on every single call and uses os.chdir() somewhere. Please fix the file and give me a documentation markdown."
        eval_id 0
        outputs {
            {
                name "job_runner.md"
                type "text"
                content "# job_runner.py\n\n## Overview\n\n\`job_runner.py\` is a production cron-job runner that sequentially executes a\nfixed set of build, test, and lint commands, commits the resulting changes to\na local Git repository, and persists run state to a JSON file.  All operational\noutput is routed through Python's \`logging\` module with a rotating file handler\nand a console handler configured once at start-up.\n\n---\n\n## Architecture\n\n\`\`\`\nmain()\n  │\n  ├─ setup_logging()          — configure RotatingFileHandler + StreamHandler once\n  ├─ load_state()             — read job_state.json (safe default on failure)\n  │\n  ├─ run_job(\"build\", [...])  ─┐\n  ├─ run_job(\"test\",  [...])   ├─ subprocess.run(cmd, shell=False, cwd unchanged)\n  ├─ run_job(\"lint\",  [...])  ─┘\n  │\n  ├─ commit_results(msg)      — git -C <repo> add . && git -C <repo> commit -m msg\n  └─ save_state(state)        — atomic write via tempfile + os.replace()\n\`\`\`"
            }
            {
                name "job_runner.py"
                type "text"
                content "#!/usr/bin/env python3\n\"\"\"\njob_runner.py — Production cron job runner.\n\nExecutes a fixed set of build/test/lint jobs, commits results to a local Git\nrepository, and persists run state to a JSON file.  All log output goes through\nPython's standard \`\`logging\`\` module (RotatingFileHandler + StreamHandler).\n\"\"\"\n\nimport json\nimport logging\nimport logging.handlers\nimport os\nimport subprocess\nimport tempfile\nfrom datetime import datetime\nfrom pathlib import Path\nfrom typing import Optional\n\n# ---------------------------------------------------------------------------\n# Paths — resolved from environment variables so deployments can override them\n# without changing the file.\n# ---------------------------------------------------------------------------\nWORKSPACE: Path = Path(os.environ.get(\"JOB_RUNNER_WORKSPACE\", \"/home/runner/workspace\"))\nSTATE_FILE: Path = WORKSPACE / \"job_state.json\"\nLOG_DIR: Path = Path(os.environ.get(\"JOB_RUNNER_LOG_DIR\", str(WORKSPACE / \"logs\")))\nGIT_REPO: Path = Path(os.environ.get(\"JOB_RUNNER_GIT_REPO\", str(WORKSPACE / \"output-repo\")))\n\n# Module-level logger; configured in setup_logging().\nlogger = logging.getLogger(__name__)"
            }
        }
        grading {
            assertions {
                {text "No bare except: blocks (AST-verified)" passed 1 evidence "AST bare handler count: 0"}
                {text "os.chdir() removed (AST-verified)" passed 1 evidence "AST chdir call count: 0"}
                {text "No shell=True in subprocess calls (AST-verified)" passed 1 evidence "AST shell=True count: 0"}
                {text "RotatingFileHandler used for logging" passed 1 evidence "grep for 'RotatingFileHandler' in output"}
                {text "Atomic state write (tempfile/os.replace)" passed 1 evidence "grep for 'os.replace' or 'tempfile'"}
                {text "Documentation .md file produced" passed 1 evidence "File exists: /sessions/epic-relaxed-noether/mnt/outputs/python-hardener-workspace/iteration-1/eval-0-job-runner/with_skill/outputs/job_runner.md"}
            }
            score 6
            total 6
            pass_rate 1.0
        }
    }
    {
        id "eval-0-job-runner-without_skill"
        prompt "This job_runner.py script is used in production cron jobs. Can you do a full review and fix — security, error handling, logging, and docstrings? It currently opens the log file on every single call and uses os.chdir() somewhere. Please fix the file and give me a documentation markdown."
        eval_id 0
        outputs {
            {
                name "job_runner.md"
                type "text"
                content "# job_runner.py — Review & Fix Documentation\n\n## Overview\n\n\`job_runner.py\` is a production cron-job runner that executes a fixed set of\nbuild, test, and lint commands, persists run state to a JSON file, and\ncommits results to a local Git repository.\n\n---\n\n## Issues Found and Fixed\n\n### 1. Security — \`shell=True\` in \`run_job()\`\n\n**Original**\n\`\`\`python\nresult = subprocess.run(cmd, shell=True, capture_output=True, text=True)\n\`\`\`\n\n**Problem**  \n\`shell=True\` passes the command string to \`/bin/sh -c\`, which allows shell\nmetacharacters (\`;\`, \`&&\`, \`|\`, \`$()\`, etc.) embedded in \`cmd\` to be\ninterpreted.  If \`cmd\` ever contains user-supplied or environment-derived\ndata, this is a shell-injection vulnerability.\n\n**Fix**  \nSplit the command string on whitespace and pass a list to \`subprocess.run\`\nwith \`shell=False\` (the default):\n\n\`\`\`python\nresult = subprocess.run(\n    cmd.split(),\n    shell=False,\n    capture_output=True,\n    text=True,\n    timeout=300,\n)\n\`\`\`"
            }
            {
                name "job_runner.py"
                type "text"
                content "#!/usr/bin/env python3\n\"\"\"job_runner.py — Production cron-job runner.\n\nRuns a fixed set of build/test/lint jobs, records their outcomes in a\npersistent JSON state file, and commits the results to a local Git\nrepository.\n\nTypical usage (from cron)::\n\n    /usr/bin/python3 /opt/scripts/job_runner.py\n\nExit codes:\n    0  All jobs passed and state was saved successfully.\n    1  One or more jobs failed (logged; script still exits cleanly so cron\n       does not flood the operator with \"command failed\" e-mails — see the\n       log for details).\n\"\"\"\n\nimport json\nimport logging\nimport subprocess\nimport sys\nfrom datetime import datetime, timezone\nfrom pathlib import Path\n\n# ---------------------------------------------------------------------------\n# Configuration\n# ---------------------------------------------------------------------------\n\nWORKSPACE: Path = Path(\"/home/runner/workspace\")\nSTATE_FILE: Path = WORKSPACE / \"job_state.json\"\nLOG_DIR: Path = WORKSPACE / \"logs\"\nGIT_REPO: Path = WORKSPACE / \"output-repo\""
            }
        }
        grading {
            assertions {
                {text "No bare except: blocks (AST-verified)" passed 1 evidence "AST bare handler count: 0"}
                {text "os.chdir() removed (AST-verified)" passed 1 evidence "AST chdir call count: 0"}
                {text "No shell=True in subprocess calls (AST-verified)" passed 1 evidence "AST shell=True count: 0"}
                {text "RotatingFileHandler used for logging" passed 0 evidence "grep for 'RotatingFileHandler' in output"}
                {text "Atomic state write (tempfile/os.replace)" passed 0 evidence "grep for 'os.replace' or 'tempfile'"}
                {text "Documentation .md file produced" passed 1 evidence "File exists: /sessions/epic-relaxed-noether/mnt/outputs/python-hardener-workspace/iteration-1/eval-0-job-runner/without_skill/outputs/job_runner.md"}
            }
            score 4
            total 6
            pass_rate 0.6666666666666666
        }
    }
}

# Styles (als Arrays)
array set colors {
    bg #faf9f5
    surface #ffffff
    border #e8e6dc
    text #141413
    text_muted #b0aea5
    accent #d97757
    accent_hover #c4613f
    green #788c5d
    green_bg #eef2e8
    red #c44
    red_bg #fceaea
    header_bg #141413
    header_text #faf9f5
}

# Hilfsfunktionen
proc create_style_frame {parent name args} {
    frame $parent.$name {*}$args
    $parent.$name configure -background $::colors(surface) -relief solid -bd 1
    return $parent.$name
}

proc create_section {parent title} {
    set f [frame $parent.sec_[string map {" " "_" $title ""}] -bg $::colors(surface) -relief solid -bd 1]
    
    set header [frame $f.header -bg $::colors(bg)]
    label $header.title -text $title -font {Arial 10 bold} -fg $::colors(text_muted) -bg $::colors(bg)
    pack $header.title -side left -padx 10 -pady 5
    
    set body [frame $f.body -bg white]
    
    pack $header -side top -fill x
    pack $body -side top -fill both -expand 1 -padx 10 -pady 10
    
    pack $f -side top -fill x -padx 10 -pady 5
    
    return $body
}

proc show_run {index} {
    global runs_data current_index visited_runs
    
    set current_index $index
    set run [lindex $runs_data $index]
    
    # Titel aktualisieren
    set config [dict get $run id]
    .header.title configure -text "Eval Review: $::skill_name ($config)"
    
    # Prompt anzeigen
    set prompt_text [dict get $run prompt]
    .main.prompt.body.text configure -state normal
    .main.prompt.body.text delete 1.0 end
    .main.prompt.body.text insert end $prompt_text
    .main.prompt.body.text configure -state disabled
    
    # Outputs anzeigen
    set outputs [dict get $run outputs]
    destroy .main.outputs.body.f*
    
    if {[llength $outputs] == 0} {
        label .main.outputs.body.empty -text "No output files found" -fg $::colors(text_muted) -font {Arial 10 italic}
        pack .main.outputs.body.empty -pady 20
    } else {
        foreach file $outputs {
            set fname [dict get $file name]
            set ftype [dict get $file type]
            set fcontent [dict get $file content]
            
            set f [create_style_frame .main.outputs.body f_[string map {"." "_" $fname ""}] -bg white]
            
            set header [frame $f.header -bg $::colors(bg) -relief solid -bd 1]
            label $header.name -text $fname -font {Arial 10 bold} -bg $::colors(bg)
            button $header.dl -text "Download" -font {Arial 8} -command "puts \"Downloading $fname\""
            pack $header.name -side left -padx 5
            pack $header.dl -side right -padx 5
            pack $header -side top -fill x
            
            set content [text $f.content -wrap word -bg white -font {Courier 10}]
            $content insert end $fcontent
            $content configure -state disabled
            pack $content -side top -fill both -expand 1 -padx 5 -pady 5
            
            pack $f -side top -fill x -pady 2
        }
    }
    
    # Grades anzeigen
    if {[dict exists $run grading]} {
        set grading [dict get $run grading]
        set assertions [dict get $grading assertions]
        set pass_rate [dict get $grading pass_rate]
        
        destroy .main.grades.body.f*
        
        # Zusammenfassung
        set summary_frame [frame .main.grades.body.summary -bg white]
        set pass_label [expr {int($pass_rate * 100)}]%
        set grade_color [expr {$pass_rate >= 0.8 ? "green" : ($pass_rate >= 0.5 ? "yellow" : "red")}]
        label $summary_frame.rate -text "$pass_label passed" -fg $grade_color -font {Arial 10 bold}
        pack $summary_frame.rate -side left -padx 10 -pady 5
        pack $summary_frame -side top -fill x
        
        # Assertion Liste
        set listbox [listbox .main.grades.body.list -height 8 -font {Arial 9}]
        foreach assertion $assertions {
            set text [dict get $assertion text]
            set passed [dict get $assertion passed]
            set status [expr {$passed ? "✓" : "✗"}]
            $listbox insert end "$status $text"
            $listbox itemconfigure end -fg [expr {$passed ? $::colors(green) : $::colors(red)}]
        }
        pack $listbox -side top -fill both -expand 1 -padx 10 -pady 5
        
        .main.grades configure -visible 1
    } else {
        .main.grades configure -visible 0
    }
    
    # Navigation aktualisieren
    .nav.prev configure -state [expr {$index == 0 ? "disabled" : "normal"}]
    .nav.next configure -state [expr {$index == [llength $runs_data]-1 ? "disabled" : "normal"}]
    
    # Fortschritt aktualisieren
    .header.progress configure -text "[expr {$index + 1}] of [llength $runs_data]"
    
    lappend visited_runs $index
    set visited_runs [lsort -unique $visited_runs]
    
    # Submit Button aktivieren, wenn alle besucht wurden
    if {[llength $visited_runs] >= [llength $runs_data]} {
        .nav.done configure -bg $::colors(accent) -fg white
    }
}

proc navigate {delta} {
    global current_index runs_data
    set new_index [expr {$current_index + $delta}]
    if {$new_index >= 0 && $new_index < [llength $runs_data]} {
        show_run $new_index
    }
}

# GUI aufbauen
frame .header -bg $::colors(header_bg) -height 60
pack .header -side top -fill x

label .header.title -text "Eval Review: $skill_name" -bg $::colors(header_bg) -fg $::colors(header_text) -font {Arial 12 bold}
pack .header.title -side left -padx 20 -pady 10

label .header.progress -text "1 of [llength $runs_data]" -bg $::colors(header_bg) -fg $::colors(header_text) -font {Arial 10}
pack .header.progress -side right -padx 20 -pady 10

# Hauptbereich
frame .main -bg $::colors(bg)
pack .main -side top -fill both -expand 1

# Prompt Section
set prompt_body [create_section .main "Prompt"]
text $prompt_body.text -wrap word -height 8 -font {Arial 10}
pack $prompt_body.text -fill both -expand 1

# Outputs Section
set outputs_body [create_section .main "Output"]

# Grades Section
set grades_body [create_section .main "Formal Grades"]
.main.grades configure -visible 0

# Feedback Section
set feedback_body [create_section .main "Your Feedback"]
text $feedback_body.feedback -wrap word -height 6 -font {Arial 10}
pack $feedback_body.feedback -fill both -expand 1

label $feedback_body.status -text "" -fg $::colors(text_muted) -font {Arial 9}
pack $feedback_body.status -side top -anchor w -pady 5

# Navigation
frame .nav -bg $::colors(surface) -height 50
pack .nav -side bottom -fill x

button .nav.prev -text "← Previous" -font {Arial 10} -command {navigate -1}
pack .nav.prev -side left -padx 20 -pady 10

button .nav.done -text "Submit All Reviews" -font {Arial 10} -command {tk_messageBox -message "Reviews submitted!"}
pack .nav.done -side left -padx 20 -pady 10 -expand 1

button .nav.next -text "Next →" -font {Arial 10} -command {navigate 1}
pack .nav.next -side right -padx 20 -pady 10

# Initiales Laden
show_run 0

# Tastaturkürzel
bind . <Key-Left> {navigate -1}
bind . <Key-Right> {navigate 1}
bind . <Key-Up> {navigate -1}
bind . <Key-Down> {navigate 1}
focus .

# Beenden mit ESC
bind . <Escape> {exit}
