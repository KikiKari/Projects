#!/usr/bin/perl
# __init__.py — portiert nach perl5
# Quelle: python, OpenClaw@main:openclaw/__init__.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# from .client import GatewayClient
require Gateway::Client;
our @EXPORT_OK = qw(GatewayClient);

# from .cluster import ClusterManager
require Gateway::Cluster;
push @EXPORT_OK, qw(ClusterManager);

# __version__ = "0.1.0a1"
our $VERSION = "0.1.0a1";

# __all__ = ["GatewayClient", "ClusterManager"]
our @EXPORT = @EXPORT_OK;

1;
