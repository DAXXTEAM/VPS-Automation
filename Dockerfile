FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV DENO_INSTALL=/usr/local
ENV PATH="/usr/local/go/bin:/usr/local/bin:${PATH}"

# The Railway container must start as root so start.sh can set the SSH
# password and start sshd. SSH sessions themselves use the unprivileged
# railway account, which receives sudo access through sudoers below.
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    ca-certificates \
    curl \
    wget \
    unzip \
    git \
    sudo \
    build-essential \
    pkg-config \
    ffmpeg \
    python3 \
    locales \
    && locale-gen en_US.UTF-8 \
    && useradd -m -s /bin/bash railway \
    && printf '%s\n' 'railway ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/railway \
    && chmod 0440 /etc/sudoers.d/railway \
    && visudo -cf /etc/sudoers.d/railway \
    && mkdir -p /run/sshd /home/railway/.ssh \
    && chown -R railway:railway /home/railway/.ssh \
    && chmod 0700 /home/railway/.ssh \
    && rm -rf /var/lib/apt/lists/*

# Install the latest Go release (>= 1.26) for linux/amd64, and verify the
# downloaded archive against the checksum published on go.dev.
ARG GO_VERSION=1.27.4
ARG GO_SHA256=7226736c2339719cda28fbf3a54d71aa63bcefe376e98cef00034268dab24840
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz \
    && echo "${GO_SHA256}  /tmp/go.tar.gz" | sha256sum -c - \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm -f /tmp/go.tar.gz

# Install yt-dlp's official Linux-compatible zipapp release. python3 is
# installed above because this release uses Python on Linux.
RUN curl -fL "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" \
    -o /usr/local/bin/yt-dlp \
    && chmod 0755 /usr/local/bin/yt-dlp

# Install Deno system-wide so it is available to the railway SSH user too.
RUN curl -fsSL https://deno.land/install.sh -o /tmp/deno-install.sh \
    && sh /tmp/deno-install.sh \
    && rm -f /tmp/deno-install.sh \
    && test -x /usr/local/bin/deno

# Install ngrok (same v3 Linux amd64 package used by the original project).
RUN curl -fsSL \
    https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip \
    -o /tmp/ngrok.zip \
    && unzip /tmp/ngrok.zip -d /usr/local/bin \
    && chmod 0755 /usr/local/bin/ngrok \
    && rm -f /tmp/ngrok.zip

# Configure SSH while retaining the original project's railway login.
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

COPY start.sh /start.sh
RUN sed -i 's/\r$//' /start.sh && chmod 0755 /start.sh

EXPOSE 22

# Do not add USER railway here: start.sh needs root to initialize sshd.
CMD ["/bin/bash", "/start.sh"]
