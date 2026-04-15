# syntax=docker/dockerfile:1
FROM debian:sid-slim

ARG DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1920x1080

# THE FIX: Added tigervnc-tools to restore the missing vncpasswd binary
RUN apt-get update && apt-get install -y --no-install-recommends \
    lxqt-core \
    pcmanfm-qt \
    openbox \
    qterminal \
    xvfb \
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    novnc \
    websockify \
    dbus-x11 \
    curl \
    gpg \
    wget \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y --no-install-recommends google-chrome-stable \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /etc/apt/keyrings/antigravity-repo-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | tee /etc/apt/sources.list.d/antigravity.list && \
    apt-get update && apt-get install -y --no-install-recommends antigravity \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN dpkg-divert --add --rename --divert /usr/bin/google-chrome-stable.real /usr/bin/google-chrome-stable && \
    echo '#!/bin/bash\nexec /usr/bin/google-chrome-stable.real --no-sandbox --disable-dev-shm-usage "$@"' > /usr/bin/google-chrome-stable && \
    chmod +x /usr/bin/google-chrome-stable

RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

RUN mkdir -p /root/Desktop && \
    echo "[Desktop Entry]\nVersion=1.0\nName=Google Chrome\nExec=/usr/bin/google-chrome-stable\nIcon=google-chrome\nTerminal=false\nType=Application" > /root/Desktop/Chrome.desktop && \
    echo "[Desktop Entry]\nVersion=1.0\nName=Antigravity\nExec=antigravity\nIcon=system-software-install\nTerminal=false\nType=Application" > /root/Desktop/Antigravity.desktop && \
    echo "[Desktop Entry]\nVersion=1.0\nName=Terminal\nExec=qterminal\nIcon=utilities-terminal\nTerminal=false\nType=Application" > /root/Desktop/Terminal.desktop && \
    chmod +x /root/Desktop/*.desktop

# 7. Clean Entrypoint Script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'export VNC_PASS="${VNC_PASSWORD:-secure1234}"' >> /entrypoint.sh && \
    echo 'echo "$VNC_PASS" | vncpasswd -f > /tmp/vncpasswd' >> /entrypoint.sh && \
    echo 'chmod 600 /tmp/vncpasswd' >> /entrypoint.sh && \
    echo 'rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock' >> /entrypoint.sh && \
    echo 'Xvnc $DISPLAY -geometry $VNC_RESOLUTION -depth 24 -SecurityTypes VncAuth -rfbauth /tmp/vncpasswd &' >> /entrypoint.sh && \
    echo 'sleep 2' >> /entrypoint.sh && \
    echo 'export DISPLAY=$DISPLAY' >> /entrypoint.sh && \
    echo 'startlxqt &' >> /entrypoint.sh && \
    echo 'websockify --web /usr/share/novnc/ 8080 127.0.0.1:5901' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
