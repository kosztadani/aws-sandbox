#!/usr/bin/env bash

set -euo pipefail

function main() {
  if [[ ${#} -ne 2 ]]; then
    print_help_and_exit
  fi
  local instanceId="${1}"
  local username="${2}"
  local publicKey
  publicKey="$(get_ssh_public_key)"
  aws ec2-instance-connect send-ssh-public-key \
    --instance-id "${instanceId}" \
    --instance-os-user "${username}" \
    --ssh-public-key "${publicKey}"
  exec aws ec2-instance-connect open-tunnel \
    --instance-id "${instanceId}"
}

function print_help_and_exit() {
  >&2 echo "Usage: aws-ssh-proxy-command.sh <instance-id> <username>"
  >&2 echo ""
  >&2 echo "This command is intended to be used with ssh's \"ProxyCommand\" option."
  >&2 echo ""
  >&2 echo "Example: \"ProxyCommand %h %r\""
  exit 1
}

function get_ssh_public_key() {
  ssh-add -L | head -n 1
}

main "${@}"
