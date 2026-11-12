#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Variables ---
REPO_URL="https://raw.githubusercontent.com/BDrimus/dotfiles/main"
CONFIG_DIR="$HOME/.config"

# --- Functions ---

# Function to print colored output
print_info() {
    printf "\n\e[1;34m%s\e[0m\n" "$1"
}

print_success() {
    printf "\e[1;32m%s\e[0m\n" "$1"
}

print_error() {
    printf "\e[1;31m%s\e[0m\n" "$1" >&2
}

# Function to install configuration files
install_configs() {
    print_info "Installing configuration files..."

    # Create directories if they don't exist
    mkdir -p "$CONFIG_DIR/i3"
    mkdir -p "$CONFIG_DIR/i3status"

    # Download and install i3 config
    if curl -sS --fail "$REPO_URL/i3/config" -o "$CONFIG_DIR/i3/config"; then
        print_success "i3 config installed."
    else
        print_error "Failed to download i3 config."
        return 1
    fi

    # Download and install i3status config
    if curl -sS --fail "$REPO_URL/i3/i3status/config" -o "$CONFIG_DIR/i3status/config"; then
        print_success "i3status config installed."
    else
        print_error "Failed to download i3status config."
        return 1
    fi

    # Hyprland and lock screen (local.lua stays per machine, so it is not here)
    mkdir -p "$CONFIG_DIR/hypr"
    for f in hyprland.lua hyprlock.conf; do
        if ! curl -sS --fail "$REPO_URL/hyprland/$f" -o "$CONFIG_DIR/hypr/$f"; then
            print_error "Failed to download $f."
            return 1
        fi
    done
    # Starts dark like the theme below; darkman repoints it at sunrise and sunset
    ln -sfn "$HOME/Prog/dotfiles/hyprland/hyprlock-colours-dark.conf" "$CONFIG_DIR/hypr/hyprlock-colours.conf"
    print_success "Hyprland config installed."

    # Notifications, linked into the repo like darkman; colours start dark and darkman switches them
    mkdir -p "$CONFIG_DIR/dunst/dunstrc.d"
    ln -sfn "$HOME/Prog/dotfiles/dunst/dunstrc" "$CONFIG_DIR/dunst/dunstrc"
    ln -sfn "$HOME/Prog/dotfiles/dunst/colours-dark.conf" "$CONFIG_DIR/dunst/dunstrc.d/colours.conf"
    print_success "dunst config installed."

    # Vesktop rewrites its settings file, so it gets a copy rather than a link
    mkdir -p "$CONFIG_DIR/vesktop"
    if curl -sS --fail "$REPO_URL/vesktop/settings.json" -o "$CONFIG_DIR/vesktop/settings.json"; then
        print_success "Vesktop settings installed."
    else
        print_error "Failed to download Vesktop settings."
        return 1
    fi

    # The rest are links into a clone of this repo, so edits there apply straight away
    [ -d "$HOME/Prog/dotfiles" ] || git clone https://github.com/bence-drimus/dotfiles.git "$HOME/Prog/dotfiles"
    for f in alacritty/alacritty.toml fontconfig/fonts.conf gtk-3.0/settings.ini gtk-4.0/settings.ini \
             kitty/kitty.conf kitty/dark-theme.auto.conf kitty/light-theme.auto.conf \
             waybar/config.jsonc waybar/style.css waybar/media.py waybar/power_menu.xml \
             wofi/config wofi/style.css; do
        mkdir -p "$CONFIG_DIR/$(dirname "$f")"
        ln -sfn "$HOME/Prog/dotfiles/$f" "$CONFIG_DIR/$f"
    done
    # Colours start dark; darkman switches them at sunrise and sunset
    ln -sfn "$HOME/Prog/dotfiles/alacritty/colours-dark.toml" "$CONFIG_DIR/alacritty/colours.toml"
    for app in waybar wofi; do
        ln -sfn "$HOME/Prog/dotfiles/theme/colours-dark.css" "$CONFIG_DIR/$app/colours.css"
    done
    print_success "Alacritty, kitty, fonts, GTK, waybar and wofi configs linked."

    # Dark theme for GTK and Electron apps (stored in dconf, so not a file here)
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface accent-color 'orange'
    gsettings set org.gnome.desktop.interface gtk-theme 'Colloid-Orange-Dark-Gruvbox'
    gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
    gsettings set org.gnome.desktop.interface cursor-theme 'macOS'
    gsettings set org.gnome.desktop.interface font-name 'Inter 11'
    print_success "Dark theme set."

    # Day/night theme: darkman runs darkman/theme at sunrise and sunset (expects this repo at ~/Prog/dotfiles)
    for mode in light dark; do
        mkdir -p "$HOME/.local/share/$mode-mode.d"
        ln -sfn "$HOME/Prog/dotfiles/darkman/theme" "$HOME/.local/share/$mode-mode.d/theme"
    done
    systemctl --user add-wants graphical-session.target darkman.service
    print_success "Day/night theme set."
}

# Function to install packages
install_packages() {
    local package_list_type=$1
    local package_file="pkglist.txt"

    if [[ -n "$package_list_type" ]]; then
        package_file="pkglist-${package_list_type}.txt"
    fi

    print_info "Installing packages from $package_file..."

    # Download the package list
    if ! curl -sS --fail "$REPO_URL/$package_file" -o "/tmp/$package_file"; then
        print_error "Failed to download package list: $package_file"
        print_error "Please make sure the file exists in the repository."
        return 1
    fi

    # Read the package list and install packages
    if [[ -f "/tmp/$package_file" ]]; then
        # Update package database
        sudo pacman -Syu --noconfirm

        # Install packages
        grep -v '^#' "/tmp/$package_file" | xargs sudo pacman -S --noconfirm --needed
        print_success "Packages installed successfully."
        rm "/tmp/$package_file"
    else
        print_error "Package list not found."
        return 1
    fi
}

# --- Main Logic ---
main() {
    local install_c=false
    local install_p=false
    local package_type=""

    if [[ $# -eq 0 ]]; then
        install_c=true
        install_p=true
    else
        while [[ "$#" -gt 0 ]]; do
            case $1 in
                -c|--configs) install_c=true; shift ;;
                -p|--packages)
                    install_p=true
                    if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                        package_type="$2"
                        shift
                    fi
                    shift
                    ;;
                -h|--help)
                    printf "Usage: %s [-c] [-p [type]] [-h]\n" "$0"
                    printf "  -c, --configs       Install configuration files\n"
                    printf "  -p, --packages [type] Install packages from a list (e.g., 'laptop', 'desktop')\n"
                    printf "                      If no type is specified, it uses the default 'pkglist.txt'.\n"
                    printf "  -h, --help          Show this help message\n"
                    exit 0
                    ;;
                *) print_error "Unknown option: $1"; exit 1 ;;
            esac
        done
    fi

    if "$install_c"; then
        install_configs
    fi

    if "$install_p"; then
        install_packages "$package_type"
    fi

    print_success "All requested operations completed."
}

main "$@"
