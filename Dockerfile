FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

# Install the standard Kali Xfce desktop environment and noVNC tools
RUN apt-get update && apt-get install -y \
    kali-desktop-xfce \
    novnc \
    x11vnc \
    xvfb \
    dbus-x11 \
    && apt-get clean

# Create the startup script to initialize the display and VNC
RUN echo '#!/bin/bash\n\
# Set VNC Password\n\
mkdir -p ~/.vnc\n\
x11vnc -storepasswd ${VNC_PASSWORD} ~/.vnc/passwd\n\
\n\
# Start Virtual Framebuffer with your requested resolution\n\
Xvfb :0 -screen 0 ${VNC_RESOLUTION}x16 &\n\
sleep 2\n\
\n\
# Start the standard Kali Xfce desktop\n\
DISPLAY=:0 startxfce4 &\n\
sleep 2\n\
\n\
# Start x11vnc using the password file\n\
x11vnc -display :0 -rfbauth ~/.vnc/passwd -autoport -localhost -bg -xkb -ncache -ncache_cr -quiet -forever &\n\
sleep 2\n\
\n\
# Start noVNC proxy on 8080 (matching your compose port)\n\
/usr/share/novnc/utils/novnc_proxy --listen 8080 --vnc localhost:5900' > /startup.sh

RUN chmod +x /startup.sh

EXPOSE 8080

CMD ["/startup.sh"]
