#!/bin/bash

# --- Color & Style Definitions ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'
PURPLE='\033[0;35m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; BOLD='\033[1m'; NC='\033[0m'

# --- Icons ---
CHECKMARK="✔"; CROSS="✘"; INFO="ℹ"; WARN="⚠"

# --- Advanced UI Elements ---

# Generates a horizontal line that adapts to your terminal width
draw_hr() {
    # Get terminal width, default to 80 if detection fails
    local cols=$(tput cols 2>/dev/null || echo 85)
    # Cap the width at 100 so it doesn't look stretched on ultra-wide monitors
    [ "$cols" -gt 100 ] && cols=100
    printf "${BLUE}%${cols}s${NC}\n" | tr " " "-"
}

# --- Messaging Functions ---

success_msg() { echo -e "${GREEN}${BOLD}${CHECKMARK} SUCCESS:${NC} $1"; }
error_msg()   { echo -e "${RED}${BOLD}${CROSS} ERROR:${NC} $1"; }
info_msg()    { echo -e "${CYAN}${BOLD}${INFO} INFO:${NC} $1"; }
warn_msg()    { echo -e "${YELLOW}${BOLD}${WARN} WARNING:${NC} $1"; }

# --- Dashboard & Table UI ---
print_header() {
    local title="MCBESM: Bedrock Server Management Suite"
    
    # 1. Top Border: 1 corner + 84 bars + 1 corner = 86 chars
    echo -e "${BLUE}${BOLD}╔$(printf '═%.0s' {1..84})╗${NC}"
    
    # 2. Title Line: ║ (1) + space (1) + text/padding (82) + space (1) + ║ (1) = 86 chars
    # %-82s ensures the title area is always exactly 82 characters wide.
    printf "${BLUE}║${NC} ${WHITE}${BOLD}%-82s${NC} ${BLUE}║${NC}\n" "  $title"
    
    # 3. Bottom Border: 1 corner + 84 bars + 1 corner = 86 chars
    echo -e "${BLUE}${BOLD}╚$(printf '═%.0s' {1..84})╝${NC}"
}

print_table_header() {
    # Calculated Column Widths: 14 | 16 | 10 | 10 | 16 | 6 (Total ~80-85 chars)
    draw_hr
    printf "${BOLD}%-14s | %-16s | %-10s | %-10s | %-16s | %-6s${NC}\n" \
           "INSTANCE" "ACTIVE WORLD" "STATUS" "VERSION" "IP ADDRESS" "PORT"
    draw_hr
}

print_usage() {
    print_header
    echo -e "${BOLD}Usage:${NC} mcbesm [command] [instance_name] [args...]"
    echo ""
    echo -e "${BOLD}Management Commands:${NC}"
    echo -e "  ${CYAN}create${NC}  <name>         Deploy a new server instance"
    echo -e "  ${CYAN}start${NC}   <name>         Pick a world and launch in background"
    echo -e "  ${CYAN}stop${NC}    <name>         Graceful shutdown of the active world"
    echo -e "  ${CYAN}import${NC}  <name> <p> <n> Import .mcworld, .zip, or folder"
    echo -e "  ${CYAN}delete${NC}  <name>         Permanently remove instance and all worlds"
    echo ""
    echo -e "${BOLD}Information & Config:${NC}"
    echo -e "  ${CYAN}status${NC}                 View dashboard (Instances vs. Active Worlds)"
    echo -e "  ${CYAN}worlds${NC}   <name>        List all worlds stored inside an instance"
    echo -e "  ${CYAN}config${NC}   <name> <k> <v> Edit server.properties for an instance"
    echo -e "  ${CYAN}versions${NC}               List cached server binaries"
    echo -e "  ${CYAN}console${NC}  <name>        Attach to the live server terminal"
    echo ""
    draw_hr
    echo -e "💡 ${YELLOW}Tip:${NC} Drag and drop world files into the terminal to paste their path!"
}

# --- User Interaction ---

confirm_action() {
    echo -en "${YELLOW}${BOLD}${WARN} CONFIRM:${NC} $1 [y/N]: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}
