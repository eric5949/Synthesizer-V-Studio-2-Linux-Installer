#!/bin/bash
echo "Starting Synthesizer V Studio 2 Pro Linux Installer.  For VST support, wine 9.21 staging is recommended."

# Checking if everything we need is installed
if ! [ -x "$(command -v wine)" ]; then
  echo 'Error: Wine is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v winetricks)" ]; then
  echo 'Error: Winetricks is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v yabridgectl)" ]; then
  echo 'Error: Yabridgectl is not installed, vst support wont work.' >&2
fi
echo 'Passed dependency checks'

# Lets set the wineprefix path
read -p "Please enter the location you would like to install Synthesizer V Studio (default ~/synth-v2/): " wineprefix_path
wineprefix_path=${wineprefix_path:-~/synth-v2/}
wineprefix_path="${wineprefix_path/#\~/$HOME}"
echo "Install path: $wineprefix_path"
mkdir -p "$wineprefix_path"
if [ ! -d "$wineprefix_path" ]; then
    echo "Error: Could not create $wineprefix_path." >&2
    exit 1
fi


# Download Edge Webview and SV2
curl -L -o MicrosoftEdgeWebview2Setup.exe https://go.microsoft.com/fwlink/p/?LinkId=2124703
curl -L -o svstudio2-pro-setup-latest.exe https://download.dreamtonics.com/svstudio2/svstudio2-pro-setup-latest.exe

# Install Synthesizer V Studio 2 Pro
WINEPREFIX="$wineprefix_path" wineboot > /dev/null 2>&1 | echo "Wineboot Complete"
WINEPREFIX="$wineprefix_path" winetricks dxvk > /dev/null 2>&1 | echo "DXVK Installed"
WINEPREFIX="$wineprefix_path" winetricks -q win10 > /dev/null 2>&1 | echo "Changed to Windows 10"
WINEPREFIX="$wineprefix_path" wine MicrosoftEdgeWebview2Setup.exe >/dev/null 2>&1 | echo "Edge Webview Installing..."
WINEPREFIX="$wineprefix_path" wine svstudio2-pro-setup-latest.exe > /dev/null 2>&1 | echo "SV2 Installing..."
WINEPREFIX="$wineprefix_path" wineserver -k > /dev/null 2>&1 | echo "Wine Server Stopped"
WINEPREFIX="$wineprefix_path" winetricks -q win7 > /dev/null 2>&1 | echo "Changed to Windows 7"
echo ""
echo "Writing Login Script at ${wineprefix_path}/synth_v_login.sh"
echo ""
cat > $wineprefix_path/synth_v_login.sh <<EOF
#!/bin/bash
WINEPREFIX=$wineprefix_path wine "C:\\Program Files\\Synthesizer V Studio 2 Pro\\synthv-studio.exe" "\$1"
EOF

chmod +x $wineprefix_path/synth_v_login.sh
echo "Writing Desktop Entry..."
cat > ~/.local/share/applications/synthv.desktop <<EOF
[Desktop Entry]
Name=Synthesizer V Studio 2 Pro
Exec=$wineprefix_path/synth_v_login.sh %f
Icon=$wineprefix_path/drive_c/sv-studio-icon.png
MimeType=x-scheme-handler/dreamtonics-svstudio2;
Type=Application
Categories=AudioVideo;
EOF

# Converting VST for Linux
yabridgectl add $wineprefix_path/drive_c/Program\ Files/Common\ Files/VST3/ > /dev/null 2>&1 | echo "Converting VST for Linux..."
yabridgectl sync > /dev/null 2>&1

echo ""
echo "Trickiest part, you should have a working installation right now, when you click log in, your browser will ask you what application to open the link with.  A script called synth_v_login.sh has been created in your wineprefix, tell your browser to use this script."
sleep 5
echo ""
echo "Launching Synthesizer V Studio 2 Pro..."
WINEPREFIX="$wineprefix_path" wine "C:\Program Files\Synthesizer V Studio 2 Pro\synthv-studio.exe" > /dev/null 2>&1

echo ""
echo "Completed, you may use Synthesizer V Studio 2 Pro standalone or the VST might work in your DAW of choice, it should be in your VST3 folder."
exit 0
