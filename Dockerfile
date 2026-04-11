# syntax=docker/dockerfile:1
FROM debian:sid-slim

ARG DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1920x1080

# 1. Install core desktop, terminal, and engines
RUN apt-get update && apt-get install -y --no-install-recommends \
    lxqt-core \
    pcmanfm-qt \
    openbox \
    qterminal \
    xvfb \
    tigervnc-standalone-server \
    tigervnc-common \
    novnc \
    websockify \
    dbus-x11 \
    curl \
    gpg \
    wget \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Install Google Chrome
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y --no-install-recommends google-chrome-stable \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Install Antigravity
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /etc/apt/keyrings/antigravity-repo-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | tee /etc/apt/sources.list.d/antigravity.list && \
    apt-get update && apt-get install -y --no-install-recommends antigravity \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. Patch Chrome for Docker
RUN dpkg-divert --add --rename --divert /usr/bin/google-chrome-stable.real /usr/bin/google-chrome-stable && \
    echo '#!/bin/bash\nexec /usr/bin/google-chrome-stable.real --no-sandbox --disable-dev-shm-usage "$@"' > /usr/bin/google-chrome-stable && \
    chmod +x /usr/bin/google-chrome-stable

# 5. Block the insecure directory listing
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# 6. THE MAGIC: Bake the shortcut icons directly into the root desktop
RUN mkdir -p /root/Desktop && \
    echo "[Desktop Entry]\nVersion=1.0\nName=Google Chrome\nExec=/usr/bin/google-chrome-stable\nIcon=google-chrome\nTerminal=false\nType=Application" > /root/Desktop/Chrome.desktop && \
    echo "[Desktop Entry]\nVersion=1.0\nName=Antigravity\nExec=antigravity\nIcon=system-software-install\nTerminal=false\nType=Application" > /root/Desktop/Antigravity.desktop && \
    echo "[Desktop Entry]\nVersion=1.0\nName=Terminal\nExec=qterminal\nIcon=utilities-terminal\nTerminal=false\nType=Application" > /root/Desktop/Terminal.desktop && \
    chmod +x /root/Desktop/*.desktop

# 7. Clean Entrypoint Script
RUN echo '#!/bin/bash\n\
mkdir -p /root/.vnc\n\
VNC_PASS=${VNC_PASSWORD:-secure1234}\n\
echo "$VNC_PASS" | vncpasswd -f > /root/.vnc/passwd\n\
chmod 600 /root/.vnc/passwd\n\
rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock\n\
# FIX: Use the strict -rfbauth parameter required by the raw Xvnc binary\n\
Xvnc $DISPLAY -geometry $VNC_RESOLUTION -depth 24 -SecurityTypes VncAuth -rfbauth /root/.vnc/passwd &\n\
sleep 2\n\
export DISPLAY=$DISPLAY\n\
startlxqt &\n\
websockify --web /usr/share/novnc/ 8080 127.0.0.1:5901\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
