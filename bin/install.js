#!/usr/bin/env node
const { execFileSync } = require('child_process')
const path = require('path')

const subcommand = process.argv[2]
const script =
  subcommand === 'uninstall' ? path.join(__dirname, '..', 'uninstall.sh') :
  subcommand === 'update'    ? path.join(__dirname, '..', 'update.sh') :
                               path.join(__dirname, '..', 'install.sh')

execFileSync('bash', [script], { stdio: 'inherit' })
