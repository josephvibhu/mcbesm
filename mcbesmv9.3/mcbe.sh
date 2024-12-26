#!/bin/bash
# mcbesmv9.3 by josephvibhu

# Path variables
SOURCE_DIR="/home/sudojoe/mcbesm"
SERVER_DIR="/home/sudojoe/server/bedrock-server"
TEMP_DIR="/home/sudojoe/temp"

# Source the modular functions using the relative path
source "$SCRIPT_DIR/mcbesm/src/mcbeup.sh"
source "$SCRIPT_DIR/mcbesm/src/mcbebak.sh"
source "$SCRIPT_DIR/mcbesm/src/mcbeinstall.sh"

mcbe() {
    # Check if the server directory exists
    if [ -d $SCRIPT_DIR/mcbesm/server/bedrock-server ]; then
        echo "Directory found! Proceeding with the script..."
    else
        # Installs Minecraft if the directory does not exist
        echo "Directory not found! Installing minecraft server..."
        mcbeinstall
        exit 0
    fi
    
    # Listing Worlds
    echo "Listing available worlds in 'server/bedrock-server/worlds/' directory..."
    worlds=$(find $SCRIPT_DIR/mcbesm/server/bedrock-server/worlds/ -mindepth 1 -maxdepth 1 -type d | sed 's|^.*/||')

    [ -n "$worlds" ] || { echo "No worlds available in the 'worlds' directory!"; exit 1; }

    echo "Available worlds:"
    echo "$worlds"

    # Propmpts for the world to start the server in
    read -p "Enter the name of the world (leave empty to generate a new world): " world_name
    world_name=$(echo "$world_name" | xargs)

    # Update server.properties
    sed -i "s/^level-name=.*/level-name=$world_name/" mcbesm/server/bedrock-server/server.properties || { echo "Failed to update server.properties"; exit 1; }

    # Start the server
    run

}

run() {
    # Starts the server
    cd mcbesm/server/bedrock-server
    echo "Starting the Minecraft server with world '$world_name'..."
    LD_LIBRARY_PATH=. ./bedrock_server

    # After the server is stopped using stop 
    # Prompt to backup world
    read -p "Do you want to backup the world (y/n)? " backup_choice
    if [ "$backup_choice" == "y" ]; then
        mcbebak "$world_name"
    else
        echo "Skipping backup for '$world_name'."
    fi

    # Prompt to update server
    read -p "Do you want to update the server (y/n)? " update_choice
    if [ "$update_choice" == "y" ]; then
        mcbeup
    else
        echo "Skipping server update."
    fi
}

# Main function
main() {
    mcbe
}

maincbe
}

main
