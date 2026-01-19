# bence-drimus's Dotfiles

![Shell](https://img.shields.io/badge/Shell-Bash-blue)![OS](https://img.shields.io/badge/OS-Arch%20Linux-blueviolet)

This repository contains my personal dotfiles and a script to automate their installation on a new Arch-based Linux system. The goal is to have a simple, modular, and easily expandable setup that can be deployed with a single command.

## Prerequisites

This setup is specifically designed for **Arch Linux** and its derivatives (like Manjaro, EndeavourOS, etc.) that use `pacman` as their package manager.

## Quick Installation

You can install these dotfiles directly from this repository using the `curl` command below. This method downloads and executes the `install.sh` script without cloning the repository.

```bash
curl -sS https://raw.githubusercontent.com/bence-drimus/dotfiles/main/install.sh | bash
```

## Usage

The installation script is designed to be flexible. You can choose to install everything at once or only specific parts.

### Command-Line Options

*   **No options**: Installs both configuration files and the default packages from `pkglist.txt`.
    ```bash
    curl -sS https://raw.githubusercontent.com/bence-drimus/dotfiles/main/install.sh | bash
    ```

*   `-c`, `--configs`: Installs only the configuration files.
    ```bash
    curl -sS https://raw.githubusercontent.com/bence-drimus/dotfiles/main/install.sh | bash -s -- -c
    ```

*   `-p`, `--packages [type]`: Installs only the packages.
    *   If no `[type]` is specified, it installs packages from the default `pkglist.txt`.
        ```bash
        curl -sS https://raw.githubusercontent.com/bence-drimus/dotfiles/main/install.sh | bash -s -- -p
        ```
    *   You can specify a type (e.g., `laptop`, `desktop`) to install from a corresponding package list (e.g., `pkglist-laptop.txt`).
        ```bash
        # This requires a 'pkglist-laptop.txt' file in the repository
        curl -sS https://raw.githubusercontent.com/bence-drimus/dotfiles/main/install.sh | bash -s -- -p laptop
        ```

*   `-h`, `--help`: Displays the help message with all available options.
    ```bash
    curl -sS https://raw.githubusercontent.com/bence-drimus/dotfiles/main/install.sh | bash -s -- -h
    ```

## Repository Structure

*   `install.sh`: The main installation script. It handles command-line arguments, downloads configs, and installs packages.
*   `i3/`: This directory contains configuration files for the i3 window manager.
    *   `config`: The main i3 configuration file.
    *   `i3status.conf`: Configuration for the i3 status bar.
*   `pkglist.txt`: A list of essential packages to be installed by default.
*   `README.md`: This file.

## How to Customize and Extend

This setup is designed to be easily expanded.

### Adding New Configuration Files

1.  Place your new configuration files in a logical directory structure (e.g., create a `kitty/` directory for a Kitty terminal configuration).
2.  Open the `install.sh` script and navigate to the `install_configs` function.
3.  Add the necessary commands to download your new files into the correct locations in the `$HOME` directory. For example, to add a `kitty.conf` file:

    ```bash
    # --- Inside the install_configs function ---

    # Create directory for Kitty
    mkdir -p "$CONFIG_DIR/kitty"

    # Download and install kitty.conf
    if curl -sS --fail "$REPO_URL/kitty/kitty.conf" -o "$CONFIG_DIR/kitty/kitty.conf"; then
        print_success "kitty.conf installed."
    else
        print_error "Failed to download kitty.conf."
        return 1
    fi
    ```

### Adding New Package Lists

You can create multiple package lists for different setups (e.g., a minimal setup, a full development environment, a laptop-specific setup, etc.).

1.  Create a new file in the root of the repository named `pkglist-<type>.txt`, where `<type>` is a name of your choice (e.g., `pkglist-desktop.txt`).
2.  Add the names of the packages you want in this file, one package per line.
3.  You can now install this list by running the installation script with the `-p <type>` option.
