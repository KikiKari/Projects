#!/usr/bin/env tclsh8.6
# system_manager.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/system_manager.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/system_manager.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# System management abstraction for Ubuntu and CentOS 8.
# Provides command matrix for packages, services, networking.

# Define SystemCommand structure
proc create_system_command {ubuntu centos description} {
    return [list ubuntu $ubuntu centos $centos description $description]
}

# SystemManager class equivalent
namespace eval SystemManager {
    # COMMANDS array
    variable COMMANDS
    array set COMMANDS {
        install     {ubuntu "apt-get install -y %package%" centos "dnf install -y %package%" description "Install a package"}
        remove      {ubuntu "apt-get remove -y %package%" centos "dnf remove -y %package%" description "Remove a package"}
        update      {ubuntu "apt-get update && apt-get upgrade -y" centos "dnf update -y" description "Update all packages"}
        search      {ubuntu "apt-cache search %package%" centos "dnf search %package%" description "Search for package"}
        service_start   {ubuntu "systemctl start %service%" centos "systemctl start %service%" description "Start a service"}
        service_stop    {ubuntu "systemctl stop %service%" centos "systemctl stop %service%" description "Stop a service"}
        service_enable  {ubuntu "systemctl enable %service%" centos "systemctl enable %service%" description "Enable service at boot"}
        service_status  {ubuntu "systemctl status %service%" centos "systemctl status %service%" description "Check service status"}
        firewall_allow  {ubuntu "ufw allow %port%/%proto%" centos "firewall-cmd --add-port=%port%/%proto% --permanent && firewall-cmd --reload" description "Open firewall port"}
        firewall_status {ubuntu "ufw status" centos "firewall-cmd --list-all" description "Check firewall status"}
        add_user        {ubuntu "adduser --disabled-password --gecos '' %username%" centos "adduser %username%" description "Add system user"}
        add_to_sudo     {ubuntu "usermod -aG sudo %username%" centos "usermod -aG wheel %username%" description "Add user to sudoers"}
    }
    
    # PACKAGE_MAP array
    variable PACKAGE_MAP
    array set PACKAGE_MAP {
        apache,ubuntu   apache2
        apache,centos   httpd
        mysql,ubuntu    mysql-server
        mysql,centos    mysql-server
        php,ubuntu      php
        php,centos      php
        nodejs,ubuntu   nodejs
        nodejs,centos   nodejs
        nginx,ubuntu    nginx
        nginx,centos    nginx
    }
}

# Constructor for SystemManager
proc SystemManager::new {os_type} {
    set os [string tolower $os_type]
    if {$os ni {"ubuntu" "centos"}} {
        error "Unsupported OS: $os_type"
    }
    return $os
}

# Get the command for an action
proc SystemManager::get_command {os action kwargs} {
    variable COMMANDS
    
    if {![info exists COMMANDS($action)]} {
        error "Unknown action: $action"
    }
    
    array set cmd_template $COMMANDS($action)
    
    # Get OS-specific command
    if {$os eq "ubuntu"} {
        set cmd $cmd_template(ubuntu)
    } else {
        set cmd $cmd_template(centos)
    }
    
    # Format with arguments
    foreach {key value} $kwargs {
        set cmd [string map [list "%$key%" $value] $cmd]
    }
    
    return $cmd
}

# Get correct package name for OS
proc SystemManager::get_package_name {os software} {
    variable PACKAGE_MAP
    
    set key "$software,$os"
    if {[info exists PACKAGE_MAP($key)]} {
        return $PACKAGE_MAP($key)
    } else {
        return $software
    }
}

# Auto-detect OS type
proc SystemManager::detect_os {} {
    if {[catch {open "/etc/os-release" r} fid]} {
        return ""
    }
    
    set content [read $fid]
    close $fid
    
    set content [string tolower $content]
    if {[string match "*ubuntu*" $content] || [string match "*debian*" $content]} {
        return "ubuntu"
    } elseif {[string match "*centos*" $content] || [string match "*rhel*" $content] || [string match "*fedora*" $content]} {
        return "centos"
    } else {
        return ""
    }
}

# Generate a shell script for multiple actions
proc SystemManager::generate_script {os actions} {
    variable COMMANDS
    
    set lines [list "#!/bin/bash" "set -e" ""]
    
    foreach action_dict $actions {
        # Extract action and remove it from dict
        set action ""
        set kwargs [dict create]
        dict for {key value} $action_dict {
            if {$key eq "action"} {
                set action $value
            } else {
                dict set kwargs $key $value
            }
        }
        
        lappend lines "# [dict get $COMMANDS($action) description]"
        lappend lines [get_command $os $action $kwargs]
        lappend lines ""
    }
    
    return [join $lines "\n"]
}

# Main procedure
proc main {} {
    global argv
    
    # Simple argument parsing since Tcl doesn't have argparse equivalent
    set args [parse_args $argv]
    
    if {![dict exists $args --os] || ![dict exists $args --action]} {
        puts stderr "Usage: $::argv0 --os <ubuntu|centos> --action <action> \[options\]"
        exit 1
    }
    
    set os [dict get $args --os]
    set action [dict get $args --action]
    set generate [dict get $args --generate]
    
    # Initialize manager
    if {[catch {SystemManager::new $os} manager]} {
        puts stderr $manager
        exit 1
    }
    
    # Build kwargs from args
    set kwargs [dict create]
    if {[dict exists $args --package]} {
        set package [SystemManager::get_package_name $os [dict get $args --package]]
        dict set kwargs package $package
    }
    if {[dict exists $args --service]} {
        dict set kwargs service [dict get $args --service]
    }
    if {[dict exists $args --port]} {
        dict set kwargs port [dict get $args --port]
        dict set kwargs proto [dict get $args --proto]
    }
    if {[dict exists $args --username]} {
        dict set kwargs username [dict get $args --username]
    }
    
    if {[catch {SystemManager::get_command $os $action $kwargs} cmd]} {
        puts stderr $cmd
        exit 1
    }
    
    if {$generate} {
        puts $cmd
    } else {
        puts "Executing: $cmd"
        # exec /bin/sh -c $cmd  ;# Uncomment to actually execute
    }
}

# Simple argument parser
proc parse_args {argv} {
    set result [dict create --generate false --proto tcp]
    
    for {set i 0} {$i < [llength $argv]} {incr i} {
        set arg [lindex $argv $i]
        switch -exact -- $arg {
            --os - --action - --package - --service - --port - --proto - --username {
                incr i
                if {$i >= [llength $argv]} {
                    error "Missing value for $arg"
                }
                dict set result $arg [lindex $argv $i]
            }
            --generate {
                dict set result $arg true
            }
            default {
                error "Unknown argument: $arg"
            }
        }
    }
    
    return $result
}

# Run main if script is executed directly
if {[info script] eq $::argv0} {
    main
}
