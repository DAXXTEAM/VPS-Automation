
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

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

RUN curl -fsSL \
    https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
    -o /tmp/ngrok.zip \
    && unzip /tmp/ngrok.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/ngrok \
    && rm /tmp/ngrok.zip

RUN printf '%s\n' \
    'Port 22' \
    'PermitRootLogin no' \
    'PasswordAuthentication no' \
    'PubkeyAuthentication yes' \
    'AllowUsers railway' \
    > /etc/ssh/sshd_config

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 22

CMD ["/start.sh"]
