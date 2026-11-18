
#!/bin/bash
set -e

echo "================================"
echo "Starting Railway SSH VPS"
echo "================================"

# Check required environment variables
if [ -z "$NGROK_TOKEN" ]; then
    echo "ERROR: NGROK_TOKEN is missing"
    exit 1
fi

if [ -z "$SSH_PASSWORD" ]; then
    echo "ERROR: SSH_PASSWORD is missing"
    exit 1
fi

# Set railway user password
printf 'railway:%s\n' "$SSH_PASSWORD" | chpasswd

# Optional SSH public key authentication
if [ -n "$SSH_PUBLIC_KEY" ]; then
    mkdir -p /home/railway/.ssh

    printf '%s\n' "$SSH_PUBLIC_KEY" \
        > /home/railway/.ssh/authorized_keys

    chown -R railway:railway /home/railway/.ssh
    chmod 700 /home/railway/.ssh
    chmod 600 /home/railway/.ssh/authorized_keys

    echo "SSH public key authentication enabled."
fi

# Generate SSH host keys
ssh-keygen -A

# Validate SSH configuration
/usr/sbin/sshd -t

# Configure ngrok authentication
ngrok config add-authtoken "$NGROK_TOKEN"

# Start SSH server
/usr/sbin/sshd

echo "================================"
echo "SSH server started successfully"
echo "Username: railway"
echo "Password authentication enabled"
echo "================================"

# Start ngrok TCP tunnel
echo "Starting ngrok TCP tunnel..."

exec ngrok tcp 22 --log=stdout
