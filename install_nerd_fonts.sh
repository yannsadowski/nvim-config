#!/usr/bin/env bash

################################################################################
# Nerd Fonts Installation Script for WSL2 / Linux
# 
# This script downloads and installs the most popular Nerd Fonts
# for use with Neovim and modern terminal applications.
#
# Author: Yann
# Date: 2025-11-16
################################################################################

set -e  # Exit on error
set -u  # Treat unset variables as error

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Nerd Fonts version
readonly NERD_FONTS_VERSION="v3.1.1"
readonly NERD_FONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"

# Installation directory
readonly FONTS_DIR="${HOME}/.local/share/fonts"

################################################################################
# Helper Functions
################################################################################

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

print_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

################################################################################
# Font Installation Function
################################################################################

install_nerd_font() {
    local font_name="$1"
    local display_name="$2"
    
    print_info "Installing ${display_name}..."
    
    local font_dir="${FONTS_DIR}/${font_name}"
    local zip_file="${font_name}.zip"
    local download_url="${NERD_FONTS_BASE_URL}/${font_name}.zip"
    
    # Create font directory
    mkdir -p "${font_dir}"
    
    # Download font
    if ! wget -q --show-progress "${download_url}" -O "${zip_file}"; then
        print_error "Failed to download ${display_name}"
        return 1
    fi
    
    # Extract font files
    if ! unzip -q -o "${zip_file}" -d "${font_dir}"; then
        print_error "Failed to extract ${display_name}"
        rm -f "${zip_file}"
        return 1
    fi
    
    # Cleanup
    rm -f "${zip_file}"
    
    print_success "${display_name} installed successfully"
    return 0
}

################################################################################
# Main Installation
################################################################################

main() {
    print_section "Nerd Fonts Installation Script"
    
    # Check for required tools
    if ! command -v wget &> /dev/null; then
        print_error "wget is not installed. Please install it first:"
        echo "  sudo apt update && sudo apt install wget"
        exit 1
    fi
    
    if ! command -v unzip &> /dev/null; then
        print_error "unzip is not installed. Please install it first:"
        echo "  sudo apt update && sudo apt install unzip"
        exit 1
    fi
    
    # Create fonts directory
    print_info "Creating fonts directory: ${FONTS_DIR}"
    mkdir -p "${FONTS_DIR}"
    
    # List of fonts to install
    # Format: "font_filename:Display Name"
    local fonts=(
        "JetBrainsMono:JetBrains Mono Nerd Font (Recommended)"
        "FiraCode:Fira Code Nerd Font"
        "Hack:Hack Nerd Font"
        "CascadiaCode:Cascadia Code Nerd Font"
        "Meslo:Meslo Nerd Font"
    )
    
    print_section "Available Fonts"
    echo "The following Nerd Fonts will be installed:"
    for i in "${!fonts[@]}"; do
        IFS=':' read -r font_file display_name <<< "${fonts[$i]}"
        echo "  $((i+1)). ${display_name}"
    done
    echo ""
    
    read -p "Do you want to install all fonts? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "You can also install fonts individually:"
        echo ""
        for i in "${!fonts[@]}"; do
            IFS=':' read -r font_file display_name <<< "${fonts[$i]}"
            echo "  $((i+1)). ${display_name}"
        done
        echo ""
        read -p "Enter font numbers to install (e.g., '1 3 4' or 'q' to quit): " -r selection
        
        if [[ "$selection" == "q" ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
        
        # Install selected fonts
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#fonts[@]}" ]; then
                idx=$((num-1))
                IFS=':' read -r font_file display_name <<< "${fonts[$idx]}"
                install_nerd_font "${font_file}" "${display_name}"
            fi
        done
    else
        # Install all fonts
        print_section "Installing All Fonts"
        for font_info in "${fonts[@]}"; do
            IFS=':' read -r font_file display_name <<< "${font_info}"
            install_nerd_font "${font_file}" "${display_name}"
        done
    fi
    
    # Refresh font cache
    print_section "Refreshing Font Cache"
    print_info "Updating font cache..."
    fc-cache -fv > /dev/null 2>&1
    print_success "Font cache updated"
    
    # Verify installation
    print_section "Verification"
    print_info "Testing installed fonts..."
    
    if fc-list | grep -i "nerd" > /dev/null; then
        print_success "Nerd Fonts detected in system"
        
        echo ""
        print_info "Installed Nerd Fonts:"
        fc-list | grep -i "nerd" | cut -d: -f2 | sort -u | head -10
    else
        print_warning "No Nerd Fonts detected. You may need to log out and back in."
    fi
    
    # Post-installation instructions
    print_section "Next Steps"
    cat << 'EOF'
1. Configure your terminal to use a Nerd Font:

   Windows Terminal:
   - Open Settings (Ctrl + ,)
   - Go to your WSL2 profile
   - Appearance → Font face → Select "JetBrainsMono Nerd Font"

   Alacritty (~/.config/alacritty/alacritty.yml):
   font:
     normal:
       family: JetBrainsMono Nerd Font

   Kitty (~/.config/kitty/kitty.conf):
   font_family JetBrainsMono Nerd Font

2. Restart your terminal

3. Test the icons:
   echo -e "\ue0b0 \uf113 \uf114 \uf09b"

4. Open Neovim and test:
   nvim
   :lua Snacks.explorer()

For more information, visit:
https://www.nerdfonts.com/
EOF
    
    print_success "Installation complete!"
}

# Run main function
main "$@"
