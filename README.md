# macOS Development Environment Setup

An interactive bash script that automates the setup of a comprehensive development environment on macOS using [gum](https://github.com/charmbracelet/gum) for a beautiful terminal UI.

## ✨ Features

### 🛠️ Development Tools
- **Homebrew** - macOS package manager
- **Oh My Zsh** - Enhanced shell experience with themes and plugins
- **Development Applications** - Choose from popular tools like:
  - `ghostty` - GPU-accelerated terminal emulator
  - `aerospace` - i3-like tiling window manager
  - `fzf` - Command-line fuzzy finder
  - `fd`, `bat`, `eza` - Modern replacements for find, cat, ls
  - `lazydocker` - Terminal UI for Docker
  - `gh` - GitHub CLI
  - And many more...

### 🔧 System Setup
- **Development Directory** - Creates `~/Development` folder structure
- **Dotfiles Management** - Optional setup with bare git repository approach
- **Configuration Backup** - Automatically backs up existing configs

## 🚀 Quick Start

### One-Line Remote Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/guillermoap/macos-dev-setup/main/setup.sh)
```

### Local Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/guillermoap/macos-dev-setup.git
   cd macos-dev-setup
   ```

2. **Make the script executable:**
   ```bash
   chmod +x setup.sh
   ```

3. **Run the setup:**
   ```bash
   ./setup.sh
   ```

## 🔧 Configuration

### Dotfiles Integration
If you have a dotfiles repository, you can integrate it:

1. Update the `DOTFILES_REPO` variable in the script:
   ```bash
   DOTFILES_REPO="https://github.com/yourusername/dotfiles.git"
   ```

2. Or enter it interactively when prompted during setup

The script uses the "bare repository" method for dotfiles management, creating a `config` command for managing your dotfiles.

### Customization
You can easily modify the script to add or remove applications:

1. **Add applications** to the `app_options` array in the `install_apps()` function
2. **Categorize them** as cask, formula, or special installation in the installation logic
3. **Update prerequisites** if needed in the `setup_prerequisites()` function

## 🗑️ Uninstallation

The script provides a complete uninstallation option that:
- Restores files from the latest backup
- Removes Homebrew and all installed packages
- Removes Oh My Zsh
- Removes the Development directory
- Removes dotfiles repository

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs or issues
- Suggest new tools to include
- Improve the documentation
- Submit pull requests

## 📄 License

This project is open source and available under the MIT License.