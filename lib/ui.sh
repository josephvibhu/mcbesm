#!/bin/bash

# --- Color Definitions ---
# Using standard ANSI escape codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color (Reset)

# --- UI Icons ---
# These look great in modern terminals (VS Code, Ubuntu Terminal)
CHECKMARK="✔"
CROSS="✘"
INFO="ℹ"
WARN="⚠"

# --- Message Functions ---

success_msg() {
    echo -e "${GREEN}${BOLD}${CHECKMARK} SUCCESS:${NC} $1"
}

error_msg() {
    echo -e "${RED}${BOLD}${CROSS} ERROR:${NC} $1"
}

info_msg() {
    echo -e "${CYAN}${BOLD}${INFO} INFO:${NC} $1"
}

warn_msg() {
    echo -e "${YELLOW}${BOLD}${WARN} WARNING:${NC} $1"
}

# --- Decorative Elements ---

print_header() {
    echo -e "${BLUE}${BOLD}========================================${NC}"
    echo -e "${BLUE}${BOLD}   MCBESM: Bedrock Server Manager       ${NC}"
    echo -e "${BLUE}${BOLD}========================================${NC}"
}

print_usage() {
    print_header
    echo -e "${BOLD}Usage:${NC} mcbesm [command] [world_name]"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo -e "  ${GREEN}create${NC} <name>   Download and set up a new server instance"
    echo -e "  ${GREEN}start${NC}  <name>   Launch a server in the background (Screen)"
    echo -e "  ${GREEN}stop${NC}   <name>   Safely shut down a running server"
    echo -e "  ${GREEN}status${NC}          List all online and offline worlds"
    echo -e "  ${GREEN}help${NC}            Show this menu"
    echo ""
    echo -e "${CYAN}Example:${NC} mcbesm start survival_world"
}

# --- Interactive Elements ---

confirm_action() {
    # Usage: if confirm_action "Do you want to delete this?"; then ...
    read -p "$(echo -e "${YELLOW}${BOLD}??${NC} $1 [y/N]: ")" response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
