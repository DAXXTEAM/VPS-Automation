
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

# Install required packages
RUN apt-get update && apt-get install -y \
    openssh-server \
    ca-certificates \
    curl \
    unzip \
    locales \
    && locale-gen en_US.UTF-8 \
    && useradd -m -s /bin/bash railway \
    && mkdir -p /run/sshd /home/railway/.ssh \
    && chown -R railway:railway /home/railway/.ssh \
    && chmod 700 /home/railway/.ssh \
    && rm -rf /var/lib/apt/lists/*

# Install ngrok
RUN curl -fsSL \
    https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
    -o /tmp/ngrok.zip \
    && unzip /tmp/ngrok.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/ngrok \
    && rm /tmp/ngrok.zip

# Configure SSH
RUN printf '%s\n' \
    'Port 22' \
    'PermitRootLogin no' \
    'PasswordAuthentication yes' \
    'KbdInteractiveAuthentication no' \
    'PubkeyAuthentication yes' \
    'UsePAM yes' \
    'AllowUsers railway' \
    'AuthorizedKeysFile .ssh/authorized_keys' \
    > /etc/ssh/sshd_config

# Copy startup script
COPY start.sh /start.sh

# Fix Windows line endings
RUN sed -i 's/\r$//' /start.sh \
    && chmod 755 /start.sh

EXPOSE 22

CMD ["/bin/bash", "/start.sh"]
