#!/bin/sh

# This script can only be run as root
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Enable community repository (required for openbox)
if ! grep -q "^http.*/community$" /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories
    apk update
fi

# Install minimal required packages (following Alpine wiki)
echo "Installing required packages..."
apk add --no-cache xorg-server-xephyr xwininfo dbus-x11 sudo \
    openbox xterm font-terminus \
    onboard ttf-dejavu

# Setup D-Bus (required for openbox)
if ! rc-service dbus status > /dev/null 2>&1; then
    rc-service dbus start
    rc-update add dbus
fi

# Create user 'alpine' if it doesn't exist
if ! id -u alpine >/dev/null 2>&1; then
    adduser -D alpine
    echo "alpine:alpine" | chpasswd
    adduser alpine wheel
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# Add user to required groups for Xorg (from Alpine wiki)
addgroup alpine input 2>/dev/null
addgroup alpine video 2>/dev/null

# Create Openbox config directories
mkdir -p /home/alpine/.config/openbox

# Copy default Openbox configs if they exist and not already present
if [ -d /etc/xdg/openbox ] && [ ! -f /home/alpine/.config/openbox/rc.xml ]; then
    cp -r /etc/xdg/openbox/* /home/alpine/.config/openbox/ 2>/dev/null
fi

# Create a minimal autostart file
cat > /home/alpine/.config/openbox/autostart << 'EOF'
# Start virtual keyboard for touchscreen
onboard &

# Set simple black background (saves resources)
xsetroot -solid black &
EOF

# Create a simple menu.xml if it doesn't exist
if [ ! -f /home/alpine/.config/openbox/menu.xml ]; then
    cat > /home/alpine/.config/openbox/menu.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu>
<menu id="root-menu" label="Menu">
  <item label="Terminal">
    <action name="Execute"><command>xterm</command></action>
  </item>
  <item label="Web Browser">
    <action name="Execute"><command>midori</command></action>
  </item>
  <separator />
  <item label="Reconfigure">
    <action name="Reconfigure" />
  </item>
</menu>
</openbox_menu>
EOF
fi

chown -R alpine:alpine /home/alpine/.config

# Kill existing Xephyr if running
if [ "$(pgrep Xephyr)" ] ; then
    echo "Xephyr is already running. Killing it..."
    kill $(pgrep Xephyr)
    sleep 2
fi

# Get screen geometry and start Xephyr
WINDOW_GEOMETRY=$(xwininfo -root -display :0 | egrep "geometry" | cut -d " " -f4)
DISPLAY=:0 Xephyr :1 -title "L:D_N:application_ID:xephyr" -ac -br -screen $WINDOW_GEOMETRY -cc 4 -reset -terminate &
sleep 3

# Start Openbox session as alpine user
su - alpine -c "
export DISPLAY=:1
export XDG_RUNTIME_DIR=/tmp/runtime-alpine
mkdir -p /tmp/runtime-alpine 2>/dev/null

# Run first-time setup if needed
if [ ! -f /home/alpine/.runonce ]; then
    touch /home/alpine/.runonce
    echo 'First-time setup complete'
fi

exec openbox-session
"

# Cleanup
echo "Killing Xephyr..."
kill $(pgrep Xephyr) 2>/dev/null
sleep 2
