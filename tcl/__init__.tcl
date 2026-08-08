#!/usr/bin/env tclsh
# __init__.py — portiert nach tcl
# Quelle: python, OpenClaw@main:openclaw/__init__.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Tcl does not have a direct equivalent to Python's __init__.py module system.
# However, we can simulate the behavior by creating a package initialization script.

# In Tcl, we typically use 'package provide' to define a package and its version.
# The client and cluster functionality would need to be implemented in separate .tcl files.

# Simulating the imports from .client and .cluster
# These would be implemented in gateway_client.tcl and cluster_manager.tcl respectively
source [file join [file dirname [info script]] gateway_client.tcl]
source [file join [file dirname [info script]] cluster_manager.tcl]

# Define package version
package provide gateway 0.1.0a1

# In Tcl, we don't have __all__ equivalent, but we can create namespace exports
# Assuming GatewayClient and ClusterManager are defined in their respective files
namespace eval ::gateway {
    namespace export GatewayClient ClusterManager
}

# Version information
set ::gateway::version "0.1.0a1"
