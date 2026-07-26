#!/usr/bin/env node
const { execFileSync } = require('child_process')
const path = require('path')
const script = path.join(__dirname, '..', 'uninstall.sh')
execFileSync('bash', [script], { stdio: 'inherit' })
