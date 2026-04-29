FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

# Install essentials
RUN apt-get update && apt-get install -y \
    kali-desktop-xfce \
    novnc \
    x11vnc \
    xvfb \
    dbus-x11 \
    && apt-get clean

# Set index.html as default
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Create startup script
RUN echo '#!/bin/bash\n\
# Set the VNC Password securely\n\
mkdir -p ~/.vnc\n\
x11vnc -storepasswd "${VNC_PASSWORD}" ~/.vnc/passwd\n\
\n\
# Start Virtual Framebuffer\n\
Xvfb :0 -screen 0 ${VNC_RESOLUTION}x16 &\n\
sleep 2\n\
\n\
# Start Kali Xfce\n\
DISPLAY=:0 startxfce4 &\n\
sleep 2\n\
\n\
# FIXED: Added -shared for multi-device access and removed caching\n\
x11vnc -display :0 -rfbauth ~/.vnc/passwd -shared -forever -bg -xkb -quiet &\n\
sleep 2\n\
\n\
# Start noVNC proxy\n\
/usr/share/novnc/utils/novnc_proxy --listen 8080 --vnc localhost:5900 --web /usr/share/novnc' > /startup.sh

RUN chmod +x /startup.sh

EXPOSE 8080

CMD ["/startup.sh"]
