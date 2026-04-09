# syntax=docker/dockerfile:1
FROM debian:sid-slim

ARG DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1920x1080

# FIX 1: Added 'qterminal' so you have a command line to program with
RUN apt-get update && apt-get install -y --no-install-recommends \
    lxqt-core \
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

# FIX 2: Added Password Authentication logic to the entrypoint
RUN echo '#!/bin/bash\n\
mkdir -p ~/.vnc\n\
# Sets a default password if you forget to provide one in the compose file\n\
VNC_PASS=${VNC_PASSWORD:-secure1234}\n\
echo "$VNC_PASS" | vncpasswd -f > ~/.vnc/passwd\n\
chmod 600 ~/.vnc/passwd\n\
rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock\n\
# Changed -SecurityTypes None to use the new password file\n\
Xvnc $DISPLAY -geometry $VNC_RESOLUTION -depth 24 -rfbauth ~/.vnc/passwd &\n\
sleep 2\n\
export DISPLAY=$DISPLAY\n\
startlxqt &\n\
websockify --web /usr/share/novnc/ 8080 localhost:5901\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
