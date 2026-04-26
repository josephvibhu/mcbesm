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
    echo -e "${BLUE}${BOLD}-------------------------------------------------------------------------${NC}"
    printf "${BOLD}%-15s | %-12s | %-10s | %-18s | %-8s${NC}\n" \
           "WORLD NAME" "STATUS" "VERSION" "IP ADDRESS" "PORT"
    echo -e "${BLUE}${BOLD}-------------------------------------------------------------------------${NC}"
}

print_usage() {
    print_header
    echo -e "${BOLD}Usage:${NC} mcbesm [command] [world_name] [args...]"
    echo ""
    echo -e "${BOLD}Management Commands:${NC}"
    echo -e "  ${CYAN}create${NC}  <name> [port] [ver]   Deploy server (Auto-port +2 logic)"
    echo -e "  ${CYAN}start${NC}   <name>                Launch instance in background"
    echo -e "  ${CYAN}stop${NC}    <name>                Safe shutdown via console injection"
    echo -e "  ${CYAN}config${NC}  <name> [key] [val]    Advanced server.properties editor"
    echo -e "  ${CYAN}console${NC} <name>                Attach to live server terminal"
    echo -e "  ${CYAN}delete${NC}  <name>                Permanently remove instance and free ports"
    echo ""
    echo -e "${BOLD}Information Commands:${NC}"
    echo -e "  ${CYAN}status${NC}                        View the live server dashboard"
    echo -e "  ${CYAN}versions${NC}                      List cached server binaries in .cache/"
    echo -e "  ${CYAN}help${NC}                          Show this documentation"
    echo ""
}
