#!/bin/bash
#v1.0

# Function to install minecraft bedrock server
mcbeinstall() {
    echo "Checking for the latest version of Minecraft Bedrock server available..."
    VERSION_FILE="server/version.txt"

    # Set random number for user-agent
    RandNum=$RANDOM

    # Download the latest version of Minecraft Bedrock server page
    curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.33 (KHTML, like Gecko) Chrome/90.0.$RandNum.212 Safari/537.33" -o temp/version.html https://minecraft.net/en-us/download/server/bedrock/

    # Extract the download URL for the latest server version
    LATEST_VERSION=$(basename $(grep -o 'https://www.minecraft.net/bedrockdedicatedserver/bin-linux/[^"]*' temp/version.html))  # Get the latest version file name

    # Construct the download URL
    DownloadURL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/$LATEST_VERSION"

    echo "Download URL: $DownloadURL"
    echo "LATEST_VERSION: $LATEST_VERSION"

    # Download the latest version of Minecraft Bedrock dedicated server
    echo "Downloading the latest version of Minecraft Bedrock server..."
    UserName=$(whoami)
    curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.33 (KHTML, like Gecko) Chrome/90.0.$RandNum.212 Safari/537.33" -o "temp/$LATEST_VERSION" "$DownloadURL"

    # Unzip the downloaded file
    echo "Unzipping the downloaded file..."
    unzip -o -q "temp/$LATEST_VERSION" -d temp/bedrock-server

    # Clean up the HTML file after extracting
    rm -f temp/version.html

    # Clean up the zip file after extracting
    rm -f temp/$LATEST_VERSION

    # Move the installed server files into the correct location
    mv  temp/bedrock-server server

    # Update the version.txt file to the maintain version info for future updates
    echo "Updating the version.txt file..."
    echo "$LATEST_VERSION" > "$VERSION_FILE"

    # Modify the server.properties file
    echo "Modifying server.properties file..."
    SERVER_PROPERTIES="server/bedrock-server/server.properties"

    if [[ -f "$SERVER_PROPERTIES" ]]; then
        # Add your custom properties that needs to be enabled as default
        sed -i 's/^view-distance=.*/view-distance=64/' "$SERVER_PROPERTIES"
        sed -i 's/^max-threads=.*/max-threads=0/' "$SERVER_PROPERTIES"
        sed -i 's/^server-port=.*/server-port=41675/' "$SERVER_PROPERTIES"
    else
        echo "server.properties not found. Install failed. Execute command once again..."
        exit 0
    fi

    echo "Server install and configuration complete!"

    echo "Server install complete!"

    cd server/bedrock-server
    LD_LIBRARY_PATH=. ./bedrock_server 
    cd ..
    cd ..

    mv server/bedrock-server/worlds/"Bedrock Level" base

    # Back to the main script
    mcbe
}
