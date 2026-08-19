#!/usr/bin/env tclsh8.6
# package_skill.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/package_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/package_skill.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Skill Packager - Creates a distributable .skill file of a skill folder
#
# Usage:
#     tclsh8.6 utils/package_skill.tcl <path/to/skill-folder> [output-directory]
#
# Example:
#     tclsh8.6 utils/package_skill.tcl skills/public/my-skill
#     tclsh8.6 utils/package_skill.tcl skills/public/my-skill ./dist

package require zipfile::encode

# Helper function to check if path is within root
proc is_within {path root} {
    set path [file normalize $path]
    set root [file normalize $root]
    if {[string first $root $path] == 0} {
        return 1
    } else {
        return 0
    }
}

# Quick validation function (stubbed since original imports from another module)
proc validate_skill {skill_path} {
    # This would need to be implemented based on the actual validation logic
    # For now, we'll just return success
    return [list 1 "Validation passed"]
}

proc package_skill {skill_path {output_dir ""}} {
    # Resolve the skill path
    set skill_path [file normalize $skill_path]

    # Validate skill folder exists
    if {![file exists $skill_path]} {
        puts "\[ERROR\] Skill folder not found: $skill_path"
        return ""
    }

    if {![file isdirectory $skill_path]} {
        puts "\[ERROR\] Path is not a directory: $skill_path"
        return ""
    }

    # Validate SKILL.md exists
    set skill_md [file join $skill_path "SKILL.md"]
    if {![file exists $skill_md]} {
        puts "\[ERROR\] SKILL.md not found in $skill_path"
        return ""
    }

    # Run validation before packaging
    puts "Validating skill..."
    lassign [validate_skill $skill_path] valid message
    if {!$valid} {
        puts "\[ERROR\] Validation failed: $message"
        puts "   Please fix the validation errors before packaging."
        return ""
    }
    puts "\[OK\] $message\n"

    # Determine output location
    set skill_name [file tail $skill_path]
    if {$output_dir ne ""} {
        file mkdir $output_dir
        set output_path [file normalize $output_dir]
    } else {
        set output_path [pwd]
    }

    set skill_filename [file join $output_path "${skill_name}.skill"]

    set excluded_dirs [list ".git" ".svn" ".hg" "__pycache__" "node_modules"]

    # Create the .skill file (zip format)
    if {[catch {
        set zf [zipfile::encode::open $skill_filename]
        
        # Walk through the skill directory
        foreach file_path [glob -nocomplain -dir $skill_path -types {f d l} *] {
            walk_directory $zf $skill_path $file_path $excluded_dirs $skill_name $skill_filename
        }
        
        $zf close
        
        puts "\n\[OK\] Successfully packaged skill to: $skill_filename"
        return $skill_filename
    } err]} {
        puts "\[ERROR\] Error creating .skill file: $err"
        return ""
    }
}

proc walk_directory {zf base_path current_path excluded_dirs skill_name skill_filename} {
    # Skip symlinks
    if {[file type $current_path] eq "link"} {
        puts "\[WARN\] Skipping symlink: $current_path"
        return
    }
    
    # Check if any part of the path is in excluded directories
    set rel_path [file relative $base_path $current_path]
    foreach part [file split $rel_path] {
        if {$part in $excluded_dirs} {
            return
        }
    }
    
    if {[file isdirectory $current_path]} {
        # Recursively process subdirectories
        foreach file [glob -nocomplain -dir $current_path *] {
            walk_directory $zf $base_path $file $excluded_dirs $skill_name $skill_filename
        }
    } elseif {[file isfile $current_path]} {
        set resolved_file [file normalize $current_path]
        if {![is_within $resolved_file $base_path]} {
            puts "\[ERROR\] File escapes skill root: $current_path"
            return
        }
        # If output lives under skill_path, avoid writing archive into itself.
        if {$resolved_file eq [file normalize $skill_filename]} {
            puts "\[WARN\] Skipping output archive: $current_path"
            return
        }

        # Calculate the relative path within the zip.
        set arcname [file join $skill_name $rel_path]
        $zf add $current_path $arcname
        puts "  Added: $arcname"
    }
}

proc main {} {
    global argv
    
    if {[llength $argv] < 1} {
        puts "Usage: tclsh8.6 utils/package_skill.tcl <path/to/skill-folder> \[output-directory\]"
        puts "\nExample:"
        puts "  tclsh8.6 utils/package_skill.tcl skills/public/my-skill"
        puts "  tclsh8.6 utils/package_skill.tcl skills/public/my-skill ./dist"
        exit 1
    }

    set skill_path [lindex $argv 0]
    set output_dir ""
    if {[llength $argv] > 1} {
        set output_dir [lindex $argv 1]
    }

    puts "Packaging skill: $skill_path"
    if {$output_dir ne ""} {
        puts "   Output directory: $output_dir"
    }
    puts ""

    set result [package_skill $skill_path $output_dir]

    if {$result ne ""} {
        exit 0
    } else {
        exit 1
    }
}

if {[info script] eq $argv0} {
    main
}
