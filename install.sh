#!/bin/bash

# install.sh - Script to install dependencies and clone dwmpanel for multiple Linux distributions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print messages
print_msg() {
    echo -e "${2}[*] $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect the Linux distribution
detect_distro() {
    DISTRO=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    elif [ -f /etc/gentoo-release ]; then
        DISTRO="gentoo"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/SuSE-release ]; then
        DISTRO="suse"
    elif [ -f /etc/slackware-version ]; then
        DISTRO="slackware"
    elif [ -f /etc/lfs-release ]; then
        DISTRO="lfs"
    else
        print_msg "Could not detect the distribution. Please specify manually." "${RED}"
        exit 1
    fi
    print_msg "Detected distribution: $DISTRO" "${GREEN}"
}

# Function to prompt for skipping dependency installation
prompt_skip_install() {
    print_msg "Dependencies required: git make gcc libx11 libxft libxinerama fontconfig" "${YELLOW}"
    print_msg "Would you like to install these dependencies? (Y/n): " "${YELLOW}"
    read -r response
    if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
        print_msg "Skipping dependency installation as requested." "${YELLOW}"
        return 1
    fi
    return 0
}

# Function to install dependencies based on the distribution
install_dependencies() {
    # Skip installation if user chose to
    if ! prompt_skip_install; then
        return 0
    fi

    print_msg "Installing dependencies for $DISTRO..." "${YELLOW}"

    case $DISTRO in
        "debian" | "Ubuntu" | "linuxmint")
            # Debian-based systems (Debian, Ubuntu, Linux Mint)
            PKG_MANAGER="apt"
            PKG_UPDATE="apt update"
            PKG_INSTALL="apt install -y"
            DEPENDENCIES="git make gcc libx11-dev libxft-dev libxinerama-dev fontconfig"
            ;;
        "arch" | "manjaro")
            # Arch-based systems (Arch, Manjaro)
            PKG_MANAGER="pacman"
            PKG_UPDATE="pacman -Syu --noconfirm"
            PKG_INSTALL="pacman -S --noconfirm"
            DEPENDENCIES="git make gcc libx11 libxft libxinerama fontconfig"
            ;;
        "fedora")
            # Fedora
            PKG_MANAGER="dnf"
            PKG_UPDATE="dnf update -y"
            PKG_INSTALL="dnf install -y"
            DEPENDENCIES="git make gcc libX11-devel libXft-devel libXinerama-devel fontconfig"
            ;;
        "gentoo")
            # Gentoo
            PKG_MANAGER="emerge"
            PKG_UPDATE="emerge --sync"
            PKG_INSTALL="emerge -q"
            DEPENDENCIES="dev-vcs/git sys-devel/make sys-devel/gcc x11-libs/libX11 x11-libs/libXft x11-libs/libXinerama media-libs/fontconfig"
            ;;
        "opensuse" | "suse")
            # openSUSE
            PKG_MANAGER="zypper"
            PKG_UPDATE="zypper refresh"
            PKG_INSTALL="zypper install -y"
            DEPENDENCIES="git make gcc libX11-devel libXft-devel libXinerama-devel fontconfig"
            ;;
        "slackware")
            # Slackware (using slackpkg)
            PKG_MANAGER="slackpkg"
            PKG_UPDATE="slackpkg update"
            PKG_INSTALL="slackpkg install"
            DEPENDENCIES="git make gcc libX11 libXft libXinerama fontconfig"
            ;;
        "lfs")
            # Linux From Scratch (LFS)
            print_msg "Linux From Scratch detected. Please install the following dependencies manually:" "${YELLOW}"
            print_msg "  - git" "${YELLOW}"
            print_msg "  - make" "${YELLOW}"
            print_msg "  - gcc" "${YELLOW}"
            print_msg "  - libX11" "${YELLOW}"
            print_msg "  - libXft" "${YELLOW}"
            print_msg "  - libXinerama" "${YELLOW}"
            print_msg "  - fontconfig" "${YELLOW}"
            print_msg "You can typically build these from source using the LFS/BLFS instructions." "${YELLOW}"
            return 0
            ;;
        *)
            print_msg "Unsupported distribution: $DISTRO" "${RED}"
            exit 1
            ;;
    esac

    # Check if the package manager exists (not applicable for LFS)
    if ! command_exists $PKG_MANAGER; then
        print_msg "Package manager $PKG_MANAGER not found!" "${RED}"
        exit 1
    fi

    # Update package lists
    print_msg "Updating package lists..." "${YELLOW}"
    if ! sudo $PKG_UPDATE; then
        print_msg "Failed to update package lists!" "${RED}"
        exit 1
    fi

    # Install dependencies
    print_msg "Installing dependencies: $DEPENDENCIES" "${YELLOW}"
    if ! sudo $PKG_INSTALL $DEPENDENCIES; then
        print_msg "Failed to install dependencies!" "${RED}"
        exit 1
    fi

    print_msg "Dependencies installed successfully." "${GREEN}"
}

# Function to check and install git if not present
check_git() {
    if ! command_exists git; then
        print_msg "Git is not installed. Attempting to install git..." "${YELLOW}"
        case $DISTRO in
            "debian" | "Ubuntu" | "linuxmint")
                sudo apt install -y git
                ;;
            "arch" | "manjaro")
                sudo pacman -S --noconfirm git
                ;;
            "fedora")
                sudo dnf install -y git
                ;;
            "gentoo")
                sudo emerge -q dev-vcs/git
                ;;
            "opensuse" | "suse")
                sudo zypper install -y git
                ;;
            "slackware")
                sudo slackpkg install git
                ;;
            "lfs")
                print_msg "Git is not installed. Please install git manually on your LFS system." "${RED}"
                exit 1
                ;;
            *)
                print_msg "Cannot install git on $DISTRO. Please install git manually." "${RED}"
                exit 1
                ;;
        esac
    fi
    print_msg "Git is installed." "${GREEN}"
}

# Function to clone the dwmpanel repository
clone_repository() {
    REPO_URL="https://github.com/user7210unix/dwmpanel.git"
    CLONE_DIR="$HOME/.dwmpanel"

    print_msg "Cloning dwmpanel repository from $REPO_URL..." "${YELLOW}"

    # Remove the directory if it already exists
    if [ -d "$CLONE_DIR" ]; then
        print_msg "Removing existing directory $CLONE_DIR..." "${YELLOW}"
        rm -rf "$CLONE_DIR"
    fi

    # Clone the repository
    if ! git clone "$REPO_URL" "$CLONE_DIR"; then
        print_msg "Failed to clone the repository!" "${RED}"
        exit 1
    fi    print_msg "Repository cloned successfully to $CLONE_DIR." "${GREEN}"
}

# Function to set executable permissions
set_permissions() {
    CLONE_DIR="$HOME/.dwmpanel"

    print_msg "Setting executable permissions for scripts in $CLONE_DIR..." "${YELLOW}"

    # Find and chmod +x all shell scripts in the repository
    find "$CLONE_DIR" -type f -name "*.sh" -exec chmod +x {} \;

    # If there's a main executable (e.g., dwmpanel), make it executable
    if [ -f "$CLONE_DIR/dwmpanel" ]; then
        chmod +x "$CLONE_DIR/dwmpanel"
    fi

    print_msg "Permissions set successfully." "${GREEN}"
}

# Function to copy dwmpanel binary to /usr/bin/
copy_to_usr_bin() {
    CLONE_DIR="$HOME/.dwmpanel"
    DEST_FILE="/usr/bin/dwmpanel"
    SOURCE_FILE="$CLONE_DIR/dwmpanel"

    print_msg "Copying dwmpanel binary to $DEST_FILE..." "${YELLOW}"

    # Check if source binary exists
    if [ ! -f "$SOURCE_FILE" ]; then
        print_msg "dwmpanel binary not found in $CLONE_DIR!" "${RED}"
        exit 1
    fi

    # Remove the destination file if it already exists
    if [ -f "$DEST_FILE" ]; then
        print_msg "Removing existing file $DEST_FILE..." "${YELLOW}"
        sudo rm -f "$DEST_FILE"
    fi

    # Copy the dwmpanel binary to /usr/bin/
    if ! sudo cp "$SOURCE_FILE" "$DEST_FILE"; then
        print_msg "Failed to copy dwmpanel binary to $DEST_FILE!" "${RED}"
        exit 1
    fi

    # Ensure the binary is executable
    sudo chmod +x "$DEST_FILE"

    print_msg "Successfully copied dwmpanel binary to $DEST_FILE." "${GREEN}"
}

# Function to prompt for adding dwmpanel to .xinitrc
add_to_xinitrc() {
    XINITRC="$HOME/.xinitrc"
    DWM_PANEL_CMD="dwmpanel &"

    print_msg "Would you like to add dwmpanel to your .xinitrc for autostart? (Y/n): " "${YELLOW}"
    read -r response
    if [[ "$response" =~ ^([nN][oO]|[nN])$ ]]; then
        print_msg "Skipping addition to .xinitrc as requested." "${YELLOW}"
        return 0
    fi

    # Check if .xinitrc exists, create it if it doesn't
    if [ ! -f "$XINITRC" ]; then
        print_msg "Creating $XINITRC..." "${YELLOW}"
        touch "$XINITRC"
        echo "#!/bin/bash" > "$XINITRC"
    fi

    # Check if dwmpanel is already in .xinitrc
    if grep -q "dwmpanel" "$XINITRC"; then
        print_msg "dwmpanel is already in $XINITRC. Skipping..." "${YELLOW}"
        return 0
    fi

    # Add dwmpanel to .xinitrc before the exec command (if present)
    if grep -q "exec dwm" "$XINITRC"; then
        print_msg "Adding $DWM_PANEL_CMD to $XINITRC before 'exec dwm'..." "${YELLOW}"
        sed -i "/exec dwm/i $DWM_PANEL_CMD" "$XINITRC"
    else
        print_msg "Adding $DWM_PANEL_CMD to $XINITRC..." "${YELLOW}"
        echo "$DWM_PANEL_CMD" >> "$XINITRC"
    fi

    print_msg "Successfully added dwmpanel to $XINITRC." "${GREEN}"
}

# Main function
main() {
    print_msg "Starting dwmpanel installation script..." "${GREEN}"

    # Detect the distribution
    detect_distro

    # Install dependencies
    install_dependencies

    # Ensure git is installed
    check_git

    # Clone the repository
    clone_repository

    # Set permissions
    set_permissions

    # Copy to /usr/bin/
    copy_to_usr_bin

    # Add to .xinitrc if requested
    add_to_xinitrc

    print_msg "Installation completed successfully!" "${GREEN}"
    print_msg "You can find dwmpanel in $HOME/.dwmpanel and /usr/bin/dwmpanel." "${YELLOW}"
    print_msg "Please follow the instructions in the repository's README to build and run dwmpanel." "${YELLOW}"
}

# Run the main function
main
