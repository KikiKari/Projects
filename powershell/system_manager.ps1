#!/usr/bin/env pwsh
# system_manager.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/system_manager.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/system_manager.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
System management abstraction for Ubuntu and CentOS 8.
Provides command matrix for packages, services, networking.
#>

class SystemCommand {
    [string]$Ubuntu
    [string]$Centos
    [string]$Description

    SystemCommand([string]$ubuntu, [string]$centos, [string]$description) {
        $this.Ubuntu = $ubuntu
        $this.Centos = $centos
        $this.Description = $description
    }
}

class SystemManager {
    <#
    .SYNOPSIS
    Ubuntu vs CentOS 8 command matrix.
    #>
    
    [hashtable]$COMMANDS
    [hashtable]$PACKAGE_MAP
    [string]$OS

    SystemManager([string]$osType) {
        $this.OS = $osType.ToLower()
        if ($this.OS -notin @("ubuntu", "centos")) {
            throw "Unsupported OS: $osType"
        }

        $this.COMMANDS = @{
            "install" = [SystemCommand]::new(
                "apt-get install -y {package}",
                "dnf install -y {package}",
                "Install a package"
            )
            "remove" = [SystemCommand]::new(
                "apt-get remove -y {package}",
                "dnf remove -y {package}",
                "Remove a package"
            )
            "update" = [SystemCommand]::new(
                "apt-get update && apt-get upgrade -y",
                "dnf update -y",
                "Update all packages"
            )
            "search" = [SystemCommand]::new(
                "apt-cache search {package}",
                "dnf search {package}",
                "Search for package"
            )
            "service_start" = [SystemCommand]::new(
                "systemctl start {service}",
                "systemctl start {service}",
                "Start a service"
            )
            "service_stop" = [SystemCommand]::new(
                "systemctl stop {service}",
                "systemctl stop {service}",
                "Stop a service"
            )
            "service_enable" = [SystemCommand]::new(
                "systemctl enable {service}",
                "systemctl enable {service}",
                "Enable service at boot"
            )
            "service_status" = [SystemCommand]::new(
                "systemctl status {service}",
                "systemctl status {service}",
                "Check service status"
            )
            "firewall_allow" = [SystemCommand]::new(
                "ufw allow {port}/{proto}",
                "firewall-cmd --add-port={port}/{proto} --permanent && firewall-cmd --reload",
                "Open firewall port"
            )
            "firewall_status" = [SystemCommand]::new(
                "ufw status",
                "firewall-cmd --list-all",
                "Check firewall status"
            )
            "add_user" = [SystemCommand]::new(
                "adduser --disabled-password --gecos '' {username}",
                "adduser {username}",
                "Add system user"
            )
            "add_to_sudo" = [SystemCommand]::new(
                "usermod -aG sudo {username}",
                "usermod -aG wheel {username}",
                "Add user to sudoers"
            )
        }

        $this.PACKAGE_MAP = @{
            "apache" = @{ "ubuntu" = "apache2"; "centos" = "httpd" }
            "mysql" = @{ "ubuntu" = "mysql-server"; "centos" = "mysql-server" }
            "php" = @{ "ubuntu" = "php"; "centos" = "php" }
            "nodejs" = @{ "ubuntu" = "nodejs"; "centos" = "nodejs" }
            "nginx" = @{ "ubuntu" = "nginx"; "centos" = "nginx" }
        }
    }

    [string] GetCommand([string]$action, [hashtable]$parameters) {
        <#
        .SYNOPSIS
        Get the command for an action.
        #>
        $cmdTemplate = $this.COMMANDS[$action]
        if (-not $cmdTemplate) {
            throw "Unknown action: $action"
        }

        # Get OS-specific command
        $cmd = ""
        if ($this.OS -eq "ubuntu") {
            $cmd = $cmdTemplate.Ubuntu
        } else {
            $cmd = $cmdTemplate.Centos
        }

        # Format with parameters
        foreach ($key in $parameters.Keys) {
            $cmd = $cmd.Replace("{$key}", $parameters[$key])
        }

        return $cmd
    }

    [string] GetPackageName([string]$software) {
        <#
        .SYNOPSIS
        Get correct package name for OS.
        #>
        $mapping = $this.PACKAGE_MAP[$software.ToLower()]
        if ($mapping) {
            return $mapping[$this.OS]
        }
        return $software
    }

    [string] DetectOS() {
        <#
        .SYNOPSIS
        Auto-detect OS type.
        #>
        try {
            $content = Get-Content "/etc/os-release" -Raw
            $contentLower = $content.ToLower()
            if ($contentLower.Contains("ubuntu") -or $contentLower.Contains("debian")) {
                return "ubuntu"
            } elseif ($contentLower.Contains("centos") -or $contentLower.Contains("rhel") -or $contentLower.Contains("fedora")) {
                return "centos"
            }
        } catch {
            # Ignore error, return null below
        }
        return $null
    }

    [string] GenerateScript([array]$actions) {
        <#
        .SYNOPSIS
        Generate a shell script for multiple actions.
        #>
        $lines = @("#!/bin/bash", "set -e", "")

        foreach ($action in $actions) {
            $cmdName = $action.action
            $action.Remove("action")
            
            $lines += "# $($this.COMMANDS[$cmdName].Description)"
            
            $params = @{}
            foreach ($key in $action.Keys) {
                $params[$key] = $action[$key]
            }
            
            $lines += $this.GetCommand($cmdName, $params)
            $lines += ""
        }

        return ($lines -join "`n")
    }
}

function Main {
    param()

    $parser = [System.Management.Automation.CommandMetaData]::new((Get-Command Write-Host))
    
    # Manual argument parsing since we can't use argparse in PowerShell
    $argsHash = @{}
    for ($i = 0; $i -lt $args.Count; $i++) {
        $arg = $args[$i]
        if ($arg.StartsWith("--")) {
            $key = $arg.Substring(2)
            if ($i + 1 -lt $args.Count -and -not $args[$i+1].StartsWith("--")) {
                $argsHash[$key] = $args[++$i]
            } else {
                $argsHash[$key] = $true
            }
        }
    }

    if (-not $argsHash.ContainsKey("os") -or -not $argsHash.ContainsKey("action")) {
        Write-Host "Missing required arguments: --os and --action"
        return
    }

    $manager = [SystemManager]::new($argsHash.os)

    # Build parameters from args
    $parameters = @{}
    if ($argsHash.ContainsKey("package")) {
        $parameters["package"] = $manager.GetPackageName($argsHash.package)
    }
    if ($argsHash.ContainsKey("service")) {
        $parameters["service"] = $argsHash.service
    }
    if ($argsHash.ContainsKey("port")) {
        $parameters["port"] = $argsHash.port
        $parameters["proto"] = if ($argsHash.ContainsKey("proto")) { $argsHash.proto } else { "tcp" }
    }
    if ($argsHash.ContainsKey("username")) {
        $parameters["username"] = $argsHash.username
    }

    $cmd = $manager.GetCommand($argsHash.action, $parameters)

    if ($argsHash.ContainsKey("generate")) {
        Write-Host $cmd
    } else {
        Write-Host "Executing: $cmd"
        # Invoke-Expression $cmd  # Uncomment to actually execute
    }
}

Main
