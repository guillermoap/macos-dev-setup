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

# Logging and status functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    printf "%b\n" "$1"
}

log_success() {
    log "${GREEN}✓${NC} $1"
}

log_error() {
    log "${RED}✗${NC} $1"
}

log_info() {
    log "${INFO}$1${NC}"
}

log_warning() {
    log "${YELLOW}$1${NC}"
}

log_skip() {
    log "${YELLOW}Skipped: $1${NC}"
}

# Check if command/app already installed
is_installed() {
    local app_name="$1"
    local install_type="${2:-formula}" # formula, cask, or directory
    
    case "$install_type" in
        "cask")
            brew list --cask "$app_name" &>/dev/null
            ;;
        "directory")
            [[ -d "$app_name" ]]
            ;;
        *)
            brew list "$app_name" &>/dev/null
            ;;
    esac
}

# Install with spinner and status
install_with_spinner() {
    local title="$1"
    local command="$2"
    local success_msg="$3"
    local error_msg="${4:-Failed to install}"
    
    if gum spin --spinner dot --title "$title" --show-output -- bash -c "$command"; then
        log_success "$success_msg"
        return 0
    else
        log_error "$error_msg"
        return 1
    fi
}

# Install a single app with proper handling
install_app() {
    local app_name="$1"
    local install_type="$2" # cask, formula, or special
    local special_cmd="$3"   # for special installations
    
    case "$install_type" in
        "cask")
            if is_installed "$app_name" "cask"; then
                log_success "$app_name already installed"
            else
                local cmd="brew install --cask \"$app_name\""
                install_with_spinner "Installing $app_name" "$cmd" "$app_name installed successfully" "Failed to install $app_name"
            fi
            ;;
        "special")
            eval "$special_cmd"
            ;;
        *)
            if is_installed "$app_name" "formula"; then
                log_success "$app_name already installed"
            else
                local cmd="brew install \"$app_name\""
                install_with_spinner "Installing $app_name" "$cmd" "$app_name installed successfully" "Failed to install $app_name"
            fi
            ;;
    esac
}

# Check and setup prerequisites
# We have to use printf since gum might not be installed
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
        log_success "Homebrew already installed, skipping"
        return 0
    fi
    
    local install_cmd="/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    
    if install_with_spinner "Installing Homebrew" "$install_cmd" "Homebrew installed successfully"; then
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

# Install Oh My Zsh
install_ohmyzsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh My Zsh already installed, skipping"
        return 0
    fi
    
    local install_cmd="sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended"
    install_with_spinner "Installing Oh My Zsh" "$install_cmd" "Oh My Zsh installed successfully"
}

# Setup development directory
setup_dev_directory() {
    if [[ -d "$HOME/Development" ]]; then
        log_success "Development directory already exists, skipping"
        return 0
    fi
    
    log_info "Setting up Development directory"
    mkdir -p "$HOME/Development"
    log_success "Development directory created"
}

# Install applications via Homebrew
install_apps() {
    # Define all available options with descriptions
    local app_options=(
        "aerospace        - i3-like tiling window manager for macOS"
        "bat              - Cat clone with syntax highlighting"
        "brave-browser    - Privacy focused browser"
        "btop             - Terminal based resource monitor"
        "datagrip         - Database and SQL IDE"
        "eza              - Modern replacement for ls"
        "fd               - Simple fast alternative to find"
        "fzf              - Command-line fuzzy finder"
        "fzf-git.sh       - Git integration for fzf (enhances git workflows)"
        "gh               - GitHub CLI tool"
        "ghostty          - A fast native GPU-accelerated terminal emulator"
        "git-delta        - Syntax-highlighting pager for git"
        "hey-desktop      - Opinionated email & calendar service"
        "lazydocker       - Terminal UI for Docker"
        "mise             - Development environment manager (replaces asdf, nvm, etc.)"
        "sst/tap/opencode - AI coding agent built for the terminal"
        "serpl            - Search and replace tool"
        "spotify          - Music streaming service"
        "thefuck          - Corrects errors in previous console commands"
        "wget             - Internet file retriever"
        "yazi             - Blazing fast terminal file manager"
        "zellij           - Terminal multiplexer"
        "zoxide           - Smarter cd command"
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
    
    # Separate apps into categories for batch installation
    local cask_apps=()
    local formula_apps=()
    
    while IFS= read -r selected_line; do
        local app_name=$(echo "$selected_line" | cut -d' ' -f1)
        
        case "$app_name" in
            "ghostty"|"aerospace"|"brave-browser"|"hey-desktop"|"datagrip"|"spotify")
                if ! is_installed "$app_name" "cask"; then
                    # Map app names to their brew identifiers
                    case "$app_name" in
                        "aerospace") cask_apps+=("nikitabobko/tap/aerospace") ;;
                        *) cask_apps+=("$app_name") ;;
                    esac
                else
                    log_success "$app_name already installed"
                fi
                ;;
            "fzf-git.sh")
                if [[ ! -d "$HOME/Development/fzf-git.sh" ]]; then
                    mkdir -p "$HOME/Development"
                    cd "$HOME/Development"
                    install_with_spinner "Installing fzf-git.sh" "git clone https://github.com/guillermoap/fzf-git.sh" "fzf-git.sh installed successfully" "Failed to install fzf-git.sh"
                    cd "$HOME"
                else
                    log_success "fzf-git.sh already installed"
                fi
                ;;
            *)
                if ! is_installed "$app_name" "formula"; then
                    formula_apps+=("$app_name")
                else
                    log_success "$app_name already installed"
                fi
                ;;
        esac
    done <<< "$selected_apps"
    
    # Batch install cask apps
    if [[ ${#cask_apps[@]} -gt 0 ]]; then
        local cask_list=$(IFS=' '; echo "${cask_apps[*]}")
        install_with_spinner "Installing cask apps" "brew install --cask ${cask_list}" "Cask apps installed successfully" "Failed to install some cask apps"
    fi
    
    # Batch install formula apps  
    if [[ ${#formula_apps[@]} -gt 0 ]]; then
        local formula_list=$(IFS=' '; echo "${formula_apps[*]}")
        install_with_spinner "Installing formula apps" "brew install ${formula_list}" "Formula apps installed successfully" "Failed to install some formula apps"
    fi
    
    printf "\n"
    log_success "Installation of selected applications completed"
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
            log_skip "$desc"
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
