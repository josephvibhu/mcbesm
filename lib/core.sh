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
        error_msg "World '$world_name' already exists."
        return 1
    fi

    # 1. Fetch Latest API Data
    info_msg "Checking API for latest version..."
    local rand_num=$RANDOM
    curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L \
         -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.$rand_num.212 Safari/537.36" \
         -o "$DOWNLOAD_CACHE/version.json" "$API_URL"

    # 2. Extract Logic
    local latest_url=$(grep -o 'https://www.minecraft.net/bedrockdedicatedserver/bin-linux/[^"]*' "$DOWNLOAD_CACHE/version.json" | head -n 1)
    local latest_file=$(echo "$latest_url" | sed 's#.*/##')

    if [ -z "$latest_file" ]; then
        error_msg "API retrieval failed. Check your network or the API URL."
        return 1
    fi

    # 3. Check for Version Pin (Manual Override)
    local target_file="$latest_file"
    local target_url="$latest_url"

    if [ -e "$PIN_FILE" ]; then
        local pin_file=$(cat "$PIN_FILE")
        warn_msg "Version pin found: $pin_file"
        target_file="$pin_file"
        target_url="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/$target_file"
    fi

    # 4. Handle Download (Only if not already in cache)
    if [ ! -f "$DOWNLOAD_CACHE/$target_file" ]; then
        info_msg "Downloading version: $target_file"
        curl -L -A "Mozilla/5.0" -o "$DOWNLOAD_CACHE/$target_file" "$target_url"
    else
        info_msg "Version $target_file found in cache. Skipping download."
    fi

    # 5. Create Instance and Unzip
    info_msg "Extracting to instances/$world_name..."
    mkdir -p "$INSTANCES_DIR/$world_name"
    unzip -o -q "$DOWNLOAD_CACHE/$target_file" -d "$INSTANCES_DIR/$world_name"
    
    # 6. Post-Installation Config (Using your old project's settings)
    info_msg "Applying server configurations..."
    local prop_file="$INSTANCES_DIR/$world_name/server.properties"
    if [ -f "$prop_file" ]; then
        # Note: I'm keeping your specific port and distance settings
        sed -i 's/^view-distance=.*/view-distance=64/' "$prop_file"
        sed -i 's/^max-threads=.*/max-threads=0/' "$prop_file"
        # We might want to make the port dynamic later so multiple servers can run!
        sed -i 's/^server-port=.*/server-port=41675/' "$prop_file"
    fi

    # 7. Finalize
    chmod +x "$INSTANCES_DIR/$world_name/bedrock_server"
    echo "$target_file" > "$INSTALLED_RECORD"
    success_msg "World '$world_name' is ready!"
}

# --- Function: Start a Server ---
# --- Function: Start a Server ---
mc_start() {
    local world_name=$1
    local session_name="mc_$world_name"
    local prop_file="$INSTANCES_DIR/$world_name/server.properties"

    # 1. Validation checks
    if [ ! -d "$INSTANCES_DIR/$world_name" ]; then
        error_msg "World '$world_name' not found."
        return 1
    fi

    if screen -list | grep -q "\.$session_name"; then
        error_msg "Server '$world_name' is already running."
        return 1
    fi

    # 2. Extract the actual port from server.properties
    # This ensures the UI matches the reality of the config
    local actual_port=$(grep "^server-port=" "$prop_file" | cut -d'=' -f2 | tr -d '\r')
    
    # Fallback to default if grep fails for some reason
    if [ -z "$actual_port" ]; then actual_port="19132"; fi

    info_msg "Starting '$world_name' on port $actual_port..."
    
    # 3. Launch
    cd "$INSTANCES_DIR/$world_name" || return
    screen -dmS "$session_name" bash -c "export LD_LIBRARY_PATH=. && ./bedrock_server"
    
    # 4. Success Output
    local_ip=$(hostname -I | awk '{print $1}')
    success_msg "Server started! Connect via ${local_ip}:${actual_port}"
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

# --- Function: Advanced Status Dashboard ---
mc_status() {
    local_ip=$(hostname -I | awk '{print $1}')
    
    echo -e "${BLUE}${BOLD}=========================================================================${NC}"
    printf "${BOLD}%-15s | %-10s | %-10s | %-20s | %-10s${NC}\n" "WORLD NAME" "STATUS" "VERSION" "ENDPOINT" "PORT"
    echo -e "${BLUE}=========================================================================${NC}"

    # Loop through all folders in the instances directory
    for world_path in "$INSTANCES_DIR"/*; do
        # Skip if it's not a directory
        [ -d "$world_path" ] || continue
        
        world_name=$(basename "$world_path")
        prop_file="$world_path/server.properties"
        session_name="mc_$world_name"
        
        # 1. Determine Operational Status
        if screen -list | grep -q "\.$session_name"; then
            status_text="${GREEN}Running${NC}"
        else
            status_text="${RED}Offline${NC}"
        fi

        # 2. Get Port from config
        if [ -f "$prop_file" ]; then
            port=$(grep "^server-port=" "$prop_file" | cut -d'=' -f2 | tr -d '\r')
        else
            port="???"
        fi

        # 3. Get Version (Reading from the record file we created in mc_create)
        # If the file doesn't exist, we'll just say 'Unknown'
        if [ -f "$PROJECT_ROOT/version_installed.txt" ]; then
            version=$(cat "$PROJECT_ROOT/version_installed.txt" | cut -d'-' -f3 | sed 's/.zip//')
        else
            version="Unknown"
        fi

        # 4. Print the Row
        # Using printf ensures the columns stay aligned regardless of name length
        printf "%-15s | %-19s | %-10s | %-20s | %-10s\n" \
               "$world_name" "$status_text" "$version" "$local_ip" "$port"
    done
    echo -e "${BLUE}=========================================================================${NC}"
}

# Jump into the Sever console
mc_console() {
    local world_name=$1
    if screen -list | grep -q "\.mc_$world_name"; then
        info_msg "Attaching to console. Press Ctrl+A then D to exit (don't use Ctrl+C!)"
        sleep 2
        screen -r "mc_$world_name"
    else
        error_msg "Server '$world_name' is not running."
    fi
}
