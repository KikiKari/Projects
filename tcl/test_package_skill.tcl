#!/usr/bin/env tclsh8.6
# test_package_skill.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/test_package_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/test_package_skill.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Regression tests for skill packaging security behavior.

package require Tcl 8.6
package require zipfile::encode
package require fileutil
package require fileutil::tempfile

# Set up test environment
set scriptDir [file normalize [file dirname $argv0]]
if {[lsearch -exact $::auto_path $scriptDir] == -1} {
    set ::auto_path [linsert $::auto_path 0 $scriptDir]
}

# Create fake quick_validate module
namespace eval ::quick_validate {
    proc validate_skill {path} {
        return [list true "Skill is valid!"]
    }
}

# Import package_skill
if {[catch {package require package_skill}]} {
    # If package doesn't exist, source the file directly
    if {[file exists [file join $scriptDir package_skill.tcl]]} {
        source [file join $scriptDir package_skill.tcl]
    } else {
        error "Cannot find package_skill"
    }
}

# Test class implementation using TclOO
package require TclOO

oo::class create TestPackageSkillSecurity {
    variable tempDir
    
    constructor {} {
        set tempDir [fileutil::tempdir test_skill_]
    }
    
    destructor {
        if {[file exists $tempDir]} {
            file delete -force $tempDir
        }
    }
    
    method create_skill {{name "test-skill"}} {
        set skillDir [file join $tempDir $name]
        file mkdir $skillDir
        set f [open [file join $skillDir SKILL.md] w]
        puts $f "---\nname: test-skill\ndescription: test\n---\n"
        close $f
        set f [open [file join $skillDir script.py] w]
        puts $f "print('ok')\n"
        close $f
        return $skillDir
    }
    
    method test_packages_normal_files {} {
        set skillDir [my create_skill "normal-skill"]
        set outDir [file join $tempDir out]
        file mkdir $outDir
        
        set result [package_skill $skillDir $outDir]
        
        if {$result eq ""} {
            error "Result should not be empty"
        }
        
        set skillFile [file join $outDir "normal-skill.skill"]
        if {![file exists $skillFile]} {
            error "Skill file was not created"
        }
        
        # Read zip contents
        set names [zipfile::encode::listfiles $skillFile]
        if {[lsearch -exact $names "normal-skill/SKILL.md"] == -1} {
            error "SKILL.md not found in archive"
        }
        if {[lsearch -exact $names "normal-skill/script.py"] == -1} {
            error "script.py not found in archive"
        }
    }
    
    method test_skips_symlink_to_external_file {} {
        set skillDir [my create_skill "symlink-file-skill"]
        set outside [file join $tempDir "outside-secret.txt"]
        set f [open $outside w]
        puts $f "super-secret\n"
        close $f
        set link [file join $skillDir "loot.txt"]
        set outDir [file join $tempDir out]
        file mkdir $outDir
        
        # Try to create symlink
        if {[catch {
            file link $link $outside
        }]} {
            puts "SKIP: symlink unsupported on this platform"
            return
        }
        
        set result [package_skill $skillDir $outDir]
        if {$result eq ""} {
            error "Result should not be empty"
        }
        
        set skillFile [file join $outDir "symlink-file-skill.skill"]
        if {![file exists $skillFile]} {
            error "Skill file was not created"
        }
        
        # Read zip contents
        set names [zipfile::encode::listfiles $skillFile]
        if {[lsearch -exact $names "symlink-file-skill/SKILL.md"] == -1} {
            error "SKILL.md not found in archive"
        }
        if {[lsearch -exact $names "symlink-file-skill/script.py"] == -1} {
            error "script.py not found in archive"
        }
        if {[lsearch -exact $names "symlink-file-skill/loot.txt"] != -1} {
            error "loot.txt should not be in archive"
        }
    }
    
    method test_skips_symlink_directory {} {
        set skillDir [my create_skill "symlink-dir-skill"]
        set outsideDir [file join $tempDir "outside"]
        file mkdir $outsideDir
        set f [open [file join $outsideDir "secret.txt"] w]
        puts $f "secret\n"
        close $f
        set link [file join $skillDir "docs"]
        set outDir [file join $tempDir out]
        file mkdir $outDir
        
        # Try to create directory symlink
        if {[catch {
            file link -directory $link $outsideDir
        }]} {
            puts "SKIP: symlink unsupported on this platform"
            return
        }
        
        set result [package_skill $skillDir $outDir]
        if {$result eq ""} {
            error "Result should not be empty"
        }
        
        set skillFile [file join $outDir "symlink-dir-skill.skill"]
        # Read zip contents
        set names [zipfile::encode::listfiles $skillFile]
        if {[lsearch -exact $names "symlink-dir-skill/SKILL.md"] == -1} {
            error "SKILL.md not found in archive"
        }
        if {[lsearch -exact $names "symlink-dir-skill/script.py"] == -1} {
            error "script.py not found in archive"
        }
        if {[lsearch -exact $names "symlink-dir-skill/docs/secret.txt"] != -1} {
            error "docs/secret.txt should not be in archive"
        }
    }
    
    method test_allows_nested_regular_files {} {
        set skillDir [my create_skill "nested-skill"]
        set nested [file join $skillDir "lib" "helpers"]
        file mkdir $nested
        set f [open [file join $nested "util.py"] w]
        puts $f "def run():\n    return 1\n"
        close $f
        set outDir [file join $tempDir out]
        file mkdir $outDir
        
        set result [package_skill $skillDir $outDir]
        
        if {$result eq ""} {
            error "Result should not be empty"
        }
        
        set skillFile [file join $outDir "nested-skill.skill"]
        # Read zip contents
        set names [zipfile::encode::listfiles $skillFile]
        if {[lsearch -exact $names "nested-skill/lib/helpers/util.py"] == -1} {
            error "util.py not found in archive"
        }
    }
    
    method test_skips_output_archive_when_output_dir_is_skill_dir {} {
        set skillDir [my create_skill "self-output-skill"]
        
        set result [package_skill $skillDir $skillDir]
        
        if {$result eq ""} {
            error "Result should not be empty"
        }
        
        set skillFile [file join $skillDir "self-output-skill.skill"]
        if {![file exists $skillFile]} {
            error "Skill file was not created"
        }
        
        # Read zip contents
        set names [zipfile::encode::listfiles $skillFile]
        if {[lsearch -exact $names "self-output-skill/SKILL.md"] == -1} {
            error "SKILL.md not found in archive"
        }
        if {[lsearch -exact $names "self-output-skill/script.py"] == -1} {
            error "script.py not found in archive"
        }
        if {[lsearch -exact $names "self-output-skill/self-output-skill.skill"] != -1} {
            error "self-output-skill.skill should not be in archive"
        }
    }
}

# Run tests
proc run_tests {} {
    set testObj [TestPackageSkillSecurity new]
    
    foreach testMethod {
        test_packages_normal_files
        test_skips_symlink_to_external_file
        test_skips_symlink_directory
        test_allows_nested_regular_files
        test_skips_output_archive_when_output_dir_is_skill_dir
    } {
        puts -nonewline "Running $testMethod... "
        if {[catch {$testObj $testMethod} error]} {
            if {[string match "SKIP:*" $error]} {
                puts [string range $error 5 end]
            } else {
                puts "FAILED: $error"
            }
        } else {
            puts "PASSED"
        }
    }
    
    $testObj destroy
}

# Execute tests
run_tests
