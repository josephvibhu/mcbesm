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
UNDERLINE='\033[4m'
NC='\033[0m' # No Color (Reset)

# --- Status-Specific Styling ---
# These make the status dashboard logic much cleaner in core.sh
STATUS_RUNNING="${GREEN}${BOLD}RUNNING${NC}"
STATUS_OFFLINE="${RED}OFFLINE${NC}"
STATUS_WARN="${YELLOW}PENDING${NC}"

# --- Icons ---
CHECKMARK="✔"
CROSS="✘"
INFO="ℹ"
WARN="⚠"
GEAR="⚙"

# --- Messaging Functions ---

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

# --- Dashboard & Table UI ---

print_header() {
    echo -e "${BLUE}${BOLD}=========================================================================${NC}"
    echo -e "${WHITE}${BOLD}   MCBESM: Bedrock Server Management Suite${NC}"
    echo -e "${BLUE}${BOLD}=========================================================================${NC}"
}

print_table_header() {
    # This matches the printf logic in your mc_status function
    echo -e "${BLUE}${BOLD}-------------------------------------------------------------------------${NC}"
    printf "${BOLD}%-15s | %-12s | %-10s | %-18s | %-8s${NC}\n" \
           "WORLD NAME" "STATUS" "VERSION" "IP ADDRESS" "PORT"
    echo -e "${BLUE}${BOLD}-------------------------------------------------------------------------${NC}"
}

print_usage() {
    print_header
    echo -e "${BOLD}Usage:${NC} mcbesm [command] [world_name]"
    echo ""
    echo -e "${BOLD}Management Commands:${NC}"
    echo -e "  ${CYAN}create${NC} <name>   Deploy a new instance from the latest API"
    echo -e "  ${CYAN}start${NC}  <name>   Launch instance in background (Screen)"
    echo -e "  ${CYAN}stop${NC}   <name>   Safe shutdown via console injection"
    echo -e "  ${CYAN}console${NC} <name>  Attach to the live server terminal"
    echo ""
    echo -e "${BOLD}Information Commands:${NC}"
    echo -e "  ${CYAN}status${NC}          View the live server dashboard"
    echo -e "  ${CYAN}help${NC}            Show this documentation"
    echo ""
}

# --- User Interaction ---

confirm_action() {
    # Example: if confirm_action "Delete world '$1'?"; then ...
    echo -en "${YELLOW}${BOLD}${WARN} CONFIRM:${NC} $1 [y/N]: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}
