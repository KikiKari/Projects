#!/usr/bin/perl
# __init__.py — portiert nach perl5
# Quelle: python, Projects@MCP-Server-Monitor:mcpmon/__init__.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# MCP-Server-Monitor — Zustand fremder MCP-Server feststellen.
#
# Nur Standardbibliothek. Kein pip, kein Framework, keine Pflicht-Zugangsdaten.

our $VERSION = "0.1.0";

# In Perl gibt es kein direktes Äquivalent zu __all__, aber wir können
# die zu exportierenden Module hier deklarieren
our @EXPORT_OK = qw(discovery state config report);

1; # Perl-Module müssen mit einer wahren Zahl enden
