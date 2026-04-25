#!/bin/bash

# Load configuration and UI helpers
source "$(dirname "${BASH_SOURCE[0]}")/../config/mcbesm.conf"
source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

# --- Function: Create a New World ---
mc_create() {
    local world_name=$1
    if [ -z "$world_name" ]; then
        error_msg "Usage: mcbesm create <world_name>"
        return 1
    fi

    if [ -d "$INSTANCES_DIR/$world_name" ]; then
        error_msg "A world named '$world_name' already exists."
        return 1
    fi

    info_msg "Fetching latest Bedrock Server download link..."
    # Scrapes the official site for the Linux download URL
    DOWNLOAD_URL=$(curl -A "$USER_AGENT" -s https://www.minecraft.net/en-us/download/server/bedrock | grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*')

    if [ -z "$DOWNLOAD_URL" ]; then
        error_msg "Could not retrieve download link. Check your internet connection."
        return 1
    fi

    info_msg "Downloading server software..."
    curl -A "$USER_AGENT" -L "$DOWNLOAD_URL" -o "$DOWNLOAD_CACHE/bedrock_latest.zip"

    info_msg "Setting up instance: $world_name"
    mkdir -p "$INSTANCES_DIR/$world_name"
    unzip -q "$DOWNLOAD_CACHE/bedrock_latest.zip" -d "$INSTANCES_DIR/$world_name"

    # Auto-accept EULA logic (Bedrock doesn't have a eula.txt, but we ensure permissions)
    chmod +x "$INSTANCES_DIR/$world_name/bedrock_server"
    
    success_msg "World '$world_name' created successfully."
}

# --- Function: Start a Server ---
mc_start() {
    local world_name=$1
    local session_name="mc_$world_name"

    if screen -list | grep -q "\.$session_name"; then
        error_msg "Server '$world_name' is already running."
        return 1
    fi

    if [ ! -d "$INSTANCES_DIR/$world_name" ]; then
        error_msg "World '$world_name' not found."
        return 1
    fi

    info_msg "Starting '$world_name' in the background..."
    cd "$INSTANCES_DIR/$world_name" || return
    
    # LD_LIBRARY_PATH is required for Bedrock server to find its own dependencies
    screen -dmS "$session_name" bash -c "export LD_LIBRARY_PATH=. && ./bedrock_server"
    
    # Networking tip: Show the local IP so you know where to connect
    local_ip=$(hostname -I | awk '{print $1}')
    success_msg "Server started! Connect via $local_ip:19132"
}

# --- Function: Stop a Server ---
mc_stop() {
    local world_name=$1
    local session_name="mc_$world_name"

    if ! screen -list | grep -q "\.$session_name"; then
        error_msg "Server '$world_name' is not running."
        return 1
    fi

    info_msg "Sending stop command to '$world_name'..."
    # Injects the 'stop' command into the screen session
    screen -S "$session_name" -X stuff "stop$(printf \\r)"
    success_msg "Stop command sent. The session will close once saving is complete."
}

# --- Function: List Status ---
mc_status() {
    echo -e "${BLUE}--- Minecraft Bedrock Status ---${NC}"
    local running_servers=$(screen -ls | grep "mc_" | awk '{print $1}')

    if [ -z "$running_servers" ]; then
        echo "No servers are currently online."
    else
        echo "Online Worlds:"
        echo "$running_servers" | sed 's/^[0-9]*\.mc_//' | sed 's/^/  - /'
    fi
}
