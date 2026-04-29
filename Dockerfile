# Use the official Kali Linux base image
FROM kalilinux/kali-rolling

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install desktop environment, noVNC, and X-server dependencies
RUN apt-get update && apt-get install -y \
    kali-desktop-xfce \
    novnc \
    x11vnc \
    xvfb \
    dbus-x11 \
    && apt-get clean

# Create a startup script to launch the services
RUN echo '#!/bin/bash\n\
# 1. Start Virtual Framebuffer (Virtual Display) on :0\n\
Xvfb :0 -screen 0 1024x768x16 &\n\
sleep 2\n\
# 2. Start the Desktop Environment\n\
DISPLAY=:0 startxfce4 &\n\
sleep 2\n\
# 3. Start x11vnc as per article instructions\n\
x11vnc -display :0 -autoport -localhost -nopw -bg -xkb -ncache -ncache_cr -quiet -forever &\n\
sleep 2\n\
# 4. Start noVNC proxy as per article instructions\n\
/usr/share/novnc/utils/novnc_proxy --listen 8081 --vnc localhost:5900' > /startup.sh

RUN chmod +x /startup.sh

# Expose the noVNC port
EXPOSE 8081

CMD ["/startup.sh"]
