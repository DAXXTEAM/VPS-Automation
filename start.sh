#!/bin/bash
set -Eeuo pipefail

printf '%s\n' '================================' 'Starting Railway SSH VPS' '================================'

# This entrypoint must run as root so it can set the account password
# and start the OpenSSH daemon.
if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: start.sh must run as root. Remove any USER railway directive from the Dockerfile."
    exit 1
fi

: "${NGROK_TOKEN:?ERROR: NGROK_TOKEN is missing}"
: "${SSH_PASSWORD:?ERROR: SSH_PASSWORD is missing}"

# Set the SSH password for the railway account.
printf 'railway:%s\n' "$SSH_PASSWORD" | chpasswd

# Optional SSH public-key authentication.
if [[ -n "${SSH_PUBLIC_KEY:-}" ]]; then
    install -d -o railway -g railway -m 0700 /home/railway/.ssh
    printf '%s\n' "$SSH_PUBLIC_KEY" > /home/railway/.ssh/authorized_keys
    chown railway:railway /home/railway/.ssh/authorized_keys
    chmod 0600 /home/railway/.ssh/authorized_keys
    echo "SSH public key authentication enabled."
fi

# Confirm sudo access is configured for the SSH user.
if ! visudo -c >/dev/null; then
    echo "ERROR: sudoers configuration is invalid."
    exit 1
fi

ssh-keygen -A
/usr/sbin/sshd -t

ngrok config add-authtoken "$NGROK_TOKEN"
/usr/sbin/sshd

printf '%s\n' \
    '================================' \
    'SSH server started successfully' \
    'Username: railway' \
    'Password authentication enabled' \
    '================================'

exec ngrok tcp 22 --log=stdout
