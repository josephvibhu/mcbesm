#!/bin/bash

# --- Color & Style Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Icons ---
CHECKMARK="✔"
CROSS="✘"
INFO="ℹ"
WARN="⚠"

# --- Messaging Functions ---
success_msg() { echo -e "${GREEN}${BOLD}${CHECKMARK} SUCCESS:${NC} $1"; }
error_msg()   { echo -e "${RED}${BOLD}${CROSS} ERROR:${NC} $1"; }
info_msg()    { echo -e "${CYAN}${BOLD}${INFO} INFO:${NC} $1"; }
warn_msg()    { echo -e "${YELLOW}${BOLD}${WARN} WARNING:${NC} $1"; }

# --- Dashboard & Table UI ---
print_header() {
    echo -e "${BLUE}${BOLD}=========================================================================${NC}"
    echo -e "${WHITE}${BOLD}   MCBESM: Bedrock Server Management Suite${NC}"
    echo -e "${BLUE}${BOLD}=========================================================================${NC}"
}

print_table_header() {
    # UPDATED: Added a 15-character column for the Active World
    # Column Widths: 15 | 15 | 12 | 10 | 18 | 8
    echo -e "${BLUE}${BOLD}------------------------------------------------------------------------------------${NC}"
    printf "${BOLD}%-15s | %-15s | %-12s | %-10s | %-18s | %-8s${NC}\n" \
           "INSTANCE" "ACTIVE WORLD" "STATUS" "VERSION" "IP ADDRESS" "PORT"
    echo -e "${BLUE}${BOLD}------------------------------------------------------------------------------------${NC}"
}

print_usage() {
    print_header
    echo -e "${BOLD}Usage:${NC} mcbesm [command] [instance_name] [args...]"
    echo ""
    echo -e "${BOLD}Management Commands:${NC}"
    echo -e "  ${CYAN}create${NC}  <name>         Deploy a new server instance"
    echo -e "  ${CYAN}start${NC}   <name>         Pick a world and launch in background"
    echo -e "  ${CYAN}stop${NC}    <name>         Graceful shutdown of the active world"
    echo -e "  ${CYAN}import${NC}  <name> <path>  Import .mcworld, .zip, or folder as a new world"
    echo -e "  ${CYAN}delete${NC}  <name>         Permanently remove instance and all its worlds"
    echo ""
    echo -e "${BOLD}Information & Config:${NC}"
    echo -e "  ${CYAN}status${NC}                 View dashboard (Instances vs. Active Worlds)"
    echo -e "  ${CYAN}worlds${NC}   <name>        List all worlds stored inside an instance"
    echo -e "  ${CYAN}config${NC}   <name> <k> <v> Edit server.properties for an instance"
    echo -e "  ${CYAN}versions${NC}               List cached server binaries"
    echo -e "  ${CYAN}console${NC}  <name>        Attach to the live server terminal"
    echo ""
    echo -e "💡 ${YELLOW}Tip:${NC} You can drag and drop world files into the terminal to paste their path!"
}

# --- User Interaction ---
confirm_action() {
    # Usage: if confirm_action "Delete world '$1'?"; then ...
    echo -en "${YELLOW}${BOLD}${WARN} CONFIRM:${NC} $1 [y/N]: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}
