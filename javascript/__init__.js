#!/usr/bin/env node
// __init__.py — portiert nach javascript
// Quelle: python, OpenClaw@main:openclaw/__init__.py
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

const { GatewayClient } = require('./client');
const { ClusterManager } = require('./cluster');

const __version__ = "0.1.0a1";

module.exports = {
  GatewayClient,
  ClusterManager,
  __version__
};
