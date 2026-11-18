
#!/bin/bash
set -e

echo "================================"
echo "Starting Railway SSH VPS"
echo "================================"

if [ -z "$NGROK_TOKEN" ]; then
    echo "ERROR: NGROK_TOKEN is missing"
    exit 1
fi

if [ -z "$SSH_PUBLIC_KEY" ]; then
    echo "ERROR: SSH_PUBLIC_KEY is missing"
    exit 1
fi

mkdir -p /home/railway/.ssh

printf '%s\n' "$SSH_PUBLIC_KEY" > /home/railway/.ssh/authorized_keys

chown -R railway:railway /home/railway/.ssh
chmod 700 /home/railway/.ssh
chmod 600 /home/railway/.ssh/authorized_keys

ssh-keygen -A

ngrok config add-authtoken "$NGROK_TOKEN"

/usr/sbin/sshd

echo "SSH server started successfully."
echo "Starting ngrok TCP tunnel..."

exec ngrok tcp 22 --log=stdout
