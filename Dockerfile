# Use a stable Kali base
FROM kalilinux/kali-rolling:latest

# Prevent prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install only the essentials for the Desktop Environment
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
    fonts-liberation \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up the VNC server environment
ENV USER=root
ENV HOME=/root
WORKDIR /root

# Expose the noVNC port
EXPOSE 8080

# Start script (ensure your repo has a script to launch Xvfb and noVNC)
CMD ["/bin/bash", "-c", "vncserver :1 -securitytypes none && websockify --web /usr/share/novnc/ 8080 localhost:5901"]
