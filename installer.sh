#!/bin/bash

# Set constants
LOG_DIR="/Users/Shared/Logging"
PROCESSOR=$(uname -m)
LOG_FILE="${PROCESSOR}-Installer-Logs-$(date +%Y%m%d-%H%M%S).log"

# Set URLs based on processor type
if [[ "$PROCESSOR" == "arm64" ]]; then
  APP_URLS=(
    "https://download.tableplus.com/macos/490/TablePlus.dmg"
  )
else
  APP_URLS=(
    "https://download.tableplus.com/macos/490/TablePlus.dmg"
  )
fi

# Define functions
install_dmg_app() {
  url="$1"
  dmg_name="$(basename "$url")"
  pkg_name="$(echo "$dmg_name" | sed -E 's/(.*)\..*/\1/').pkg"

  echo "Installing $dmg_name..."
  curl --silent --location --remote-name "$url"
  volume="$(hdiutil attach -nobrowse "$dmg_name" | grep Volumes | sed 's/.*\/Volumes\//\/Volumes\//')"
  cp -R "$volume"/*.app /Applications/
  hdiutil detach "$volume"
  pkgbuild --root "$volume" --identifier com.example.app "$pkg_name"
  installer -pkg "$pkg_name" -target /
  rm "$dmg_name" "$pkg_name"
}

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Redirect output to log file
exec &> >(tee -a "$LOG_DIR/$LOG_FILE")

# Log variable values
echo "PROCESSOR=$PROCESSOR"
for app_url in "${APP_URLS[@]}"; do
  echo "APP_URL=$app_url"
done

# Install applications
for app_url in "${APP_URLS[@]}"; do
  if [[ "$app_url" == *".dmg" ]]; then
    install_dmg_app "$app_url"
  elif [[ "$app_url" == *".zip" ]]; then
    echo "Downloading and installing $(basename "$app_url")..."
    curl --silent --location "$app_url" -o /tmp/app.zip
    unzip -q /tmp/app.zip -d /Applications/
    rm /tmp/app.zip
  else
    echo "Unsupported application format for $app_url"
  fi
done


echo "Done"
