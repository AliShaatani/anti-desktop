# syntax=docker/dockerfile:1
# Using sid-slim to guarantee access to the latest LXQt 2.3.0 packages
FROM debian:sid-slim

# Avoid interactive prompts during apt-get
ARG DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1920x1080

# Step 1: Install core essentials ONLY. 
# --no-install-recommends is crucial here to keep the image size Alpine-like.
RUN apt-get update && apt-get install -y --no-install-recommends \
    lxqt-core \
    openbox \
    xvfb \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    websockify \
    curl \
    gpg \
    wget \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Step 2: Install Google Chrome (relies on glibc, satisfying the Debian requirement)
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y --no-install-recommends google-chrome-stable \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Step 3: Install Antigravity (using your specified Debian repo)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /etc/apt/keyrings/antigravity-repo-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | tee /etc/apt/sources.list.d/antigravity.list && \
    apt-get update && apt-get install -y --no-install-recommends antigravity \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Step 4: Patch Chrome to run safely inside a container
RUN dpkg-divert --add --rename --divert /usr/bin/google-chrome-stable.real /usr/bin/google-chrome-stable && \
    echo '#!/bin/bash\nexec /usr/bin/google-chrome-stable.real --no-sandbox --disable-dev-shm-usage "$@"' > /usr/bin/google-chrome-stable && \
    chmod +x /usr/bin/google-chrome-stable

# Step 5: Minimal entrypoint logic
RUN echo '#!/bin/bash\n\
rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock\n\
Xvnc $DISPLAY -geometry $VNC_RESOLUTION -depth 24 -SecurityTypes None &\n\
sleep 2\n\
export DISPLAY=$DISPLAY\n\
startlxqt &\n\
websockify --web /usr/share/novnc/ 8080 localhost:5900\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
