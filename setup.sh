#!/bin/bash

# Mac Development Environment Setup Script with gum
# Usage: ./setup.sh

set -e

# Colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
INFO='\033[0;34m'
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
            
            printf "${GREEN}✓${NC} Homebrew installed successfully\n"
        else
            printf "${RED}✗ Homebrew is required for this setup. Exiting.${NC}\n"
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
            printf "${GREEN}✓${NC} gum installed successfully\n"
        else
            printf "${RED}✗ gum is required for the interactive setup. Exiting.${NC}\n"
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
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_subdir="$BACKUP_DIR/backup_$timestamp"
    
    gum spin --spinner dot --title "Creating backups" --show-output -- bash -c "
        mkdir -p '$backup_subdir'
        
        GREEN='\\033[0;32m'
        NC='\\033[0m'
        
        log() {
            echo \"\$(date '+%Y-%m-%d %H:%M:%S') - \$1\" >> '$LOG_FILE'
            printf \"%b\\n\" \"\$1\"
        }
        
        printf '\\n'
        
        files_to_backup=('.zshrc' '.gitconfig' '.config')
        
        for file in \"\${files_to_backup[@]}\"; do
            if [[ -e \"\$HOME/\$file\" ]]; then
                cp -r \"\$HOME/\$file\" '$backup_subdir/' 2>/dev/null || true
                log \"\${GREEN}✓\${NC} Backed up: \$file\"
            fi
        done
        
        echo '$backup_subdir' > '$BACKUP_DIR/latest_backup.txt'
        log \"\${GREEN}✓\${NC} Backup created at: $backup_subdir\"
    "
}

# Install Homebrew
install_homebrew() {
    if command -v brew &> /dev/null; then
        log "${GREEN}✓${NC} Homebrew already installed, skipping"
        return 0
    fi
    
    gum spin --spinner dot --title "Installing Homebrew" -- /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
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
        log "${GREEN}✓${NC} Oh My Zsh already installed, skipping"
        return 0
    fi
    
    gum spin --spinner dot --title "Installing Oh My Zsh" -- sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log "${GREEN}Oh My Zsh installed successfully${NC}"
}

# Setup development directory
setup_dev_directory() {
    if [[ -d "$HOME/Development" ]]; then
        log "${GREEN}✓${NC} Development directory already exists, skipping"
        return 0
    fi
    
    log "${INFO}Setting up Development directory...${NC}"
    mkdir -p "$HOME/Development"
    log "${GREEN}Development directory created${NC}"
}

# Install applications via Homebrew
install_apps() {
    # Define all available options with descriptions
    local app_options=(
        "ghostty - A fast native GPU-accelerated terminal emulator"
        "aerospace - i3-like tiling window manager for macOS"
        "wget - Internet file retriever"
        "fzf - Command-line fuzzy finder"
        "fd - Simple fast alternative to find"
        "bat - Cat clone with syntax highlighting"
        "git-delta - Syntax-highlighting pager for git"
        "eza - Modern replacement for ls"
        "thefuck - Corrects errors in previous console commands"
        "zoxide - Smarter cd command"
        "lazydocker - Terminal UI for Docker"
        "gh - GitHub CLI tool"
        "zellij - Terminal multiplexer"
        "serpl - Search and replace tool"
        "yazi - Blazing fast terminal file manager"
        "fzf-git.sh - Git integration for fzf (enhances git workflows)"
    )
    
    # Start with all options selected by default
    local current_selection=$(IFS=','; echo "${app_options[*]}")
    
    while true; do
        # Let user select what they want to install (preserving their last selection)
        local selected_apps
        selected_apps=$(gum choose --no-limit --selected="$current_selection" --height=20 --header "Select applications and tools to install (use space to toggle, enter when done):" "${app_options[@]}")
        
        # Check if user selected anything
        if [[ -z "$selected_apps" ]]; then
            log "${YELLOW}No applications selected, skipping installation${NC}"
            return 0
        fi
        
        # Update current_selection to remember user's choice for potential "go back"
        current_selection=$(echo "$selected_apps" | tr '\n' ',' | sed 's/,$//')
        
        # Show what user selected and ask for confirmation
        printf "\n${INFO}You selected the following tools:${NC}\n"
        while IFS= read -r selected_line; do
            printf "  • %s\n" "$selected_line"
        done <<< "$selected_apps"
        printf "\n"
        
        # Ask for confirmation with options
        local confirmation_choice
        confirmation_choice=$(gum choose "Confirm and install these tools" "Go back to selection" "Skip this step" --header "What would you like to do?")
        
        case "$confirmation_choice" in
            "Confirm and install these tools")
                break
                ;;
            "Go back to selection")
                continue
                ;;
            "Skip this step")
                log "${YELLOW}Skipped applications installation${NC}"
                return 0
                ;;
        esac
    done
    
    printf "\n"
    
    # Run installation with spinner
    gum spin --spinner dot --title "Installing selected tools" --show-output -- bash -c "
        selected_apps='$selected_apps'
        GREEN='\\033[0;32m'
        RED='\\033[0;31m'
        NC='\\033[0m'
        
        log() {
            echo \"\$(date '+%Y-%m-%d %H:%M:%S') - \$1\" >> \"$LOG_FILE\"
            printf \"%b\\n\" \"\$1\"
        }
        
        printf '\\n'
        while IFS= read -r selected_line; do
            app_name=\$(echo \"\$selected_line\" | cut -d' ' -f1)
            
            case \"\$app_name\" in
                \"ghostty\"|\"aerospace\")
                    if brew list --cask \"\$app_name\" &>/dev/null; then
                        log \"\${GREEN}✓\${NC} \$app_name already installed\"
                    else
                        if [[ \"\$app_name\" == \"aerospace\" ]]; then
                            if brew install --cask \"nikitabobko/tap/aerospace\" &>/dev/null; then
                                log \"\${GREEN}✓\${NC} \$app_name installed successfully\"
                            else
                                log \"\${RED}✗ Failed to install \$app_name\${NC}\"
                            fi
                        else
                            if brew install --cask \"\$app_name\" &>/dev/null; then
                                log \"\${GREEN}✓\${NC} \$app_name installed successfully\"
                            else
                                log \"\${RED}✗ Failed to install \$app_name\${NC}\"
                            fi
                        fi
                    fi
                    ;;
                \"fzf-git.sh\")
                    if [[ -d \"\$HOME/Development/fzf-git.sh\" ]]; then
                        log \"\${GREEN}✓\${NC} fzf-git.sh already installed\"
                    else
                        cd \"\$HOME/Development\" 2>/dev/null || mkdir -p \"\$HOME/Development\" && cd \"\$HOME/Development\"
                        if git clone https://github.com/guillermoap/fzf-git.sh &>/dev/null; then
                            log \"\${GREEN}✓\${NC} fzf-git.sh installed successfully\"
                        else
                            log \"\${RED}✗ Failed to install fzf-git.sh\${NC}\"
                        fi
                        cd \"\$HOME\"
                    fi
                    ;;
                *)
                    if brew list \"\$app_name\" &>/dev/null; then
                        log \"\${GREEN}✓\${NC} \$app_name already installed\"
                    else
                        if brew install \"\$app_name\" &>/dev/null; then
                            log \"\${GREEN}✓\${NC} \$app_name installed successfully\"
                        else
                            log \"\${RED}✗ Failed to install \$app_name\${NC}\"
                        fi
                    fi
                    ;;
            esac
        done <<< \"\$selected_apps\"
    "
    
    printf "\n"
    log "${GREEN}Installation of selected applications completed${NC}"
}

# Setup dotfiles
setup_dotfiles() {
    # Check if dotfiles are already set up
    if [[ -d "$DOTFILES_DIR" ]] && [[ -f "$HOME/.zshrc" ]] && grep -q "alias config=" "$HOME/.zshrc" 2>/dev/null; then
        log "${GREEN}✓${NC} Dotfiles already set up, skipping"
        return 0
    fi
    
    if ! gum confirm "Setup dotfiles repository?"; then
        log "${YELLOW}Skipped dotfiles setup${NC}"
        return 0
    fi
    
    log "${INFO}Setting up dotfiles...${NC}"
    
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
        
        printf "\n"
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
    
    log "${INFO}Starting uninstall process...${NC}"
    
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
        "Homebrew:$(command -v brew &>/dev/null && echo "${GREEN}✓${NC} Installed" || echo "${RED}✗${NC} Not installed")"
        "Oh My Zsh:$([ -d "$HOME/.oh-my-zsh" ] && echo "${GREEN}✓${NC} Installed" || echo "${RED}✗${NC} Not installed")"
        "Development Directory:$([ -d "$HOME/Development" ] && echo "${GREEN}✓${NC} Exists" || echo "${RED}✗${NC} Not found")"
        "Dotfiles:$([ -d "$DOTFILES_DIR" ] && echo "${GREEN}✓${NC} Setup" || echo "${RED}✗${NC} Not setup")"
        "fzf-git.sh:$([ -d "$HOME/Development/fzf-git.sh" ] && echo "${GREEN}✓${NC} Cloned" || echo "${RED}✗${NC} Not found")"
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
