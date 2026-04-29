FROM docker.io/kalilinux/kali-rolling:latest

# Suppress interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Essential Desktop & VNC setup
RUN apt-get update && apt-get install -y --no-install-recommends \
    kali-linux-core \
    lxqt-core \
    pcmanfm-qt \
    openbox \
    qterminal \
    xvfb \
    tigervnc-standalone-server \
    novnc \
    websockify \
    curl \
    ca-certificates \
    dbus-x11 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Environment for VNC
ENV USER=root
ENV HOME=/root
WORKDIR /root

EXPOSE 8080

# Start VNC and noVNC
CMD ["/bin/bash", "-c", "vncserver :1 -securitytypes none -geometry 1280x720 && websockify --web /usr/share/novnc/ 8080 localhost:5901"]
