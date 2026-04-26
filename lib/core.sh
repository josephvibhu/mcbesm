#!/bin/bash

# Load configuration and UI helpers
# Using absolute path to ensure files are found regardless of where the script is run
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/../config/mcbesm.conf"
source "$LIB_DIR/ui.sh"

# --- Function: Create a New World ---
mc_create() {
    local world_name="$1"
    local requested_port="$2"
    
    if [ -z "$world_name" ]; then
        error_msg "Usage: mcbesm create <world_name> [port]"
        return 1
    fi

    if [ -d "$INSTANCES_DIR/$world_name" ]; then
        error_msg "World '$world_name' already exists."
        return 1
    fi

    # Smart Port Selection (Fixed for IPv6 Shadowing)
    if [ -n "$requested_port" ]; then
        final_port=$requested_port
    else
        info_msg "Scanning for available port pair..."
        max_port=$(grep -rh "^server-port=" "$INSTANCES_DIR"/*/server.properties 2>/dev/null | cut -d'=' -f2 | tr -d '\r' | sort -n | tail -1)
        final_port=$([ -z "$max_port" ] && echo 41675 || echo $((max_port + 2)))
    fi

    # Versioning & API Logic
    info_msg "Checking API for latest version..."
    local rand_num=$RANDOM
    curl -s -H "Accept-Encoding: identity" -H "Accept-Language: en" -L \
         -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.$rand_num.212 Safari/537.36" \
         -o "$DOWNLOAD_CACHE/version.json" "$API_URL"

    local latest_url=$(grep -o 'https://www.minecraft.net/bedrockdedicatedserver/bin-linux/[^"]*' "$DOWNLOAD_CACHE/version.json" | head -n 1)
    local latest_file=$(echo "$latest_url" | sed 's#.*/##')

    [ -z "$latest_file" ] && { error_msg "API retrieval failed."; return 1; }

    # Handle Version Pinning
    local target_file="$latest_file"
    local target_url="$latest_url"
    if [ -e "$PIN_FILE" ]; then
        target_file=$(cat "$PIN_FILE")
        target_url="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/$target_file"
        warn_msg "Version pin active: $target_file"
    fi

    # Download & Extraction
    if [ ! -f "$DOWNLOAD_CACHE/$target_file" ]; then
        info_msg "Downloading: $target_file"
        curl -L -A "Mozilla/5.0" -o "$DOWNLOAD_CACHE/$target_file" "$target_url"
    fi

    info_msg "Extracting to instances/$world_name..."
    mkdir -p "$INSTANCES_DIR/$world_name"
    unzip -o -q "$DOWNLOAD_CACHE/$target_file" -d "$INSTANCES_DIR/$world_name"

    # Post-Installation Config
    local prop_file="$INSTANCES_DIR/$world_name/server.properties"
    if [ -f "$prop_file" ]; then
        sed -i "s/^server-port=.*/server-port=$final_port/" "$prop_file"
        sed -i "s/^server-portv6=.*/server-portv6=$((final_port + 1))/" "$prop_file"
        sed -i 's/^view-distance=.*/view-distance=64/' "$prop_file"
    fi

    chmod +x "$INSTANCES_DIR/$world_name/bedrock_server"
    echo "$target_file" > "$INSTANCES_DIR/$world_name/version.txt"
    success_msg "Instance '$world_name' ready on port $final_port!"
}

# --- Function: Start a Server ---
mc_start() {
    local instance_name="$1"
    local worlds_dir="$INSTANCES_DIR/$instance_name/worlds"
    
    if [ ! -d "$INSTANCES_DIR/$instance_name" ]; then
        error_msg "Instance '$instance_name' not found."; return 1
    fi

    # 1. World Selection Logic
    info_msg "Available worlds in $instance_name:"
    local worlds=($(ls -d "$worlds_dir"/*/ 2>/dev/null | sed 's#.*/##; s#/##'))
    
    if [ ${#worlds[@]} -eq 0 ]; then
        error_msg "No worlds found inside 'worlds/' folder."; return 1
    fi

    for i in "${!worlds[@]}"; do echo "  [$i] ${worlds[$i]}"; done
    echo -en "${YELLOW}${BOLD}?? Select world index [Default 0]: ${NC}"
    read -r choice
    choice=${choice:-0}
    local selected_world=${worlds[$choice]}

    # 2. Update config and Launch
    sed -i "s/^level-name=.*/level-name=$selected_world/" "$INSTANCES_DIR/$instance_name/server.properties"
    info_msg "Launching '$instance_name' with world '$selected_world'..."
    
    cd "$INSTANCES_DIR/$instance_name" || return
    screen -dmS "mc_$instance_name" bash -c "export LD_LIBRARY_PATH=. && ./bedrock_server"
    success_msg "Server is live! Use 'mcbesm console $instance_name' to view."
}

# --- Function: Stop a Server ---
mc_stop() {
    local name="$1"
    local session="mc_$name"
    if ! screen -list | grep -q "\.$session\s"; then
        error_msg "Server '$name' is not running."; return 1
    fi
    info_msg "Stopping '$name'..."
    screen -S "$session" -X stuff "stop$(printf \\r)"
    success_msg "Stop command sent."
}

# --- Function: Advanced Status Dashboard ---
mc_status() {
    screen -wipe > /dev/null
    local_ip=$(hostname -I | awk '{print $1}')
    
    print_header
    print_table_header # Uses the 14|16|10|10|16|6 padding

    for world_path in "$INSTANCES_DIR"/*; do
        [ -d "$world_path" ] || continue
        name=$(basename "$world_path")
        prop_file="$world_path/server.properties"
        
        # 1. Determine Status
        if screen -list | grep -q "\.mc_$name\s"; then
            s_col=$GREEN; s_txt="Running"
        else
            s_col=$RED; s_txt="Offline"
        fi

        # 2. Extract Data
        port=$(grep "^server-port=" "$prop_file" 2>/dev/null | cut -d'=' -f2 | tr -d '\r')
        active_world=$(grep "^level-name=" "$prop_file" 2>/dev/null | cut -d'=' -f2 | tr -d '\r')
        [ ${#active_world} -gt 15 ] && active_world="${active_world:0:13}.."

        # 3. Get Version (Instance Specific)
        if [ -f "$world_path/version.txt" ]; then
            ver=$(cat "$world_path/version.txt" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
        else
            ver="Unknown"
        fi

        # 4. FIXED PADDING: Colors applied OUTSIDE the width limit
        printf "%-14s | " "$name"
        printf "%-16s | " "${active_world:-Bedrock level}"
        printf "${s_col}%-10s${NC} | " "$s_txt"
        printf "%-10s | " "${ver:-?.?.?}"
        printf "%-16s | " "${local_ip:-127.0.0.1}"
        printf "%-6s\n" "${port:-19132}"
    done
    draw_hr
}

# --- Function: Advanced Property Editor ---
mc_config() {
    local world_name="$1"
    local key="$2"
    local value="$3"
    local prop_file="$INSTANCES_DIR/$world_name/server.properties"

    if [ -z "$world_name" ] || [ ! -f "$prop_file" ]; then
        error_msg "Invalid instance or config not found."; return 1
    fi

    if [ -z "$key" ]; then
        print_header
        info_msg "Config for '$world_name':"
        draw_hr
        grep -v "^#" "$prop_file" | grep -v "^$" | column -t -s "="
        draw_hr
        return 0
    fi

    if [ -n "$value" ]; then
        if ! grep -q "^$key=" "$prop_file"; then
            error_msg "Key '$key' not found."; return 1
        fi
        sed -i "s/^$key=.*/$key=$value/" "$prop_file"
        success_msg "Set $key to $value."
        screen -list | grep -q "\.mc_$world_name\s" && warn_msg "Restart required."
    else
        echo -e "Current $key: ${YELLOW}$(grep "^$key=" "$prop_file" | cut -d'=' -f2)${NC}"
    fi
}

# --- Function: Import Custom World (MIME-Aware) ---
mc_import() {
    local instance="$1"
    local path="$2"
    local name="$3"
    local dest="$INSTANCES_DIR/$instance/worlds/$name"

    if [ -z "$instance" ] || [ -z "$path" ] || [ -z "$name" ]; then
        error_msg "Usage: mcbesm import <instance> <path> <name>"; return 1
    fi

    [ ! -d "$INSTANCES_DIR/$instance" ] && { error_msg "Instance not found."; return 1; }
    
    local type=$(file --mime-type -b "$path")
    mkdir -p "$dest"

    if [ -d "$path" ]; then
        cp -r "$path/." "$dest/"
    elif [[ "$type" == *"zip"* ]] || [[ "$path" == *.mcworld ]]; then
        unzip -o -q "$path" -d "$dest"
    elif [[ "$type" == *"rar"* ]]; then
        unrar x -idq "$path" "$dest/"
    else
        error_msg "Unsupported format: $type"; rm -rf "$dest"; return 1
    fi

    chmod -R 755 "$dest"
    success_msg "Imported '$name' to '$instance'."
}

# --- Function: Delete Instance ---
mc_delete() {
    local name="$1"
    [ -z "$name" ] && return 1
    if screen -list | grep -q "\.mc_$name\s"; then
        error_msg "Server is running. Stop it first."; return 1
    fi

    if confirm_action "Delete ALL data for '$name'?"; then
        rm -rf "$INSTANCES_DIR/$name"
        success_msg "Instance '$name' deleted."
    fi
}

# --- Function: List Worlds ---
mc_list_worlds() {
    local name="$1"
    local dir="$INSTANCES_DIR/$name/worlds"
    [ ! -d "$dir" ] && { error_msg "Instance not found."; return 1; }
    
    print_header
    info_msg "Worlds in '$name':"
    draw_hr
    find "$dir" -maxdepth 1 -mindepth 1 -type d | sed 's#.*/##' | sed 's/^/  - /'
    draw_hr
}

# --- Function: List Cached Versions ---
mc_versions() {
    print_header
    info_msg "Cached binaries (.cache/):"
    draw_hr
    ls "$DOWNLOAD_CACHE"/*.zip 2>/dev/null | sed 's#.*/##' | sed 's/^/  - /'
    draw_hr
}
