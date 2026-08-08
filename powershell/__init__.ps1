# __init__.py — portiert nach powershell
# Quelle: python, OpenClaw@main:openclaw/__init__.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# __init__.py
# PowerShell 7 does not have a direct equivalent to Python's __init__.py
# This file is typically used in Python packages to define what gets imported
# when someone does 'from package import *'

# In PowerShell, we would typically use a module manifest (.psd1) file
# or simply dot-source the required files

# Define version
$script:__version__ = "0.1.0a1"

# In PowerShell, we don't have __all__ equivalent, but we can control exports
# by explicitly exporting functions, aliases, and variables

# Load required modules/components
# Note: PowerShell uses different file structure and loading mechanism
# We would typically have .psm1 files for modules

# Since PowerShell doesn't support relative imports like Python,
# we need to adjust the paths accordingly
# This would depend on the actual file structure

# Export the main classes/functions
# In PowerShell, we would export functions rather than classes
# Classes in PowerShell are defined differently

Export-ModuleMember -Variable @('__version__')
