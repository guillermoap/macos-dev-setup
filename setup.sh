#!/bin/bash

# Mac Development Environment Setup Script with gum
# Usage: ./setup.sh

set -e

# Colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="$HOME/.dev-setup-backups"
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO="https://github.com/yourusername/dotfiles.git"  # Replace with your dotfiles repo
LOG_FILE="$HOME/.dev-setup.log"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    printf "%b\n" "$1"
}

# Check and setup prerequisites
setup_prerequisites() {
    # Silent check - only show messages if something needs to be installed
    local needs_setup=false
    
    # Check Homebrew
    if ! command -v brew &> /dev/null; then
        needs_setup=true
        printf "${YELLOW}=== Mac Development Setup Prerequisites ===${NC}\n"
        printf "\n"
        printf "This script requires Homebrew and gum to provide an interactive setup experience.\n"
        printf "\n"
        printf "${YELLOW}⚠️  Homebrew is not installed.${NC}\n"
        printf "Homebrew is the package manager for macOS and is required for this setup.\n"
        printf "\n"
        read -p "Would you like to install Homebrew now? (y/N): " -n 1 -r
        printf "\n"
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            printf "${YELLOW}Installing Homebrew...${NC}\n"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH for Apple Silicon Macs
            if [[ $(uname -m) == "arm64" ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            
            printf "${GREEN}✅ Homebrew installed successfully${NC}\n"
        else
            printf "${RED}❌ Homebrew is required for this setup. Exiting.${NC}\n"
            printf "\n"
            printf "To install Homebrew manually, run:\n"
            printf '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"\n'
            exit 1
        fi
    fi
    
    # Check gum
    if ! command -v gum &> /dev/null; then
        if ! $needs_setup; then
            printf "${YELLOW}=== Mac Development Setup Prerequisites ===${NC}\n"
            printf "\n"
            printf "This script requires gum to provide an interactive setup experience.\n"
            printf "\n"
        fi
        needs_setup=true
        printf "${YELLOW}⚠️  gum is not installed.${NC}\n"
        printf "gum provides the interactive interface for this setup script.\n"
        printf "\n"
        read -p "Would you like to install gum now? (y/N): " -n 1 -r
        printf "\n"
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            printf "${YELLOW}Installing gum...${NC}\n"
            brew install gum
            printf "${GREEN}✅ gum installed successfully${NC}\n"
        else
            printf "${RED}❌ gum is required for the interactive setup. Exiting.${NC}\n"
            printf "\n"
            printf "To install gum manually, run:\n"
            printf "brew install gum\n"
            exit 1
        fi
    fi
    
    # Only show completion message if we had to install something
    if $needs_setup; then
        printf "\n"
        printf "${GREEN}🎉 All prerequisites are ready!${NC}\n"
        printf "\n"
        read -p "Press Enter to continue to the main setup menu..."
        printf "\n"
    fi
}

# Backup existing files
backup_files() {
    log "${YELLOW}Creating backups...${NC}"
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_subdir="$BACKUP_DIR/backup_$timestamp"
    mkdir -p "$backup_subdir"
    
    # Files to backup
    local files_to_backup=(
        ".zshrc"
        ".gitconfig"
        ".config"
    )
    
    for file in "${files_to_backup[@]}"; do
        if [[ -e "$HOME/$file" ]]; then
            cp -r "$HOME/$file" "$backup_subdir/" 2>/dev/null || true
            log "Backed up: $file"
        fi
    done
    
    echo "$backup_subdir" > "$BACKUP_DIR/latest_backup.txt"
    log "${GREEN}Backup created at: $backup_subdir${NC}"
}

# Install Homebrew
install_homebrew() {
    if command -v brew &> /dev/null; then
        log "${GREEN}✅ Homebrew already installed, skipping${NC}"
        return 0
    fi
    
    log "${YELLOW}Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    log "${GREEN}Homebrew installed successfully${NC}"
}

# Install Oh My Zsh
install_ohmyzsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log "${GREEN}✅ Oh My Zsh already installed, skipping${NC}"
        return 0
    fi
    
    log "${YELLOW}Installing Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log "${GREEN}Oh My Zsh installed successfully${NC}"
}

# Setup development directory
setup_dev_directory() {
    if [[ -d "$HOME/Development" ]]; then
        log "${GREEN}✅ Development directory already exists, skipping${NC}"
        return 0
    fi
    
    log "${YELLOW}Setting up Development directory...${NC}"
    mkdir -p "$HOME/Development"
    log "${GREEN}Development directory created${NC}"
}

# Install applications via Homebrew
install_apps() {
    log "${YELLOW}Preparing to install applications and development tools...${NC}"
    
    printf "\n${YELLOW}=== APPLICATIONS TO INSTALL ===${NC}\n"
    printf "• ghostty - A fast, native, GPU-accelerated terminal emulator\n"
    printf "• aerospace - i3-like tiling window manager for macOS\n"
    printf "\n${YELLOW}=== CLI DEVELOPMENT TOOLS ===${NC}\n"
    printf "• wget - Internet file retriever\n"
    printf "• fzf - Command-line fuzzy finder\n"
    printf "• fd - Simple, fast alternative to 'find'\n"
    printf "• bat - Cat clone with syntax highlighting\n"
    printf "• git-delta - Syntax-highlighting pager for git\n"
    printf "• eza - Modern replacement for 'ls'\n"
    printf "• thefuck - Corrects errors in previous console commands\n"
    printf "• zoxide - Smarter cd command\n"
    printf "• lazydocker - Terminal UI for Docker\n"
    printf "• gh - GitHub CLI tool\n"
    printf "• zellij - Terminal multiplexer\n"
    printf "• serpl - Search and replace tool\n"
    printf "• yazi - Blazing fast terminal file manager\n"
    printf "\n${YELLOW}=== ADDITIONAL TOOLS ===${NC}\n"
    printf "• fzf-git.sh - Git integration for fzf (enhances git workflows)\n"
    printf "\n"
    
    # Ask for confirmation
    if ! gum confirm "Proceed with automated installation of all these tools?"; then
        log "${YELLOW}Skipped applications installation${NC}"
        return 0
    fi
    
    # Define applications and tools
    local cask_apps=(
        "ghostty"
        "aerospace"
    )
    
    local cli_tools=(
        "wget"
        "fzf"
        "fd"
        "bat"
        "git-delta"
        "eza"
        "thefuck"
        "zoxide"
        "lazydocker"
        "gh"
        "zellij"
        "serpl"
        "yazi"
    )
    
    printf "\n${YELLOW}Starting automated installation...${NC}\n\n"
    
    # Install GUI applications
    printf "${YELLOW}Installing GUI applications...${NC}\n"
    for app in "${cask_apps[@]}"; do
        if brew list --cask "$app" &>/dev/null; then
            log "${GREEN}✅ $app already installed${NC}"
        else
            log "${YELLOW}Installing $app...${NC}"
            if [[ "$app" == "aerospace" ]]; then
                brew install --cask "nikitabobko/tap/aerospace" || log "${RED}Failed to install $app${NC}"
            else
                brew install --cask "$app" || log "${RED}Failed to install $app${NC}"
            fi
        fi
    done
    
    # Install CLI tools
    printf "\n${YELLOW}Installing CLI tools...${NC}\n"
    for tool in "${cli_tools[@]}"; do
        if brew list "$tool" &>/dev/null; then
            log "${GREEN}✅ $tool already installed${NC}"
        else
            log "${YELLOW}Installing $tool...${NC}"
            brew install "$tool" || log "${RED}Failed to install $tool${NC}"
        fi
    done
    
    # Install fzf-git.sh
    printf "\n${YELLOW}Installing additional development tools...${NC}\n"
    if [[ -d "$HOME/Development/fzf-git.sh" ]]; then
        log "${GREEN}✅ fzf-git.sh already installed${NC}"
    else
        log "${YELLOW}Installing fzf-git.sh...${NC}"
        cd "$HOME/Development" 2>/dev/null || mkdir -p "$HOME/Development" && cd "$HOME/Development"
        git clone https://github.com/guillermoap/fzf-git.sh || log "${RED}Failed to install fzf-git.sh${NC}"
        cd "$HOME"
    fi
    
    log "\n${GREEN}Applications installation completed${NC}"
}

# Setup dotfiles
setup_dotfiles() {
    # Check if dotfiles are already set up
    if [[ -d "$DOTFILES_DIR" ]] && [[ -f "$HOME/.zshrc" ]] && grep -q "alias config=" "$HOME/.zshrc" 2>/dev/null; then
        log "${GREEN}✅ Dotfiles already set up, skipping${NC}"
        return 0
    fi
    
    if ! gum confirm "Setup dotfiles repository?"; then
        log "${YELLOW}Skipped dotfiles setup${NC}"
        return 0
    fi
    
    log "${YELLOW}Setting up dotfiles...${NC}"
    
    # Prompt for dotfiles repository URL if not set
    if [[ "$DOTFILES_REPO" == "https://github.com/yourusername/dotfiles.git" ]]; then
        DOTFILES_REPO=$(gum input --placeholder "Enter your dotfiles repository URL")
        if [[ -z "$DOTFILES_REPO" ]]; then
            log "${RED}No repository URL provided, skipping dotfiles setup${NC}"
            return 1
        fi
    fi
    
    # Create dotfiles directory if it doesn't exist
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
    fi
    
    # Create the config alias function
    config() {
        /usr/bin/git --git-dir="$DOTFILES_DIR/.git/" --work-tree="$HOME" "$@"
    }
    
    # Try to checkout dotfiles
    if config checkout; then
        log "${GREEN}Dotfiles checked out successfully${NC}"
    else
        log "${YELLOW}Dotfiles checkout failed, likely due to existing files${NC}"
        
        if gum confirm "Remove conflicting files and try again?"; then
            config checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | xargs -I{} rm -f "$HOME/{}"
            config checkout
            log "${GREEN}Dotfiles checked out after removing conflicts${NC}"
        fi
    fi
    
    # Set git config for dotfiles
    config config --local status.showUntrackedFiles no
    
    # Add alias to shell config
    local shell_config=""
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_config="$HOME/.bashrc"
    fi
    
    if [[ -n "$shell_config" ]] && ! grep -q "alias config=" "$shell_config"; then
        echo 'alias config="/usr/bin/git --git-dir=$HOME/.dotfiles/.git/ --work-tree=$HOME"' >> "$shell_config"
        log "Added config alias to $shell_config"
    fi
    
    log "${GREEN}Dotfiles setup completed${NC}"
}

# Main installation function
install_all() {
    gum style --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'Mac Development Setup' 'Starting installation...'
    
    backup_files
    
    # Installation steps
    local steps=(
        "install_homebrew:Install Homebrew"
        "install_ohmyzsh:Install Oh My Zsh"
        "setup_dev_directory:Setup Development Directory" 
        "install_apps:Install Applications & Tools"
        "setup_dotfiles:Setup Dotfiles"
    )
    
    for step in "${steps[@]}"; do
        local func="${step%%:*}"
        local desc="${step##*:}"
        
        if gum confirm "Proceed with: $desc?"; then
            eval "$func"
        else
            log "${YELLOW}Skipped: $desc${NC}"
        fi
    done
    
    gum style --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'Installation Complete!' 'Please restart your terminal or run: source ~/.zshrc'
}

# Uninstall function
uninstall_all() {
    gum style --foreground 196 --border-foreground 196 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'Uninstall Development Setup' 'This will remove installed components'
    
    if ! gum confirm "Are you sure you want to uninstall everything?"; then
        log "Uninstall cancelled"
        return 0
    fi
    
    log "${YELLOW}Starting uninstall process...${NC}"
    
    # Restore from latest backup
    if [[ -f "$BACKUP_DIR/latest_backup.txt" ]]; then
        local latest_backup=$(cat "$BACKUP_DIR/latest_backup.txt")
        if [[ -d "$latest_backup" ]] && gum confirm "Restore files from backup?"; then
            log "Restoring from backup: $latest_backup"
            cp -r "$latest_backup"/. "$HOME/" 2>/dev/null || true
            log "${GREEN}Files restored from backup${NC}"
        fi
    fi
    
    # Remove installed components
    if gum confirm "Remove Homebrew and all installed packages?"; then
        log "Removing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" || true
    fi
    
    if gum confirm "Remove Oh My Zsh?"; then
        log "Removing Oh My Zsh..."
        rm -rf "$HOME/.oh-my-zsh" 2>/dev/null || true
    fi
    
    if gum confirm "Remove Development directory?"; then
        log "Removing Development directory..."
        rm -rf "$HOME/Development" 2>/dev/null || true
    fi
    
    if gum confirm "Remove dotfiles repository?"; then
        log "Removing dotfiles..."
        rm -rf "$DOTFILES_DIR" 2>/dev/null || true
    fi
    
    log "${GREEN}Uninstall completed${NC}"
}

# Show status
show_status() {
    gum style --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'Development Environment Status'
    
    local components=(
        "Homebrew:$(command -v brew &>/dev/null && echo "✅ Installed" || echo "❌ Not installed")"
        "Oh My Zsh:$([ -d "$HOME/.oh-my-zsh" ] && echo "✅ Installed" || echo "❌ Not installed")"
        "Development Directory:$([ -d "$HOME/Development" ] && echo "✅ Exists" || echo "❌ Not found")"
        "Dotfiles:$([ -d "$DOTFILES_DIR" ] && echo "✅ Setup" || echo "❌ Not setup")"
        "fzf-git.sh:$([ -d "$HOME/Development/fzf-git.sh" ] && echo "✅ Cloned" || echo "❌ Not found")"
    )
    
    for component in "${components[@]}"; do
        local name="${component%%:*}"
        local status="${component##*:}"
        printf "%-20s %s\n" "$name:" "$status"
    done
    
    printf "\n"
    if [[ -f "$BACKUP_DIR/latest_backup.txt" ]]; then
        local latest_backup=$(cat "$BACKUP_DIR/latest_backup.txt")
        printf "Latest backup: %s\n" "$(basename "$latest_backup")"
    else
        printf "No backups found\n"
    fi
}

# Main script logic
main() {
    setup_prerequisites
    
    # Always start with interactive menu after prerequisites
    local choice=$(gum choose "Install Development Environment" "Uninstall Everything" "Show Status" "Exit")
    case "$choice" in
        "Install Development Environment")
            install_all
            ;;
        "Uninstall Everything")
            uninstall_all
            ;;
        "Show Status")
            show_status
            ;;
        "Exit")
            log "Goodbye!"
            exit 0
            ;;
    esac
}

# Run main function
main
