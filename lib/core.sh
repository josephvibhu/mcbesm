#!/bin/bash

# Load configuration and UI helpers
source "$(dirname "${BASH_SOURCE[0]}")/../config/mcbesm.conf"
source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

# --- Function: Create a New World ---
mc_create() {
    local world_name=$1
    local requested_port=$2  # The new port argument
    
    # --- 1. Validation ---
    if [ -z "$world_name" ]; then
        error_msg "Usage: mcbesm create <world_name> [port]"
        return 1
    fi

    if [ -d "$INSTANCES_DIR/$world_name" ]; then
        error_msg "World '$world_name' already exists."
        return 1
    fi

    # --- 2. Smart Port Selection (Fixed for IPv6) ---
    if [ -n "$requested_port" ]; then
        final_port=$requested_port
    else
        info_msg "Scanning for available port pair..."
        # Find the highest port used
        max_port=$(grep -rh "^server-port=" "$INSTANCES_DIR"/*/server.properties 2>/dev/null | cut -d'=' -f2 | tr -d '\r' | sort -n | tail -1)
        
        if [ -z "$max_port" ]; then
            final_port=41675
        else
            # INCREMENT BY 2 to avoid IPv6 shadowing
            final_port=$((max_port + 2))
        fi
    fi

    # --- 3. Versioning & API Logic ---
    info_msg "Checking API for latest version..."
    local rand_num=$RANDOM
    curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L \
         -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.$rand_num.212 Safari/537.36" \
         -o "$DOWNLOAD_CACHE/version.json" "$API_URL"

    local latest_url=$(grep -o 'https://www.minecraft.net/bedrockdedicatedserver/bin-linux/[^"]*' "$DOWNLOAD_CACHE/version.json" | head -n 1)
    local latest_file=$(echo "$latest_url" | sed 's#.*/##')

    if [ -z "$latest_file" ]; then
        error_msg "API retrieval failed. Check your network or the API URL."
        return 1
    fi

    local target_file="$latest_file"
    local target_url="$latest_url"

    if [ -e "$PIN_FILE" ]; then
        local pin_file=$(cat "$PIN_FILE")
        warn_msg "Version pin found: $pin_file"
        target_file="$pin_file"
        target_url="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/$target_file"
    fi

    # --- 4. Download & Extraction ---
    if [ ! -f "$DOWNLOAD_CACHE/$target_file" ]; then
        info_msg "Downloading version: $target_file"
        curl -L -A "Mozilla/5.0" -o "$DOWNLOAD_CACHE/$target_file" "$target_url"
    else
        info_msg "Version $target_file found in cache. Skipping download."
    fi

    info_msg "Extracting to instances/$world_name..."
    mkdir -p "$INSTANCES_DIR/$world_name"
    unzip -o -q "$DOWNLOAD_CACHE/$target_file" -d "$INSTANCES_DIR/$world_name"

    # --- 5. Post-Installation Configuration ---
    info_msg "Applying server configurations for port $final_port..."
    local prop_file="$INSTANCES_DIR/$world_name/server.properties"
    
    if [ -f "$prop_file" ]; then
        # Networking Essentials: Set unique IPv4 and IPv6 ports
        sed -i "s/^server-port=.*/server-port=$final_port/" "$prop_file"
        sed -i "s/^server-portv6=.*/server-portv6=$((final_port + 1))/" "$prop_file"
        
        # Performance & Gameplay tweaks
        sed -i 's/^view-distance=.*/view-distance=64/' "$prop_file"
        sed -i 's/^max-threads=.*/max-threads=0/' "$prop_file"
    fi

    # --- 6. Finalize ---
    chmod +x "$INSTANCES_DIR/$world_name/bedrock_server"
    echo "$target_file" > "$INSTALLED_RECORD"
    success_msg "World '$world_name' is ready on port $final_port!"
}

# --- Function: Start a Server ---
mc_start() {
    local instance_name=$1
    local worlds_dir="$INSTANCES_DIR/$instance_name/worlds"
    
    # 1. List worlds and ask user to pick one
    info_msg "Available worlds in $instance_name:"
    local worlds=($(ls -d "$worlds_dir"/*/ 2>/dev/null | sed 's#.*/##; s#/##'))
    
    if [ ${#worlds[@]} -eq 0 ]; then
        error_msg "No worlds found. Use 'import' or 'create' first."
        return 1
    fi

    for i in "${!worlds[@]}"; do
        echo "  [$i] ${worlds[$i]}"
    done

    echo -en "${YELLOW}${BOLD}?? Select world number to run [Default 0]: ${NC}"
    read -r choice
    choice=${choice:-0}
    local selected_world=${worlds[$choice]}

    # 2. Update server.properties BEFORE starting
    sed -i "s/^level-name=.*/level-name=$selected_world/" "$INSTANCES_DIR/$instance_name/server.properties"
    
    # 3. Standard Start Logic (Screen)
    # ... [Keep your existing screen -dmS logic here] ...
    info_msg "Launching '$instance_name' with world '$selected_world'..."
    cd "$INSTANCES_DIR/$instance_name" && screen -dmS "mc_$instance_name" bash -c "export LD_LIBRARY_PATH=. && ./bedrock_server"
    success_msg "Server is live!"
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

# --- Function: Advanced Status Dashboard (Fixed Alignment) ---
mc_status() {
    screen -wipe > /dev/null 
    local_ip=$(hostname -I | awk '{print $1}')
    
    print_header
    print_table_header

    for world_path in "$INSTANCES_DIR"/*; do
        [ -d "$world_path" ] || continue
        
        world_name=$(basename "$world_path")
        prop_file="$world_path/server.properties"
        session_name="mc_$world_name"
        
        # 1. Determine Status & Color logic
        if screen -list | grep -q "\.$session_name"; then
            status_color=$GREEN
            status_text="Running"
        else
            status_color=$RED
            status_text="Offline"
        fi

        # 2. Get Port
        port=$(grep "^server-port=" "$prop_file" 2>/dev/null | cut -d'=' -f2 | tr -d '\r')
        [ -z "$port" ] && port="19132"

        # --- NEW CODE START: Get Active World Name ---
        active_world=$(grep "^level-name=" "$prop_file" 2>/dev/null | cut -d'=' -f2 | tr -d '\r')
        [ -z "$active_world" ] && active_world="Bedrock level"
        # --- NEW CODE END ---

        # 3. Get Version (Cleanly)
        # (Note: Using per-world version.txt is better for multi-version setups)
        if [ -f "$world_path/version.txt" ]; then
            version=$(cat "$world_path/version.txt" | grep -oP '\d+\.\d+\.\d+\.\d+')
        else
            version="Unknown"
        fi

        # 4. The Aligned Print Logic
        # Update the first printf to include the new column %-15s
        printf "%-15s | " "$world_name"
        printf "%-15s | " "$active_world"   # <--- ADD THIS LINE
        printf "${status_color}%-12s${NC} | " "$status_text"
        printf "%-10s | " "$version"
        printf "%-18s | " "$local_ip"
        printf "%-8s\n" "$port"
    done
    echo -e "${BLUE}${BOLD}----------------------------------------------------------------------------------${NC}"
}

# --- Function: Attach to Server Console ---
mc_console() {
    local world_name=$1
    local session_name="mc_$world_name"

    # Check if a name was provided
    if [ -z "$world_name" ]; then
        error_msg "Usage: mcbesm console <world_name>"
        return 1
    fi

    # Check if the session actually exists
    if screen -list | grep -q "\.$session_name"; then
        info_msg "Attaching to '${world_name}' console..."
        echo -e "${YELLOW}${BOLD}IMPORTANT:${NC} Press ${CYAN}Ctrl+A${NC} then ${CYAN}D${NC} to detach."
        echo -e "Do ${RED}NOT${NC} use Ctrl+C or you will kill the server!"
        sleep 2
        screen -r "$session_name"
    else
        error_msg "Server '$world_name' is not currently running."
        return 1
    fi
}

# --- Function: Advanced Property Editor ---
mc_config() {
    local world_name=$1
    local key=$2
    local value=$3
    local prop_file="$INSTANCES_DIR/$world_name/server.properties"

    # 1. Basic Validation
    if [ -z "$world_name" ]; then
        error_msg "Usage: mcbesm config <world_name> [property_key] [new_value]"
        return 1
    fi

    if [ ! -f "$prop_file" ]; then
        error_msg "Config file for '$world_name' not found."
        return 1
    fi

    # 2. VIEW MODE: If only the world name is provided
    if [ -z "$key" ]; then
        print_header
        info_msg "Current configuration for '$world_name':"
        echo -e "${BLUE}--------------------------------------------------${NC}"
        # Filter out comments (#) and empty lines for a clean view
        grep -v "^#" "$prop_file" | grep -v "^$" | column -t -s "="
        echo -e "${BLUE}--------------------------------------------------${NC}"
        info_msg "To edit: mcbesm config $world_name <key> <value>"
        return 0
    fi

    # 3. UPDATE MODE: Change a specific property
    if [ -n "$key" ] && [ -n "$value" ]; then
        # Check if the key actually exists in the file first
        if ! grep -q "^$key=" "$prop_file"; then
            error_msg "Property '$key' does not exist in server.properties."
            return 1
        fi

        # Perform the update using sed
        # This replaces the line starting with 'key=' with 'key=value'
        sed -i "s/^$key=.*/$key=$value/" "$prop_file"
        
        success_msg "Updated '$key' to '$value' for world '$world_name'."
        
        # UI Check: If server is running, warn the user
        if screen -list | grep -q "\.mc_$world_name\s"; then
            warn_msg "Server is currently running. Restart it to apply changes."
        fi
    else
        # If they provided a key but no value
        local current_val=$(grep "^$key=" "$prop_file" | cut -d'=' -f2)
        info_msg "Current value for '$key' is: ${YELLOW}$current_val${NC}"
    fi
}

# --- Function: Delete a World ---
mc_delete() {
    local world_name=$1
    local session_name="mc_$world_name"

    if [ -z "$world_name" ]; then
        error_msg "Usage: mcbesm delete <world_name>"
        return 1
    fi

    if [ ! -d "$INSTANCES_DIR/$world_name" ]; then
        error_msg "World '$world_name' not found."
        return 1
    fi

    # Security: Don't delete a running server!
    if screen -list | grep -q "\.$session_name\s"; then
        error_msg "Server is running. Stop it first with 'mcbesm stop $world_name'."
        return 1
    fi

    # Confirmation using the function from ui.sh
    if confirm_action "Are you sure you want to PERMANENTLY delete '$world_name'?"; then
        info_msg "Deleting files and freeing ports..."
        rm -rf "$INSTANCES_DIR/$world_name"
        success_msg "World '$world_name' has been removed. Ports are now available for reuse."
    else
        info_msg "Deletion cancelled."
    fi
}

# --- Function: Multi-Format World Import ---
mc_import() {
    local instance_name="$1"
    local input_path="$2"
    local new_world_name="$3"
    
    # [Keep your basic validation here...]

    local instance_path="$INSTANCES_DIR/$instance_name"
    local dest_dir="$instance_path/worlds/$new_world_name"

    # 1. Detect File Type (Reliable Way)
    local file_type=$(file --mime-type -b "$input_path")

    # 2. Process based on actual content, not just extension
    if [ -d "$input_path" ]; then
        info_msg "Importing folder..."
        cp -r "$input_path" "$dest_dir" || return 1
        
    elif [[ "$file_type" == "application/zip" ]] || [[ "$input_path" == *.mcworld ]]; then
        info_msg "Extracting ZIP/MCWORLD..."
        mkdir -p "$dest_dir"
        if unzip -o -q "$input_path" -d "$dest_dir"; then
            success_msg "Imported '$new_world_name' successfully."
        else
            error_msg "ZIP extraction failed."; rm -rf "$dest_dir"; return 1
        fi

    elif [[ "$file_type" == "application/x-rar" ]] || [[ "$file_type" == "application/vnd.rar" ]]; then
        info_msg "Extracting RAR archive..."
        mkdir -p "$dest_dir"
        # 'unrar x' extracts with full paths, '-idq' is quiet mode
        if unrar x -idq "$input_path" "$dest_dir/"; then
            success_msg "Imported RAR-based world '$new_world_name'."
        else
            error_msg "RAR extraction failed. Is 'unrar' installed?"; rm -rf "$dest_dir"; return 1
        fi

    else
        error_msg "Unsupported file type: $file_type"
        return 1
    fi

    chmod -R 755 "$dest_dir"
}

# --- Function: List all worlds inside an instance ---
mc_list_worlds() {
    local instance_name="$1"
    
    # 1. Validation
    if [ -z "$instance_name" ]; then
        error_msg "Usage: mcbesm worlds <instance_name>"
        return 1
    fi

    # Ensure we have the full path to the instances folder
    local worlds_dir="$INSTANCES_DIR/$instance_name/worlds"

    if [ ! -d "$worlds_dir" ]; then
        error_msg "Directory not found: $worlds_dir"
        info_msg "Maybe the instance name is misspelled?"
        return 1
    fi

    print_header
    info_msg "Scanning storage for '$instance_name'..."
    echo -e "${BLUE}--------------------------------------------------${NC}"
    
    # Use 'find' instead of 'ls' - it's more reliable for scripts
    local count=0
    while IFS= read -r dir; do
        world=$(basename "$dir")
        echo -e "  [${CYAN}#${NC}] $world"
        ((count++))
    done < <(find "$worlds_dir" -maxdepth 1 -mindepth 1 -type d)

    if [ "$count" -eq 0 ]; then
        warn_msg "No world folders found in $worlds_dir"
    else
        echo -e "${BLUE}--------------------------------------------------${NC}"
        success_msg "Found $count world(s)."
    fi
}
