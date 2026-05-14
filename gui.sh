#!/bin/sh

# This script can only be run as root
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Install required packages if they are not already installed
if [ -z "$(which Xephyr)" ] || [ -z "$(which xwininfo)" ]; then
    echo "Installing required packages..."
    apk add --no-cache xorg-server-xephyr xwininfo onboard dbus-x11 sudo openbox obconf lxterminal tint2 spacefm xset xrandr feh font-dejavu
fi

# Create a new user 'alpine' if it doesn't already exist
if ! id -u alpine >/dev/null 2>&1; then
    adduser -D alpine
    echo "alpine:alpine" | chpasswd
    adduser alpine wheel
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# Create Openbox configuration for the alpine user
if [ ! -d /home/alpine/.config/openbox ]; then
    mkdir -p /home/alpine/.config/openbox
    # Copiar configuración por defecto
    cp /etc/xdg/openbox/rc.xml /home/alpine/.config/openbox/
    cp /etc/xdg/openbox/menu.xml /home/alpine/.config/openbox/
    cp /etc/xdg/openbox/autostart /home/alpine/.config/openbox/
    
    # Configurar autostart para aplicaciones útiles
    cat > /home/alpine/.config/openbox/autostart << 'EOF'
# Panel tint2
tint2 &

# Gestor de archivos
spacefm --daemon &

# Configurar fondo negro por defecto (más eficiente)
xsetroot -solid black &

# Teclado virtual para la pantalla táctil
onboard &
EOF
    
    chown -R alpine:alpine /home/alpine/.config/openbox
fi

# Make dang sure Xephyr isn't already running
if [ "$(pgrep Xephyr)" ] ; then
    echo "Xephyr is already running. Killing it..."
    kill $(pgrep Xephyr)
    sleep 2
fi

WINDOW_GEOMETRY=$(xwininfo -root -display :0 | egrep "geometry" | cut -d " "  -f4)
DISPLAY=:0 Xephyr :1 -title "L:D_N:application_ID:xephyr" -ac -br -screen $WINDOW_GEOMETRY -cc 4 -reset -terminate &
sleep 2

# Drop into the Alpine user session
su - alpine -c "
export DISPLAY=:1

# Run first-time setup if needed
if [ ! -f /home/alpine/.runonce ]; then
    echo 'Running first-time setup...'
    touch /home/alpine/.runonce
    
    # Configurar resolución para mejor visualización en Kindle
    xrandr -s ${WINDOW_GEOMETRY}
    
    sleep 2
fi

# Start Openbox session
dbus-run-session openbox-session
" > /dev/null 2>&1

# Cleanup:
echo "Killing Xephyr..."
kill $(pgrep Xephyr)
sleep 2