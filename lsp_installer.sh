#!/usr/bin/env bash

################################################################################
# Neovim LSP Configuration Setup Script
# 
# This script automates the installation of:
# 1. nvim-lspconfig plugin
# 2. Package managers (Homebrew, uv, Rust)
# 3. Language servers for multiple languages
#
# Author: Yann
# Date: 2025-11-14
################################################################################

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error
set -o pipefail  # Return value of a pipeline is the status of the last command to exit with a non-zero status

# Color codes for better output readability
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

################################################################################
# Helper Functions
################################################################################

# Print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Print section headers
print_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if installation was successful
check_installation() {
    if command_exists "$1"; then
        print_success "$1 is now available"
        return 0
    else
        print_error "$1 installation failed or not in PATH"
        return 1
    fi
}

################################################################################
# Step 1: Clone nvim-lspconfig
################################################################################

install_nvim_lspconfig() {
    print_section "Step 1: Installing nvim-lspconfig"
    
    local target_dir="${HOME}/.config/nvim/pack/nvim/start/nvim-lspconfig"
    
    if [ -d "$target_dir" ]; then
        print_warning "nvim-lspconfig already exists at $target_dir"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Updating nvim-lspconfig..."
            cd "$target_dir" && git pull
            print_success "nvim-lspconfig updated"
        else
            print_info "Skipping nvim-lspconfig installation"
        fi
    else
        print_info "Cloning nvim-lspconfig..."
        mkdir -p "$(dirname "$target_dir")"
        git clone https://github.com/neovim/nvim-lspconfig "$target_dir"
        print_success "nvim-lspconfig installed to $target_dir"
    fi
}

################################################################################
# Step 2: Install Package Managers
################################################################################

install_homebrew() {
    print_section "Step 2.1: Installing Homebrew"
    
    if command_exists brew; then
        print_warning "Homebrew is already installed"
        brew --version
    else
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for the current session
        # This handles both Linux and macOS installations
        if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        check_installation brew
    fi
}

install_uv() {
    print_section "Step 2.2: Installing uv (Astral)"
    
    if command_exists uv; then
        print_warning "uv is already installed"
        uv --version
    else
        print_info "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        
        # Add uv to PATH for the current session
        export PATH="${HOME}/.cargo/bin:${PATH}"
        
        check_installation uv
    fi
}

install_rust() {
    print_section "Step 2.3: Installing Rust"
    
    if command_exists rustc && command_exists cargo; then
        print_warning "Rust is already installed"
        rustc --version
        cargo --version
    else
        print_info "Installing Rust..."
        curl https://sh.rustup.rs -sSf | sh -s -- -y
        
        # Source cargo environment for the current session
        source "${HOME}/.cargo/env" 2>/dev/null || true
        
        check_installation rustc
        check_installation cargo
    fi
}

################################################################################
# Step 3: Install Language Servers
################################################################################

install_lsp_servers() {
    print_section "Step 3: Installing Language Servers"
    
    # Ensure npm is available (comes with Node.js)
    if ! command_exists npm; then
        print_error "npm is not installed. Please install Node.js first."
        print_info "Visit: https://nodejs.org/ or use: brew install node"
        return 1
    fi
    
    # Array of LSP servers to install
    # Format: "command:installation_method:package_name:description"
    local lsp_servers=(
        "basedpyright:npm:basedpyright:Python LSP (Pyright fork)"
        "bash-language-server:npm:bash-language-server:Bash LSP"
        "lua-language-server:brew:lua-language-server:Lua LSP"
        "marksman:brew:marksman:Markdown LSP"
        "nixd:nix:nixd:Nix LSP"
        "texlab:brew:texlab:LaTeX LSP"
        "tinymist:cargo:tinymist:Typst LSP"
        "ty:uvx:ty:Additional Typst tool"
    )
    
    for server_info in "${lsp_servers[@]}"; do
        IFS=':' read -r command method package description <<< "$server_info"
        
        print_info "Installing $description ($command)..."
        
        if command_exists "$command"; then
            print_warning "$command is already installed"
            continue
        fi
        
        case "$method" in
            npm)
                if [ "$package" == "bash-language-server"  &&  "$package" == "basedpyright" ]; then
                    npm install -g "$package"
                else
                    npm install "$package"
                fi
                ;;
            brew)
                brew install "$package"
                ;;
            nix)
                if ! command_exists nix; then
                    print_error "Nix is not installed. Skipping nixd installation."
                    print_info "To install Nix, visit: https://nixos.org/download.html"
                    continue
                fi
                nix profile install "github:nix-community/${package}"
                ;;
            cargo)
                if [ "$package" == "tinymist" ]; then
                    cargo install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli
                else
                    cargo install "$package"
                fi
                ;;
            uvx)
                uvx "$package"
                ;;
        esac
        
        # Verify installation
        if check_installation "$command"; then
            print_success "$description installed successfully"
        else
            print_warning "$description may not be in PATH yet. Restart your shell or source your profile."
        fi
    done
}

################################################################################
# Post-Installation Steps
################################################################################

post_install_info() {
    print_section "Installation Complete!"
    
    cat << 'EOF'
Next steps:

1. Restart your terminal or source your shell profile:
   source ~/.bashrc    # or ~/.zshrc for zsh

2. Verify installations:
   - nvim --version
   - brew --version
   - uv --version
   - cargo --version

3. Check LSP servers:
   - basedpyright --version
   - bash-language-server --version
   - lua-language-server --version
   - marksman --version
   - texlab --version
   - tinymist --version

4. Configure Neovim to use these LSP servers in your init.lua:
   - Add LSP configurations in ~/.config/nvim/init.lua
   - Example: require('lspconfig').basedpyright.setup{}

5. Optional: Add these paths to your shell profile if not already present:
   export PATH="$HOME/.cargo/bin:$PATH"
   export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"  # Linux
   export PATH="/opt/homebrew/bin:$PATH"               # macOS

For more information on configuring LSP servers, visit:
https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
EOF
}

################################################################################
# Main Execution
################################################################################

main() {
    print_section "Neovim LSP Setup Script"
    
    print_info "This script will install:"
    echo "  - nvim-lspconfig plugin"
    echo "  - Package managers (Homebrew, uv, Rust)"
    echo "  - Language servers for Python, Bash, Lua, Markdown, Nix, LaTeX, and Typst"
    echo
    
    read -p "Do you want to proceed? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled by user"
        exit 0
    fi
    
    # Execute installation steps
    install_nvim_lspconfig
    install_homebrew
    install_uv
    install_rust
    install_lsp_servers
    post_install_info
    
    print_success "All installations completed successfully!"
}

# Run main function
main "$@"
