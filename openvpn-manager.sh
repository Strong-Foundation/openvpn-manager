#!/bin/bash

# OpenVPN-Manager Installation Script
# Purpose: This script automates the installation of OpenVPN-Manager, a comprehensive tool for managing OpenVPN configurations.
# Author: ComplexOrganizations
# Repository: https://github.com/complexorganizations/openvpn-manager

# Usage Instructions:
# 1. System Requirements: Ensure you have 'curl' installed on your system. This script is compatible with most Linux distributions.
# 2. Downloading the Script:
#    - Use the following command to download the script:
#      curl https://raw.githubusercontent.com/complexorganizations/openvpn-manager/main/openvpn-manager.sh --create-dirs -o /usr/local/bin/openvpn-manager.sh
# 3. Making the Script Executable:
#    - Grant execution permissions to the script:
#      chmod +x /usr/local/bin/openvpn-manager.sh
# 4. Running the Script:
#    - Execute the script with root privileges:
#      bash /usr/local/bin/openvpn-manager.sh
# 5. Follow the on-screen instructions to complete the installation of OpenVPN-Manager.

# Advanced Usage:
# - The script supports various command-line arguments for custom installations. Refer to the repository's readme.md for more details.
# - For automated deployments, environment variables can be set before running this script.

# Troubleshooting:
# - If you encounter issues, ensure your system is up-to-date and retry the installation.
# - For specific errors, refer to the 'Troubleshooting' section in the repository's documentation.

# Contributing:
# - Contributions to the script are welcome. Please follow the contributing guidelines in the repository.

# Contact Information:
# - For support, feature requests, or bug reports, please open an issue on the GitHub repository.

# License: MIT License

# Note: This script is provided 'as is', without warranty of any kind. The user is responsible for understanding the operations and risks involved.

# Define a function to check if the script is being run with root privileges
function check_root() {
  # Compare the user ID of the current user to 0, which is the ID for root
  if [ "$(id -u)" != "0" ]; then
    # If the user ID is not 0 (i.e., not root), print an error message
    echo "Error: This script must be run as root."
    # Exit the script with a status code of 1, indicating an error
    exit 1 # Exit the script with an error code.
  fi
}

# Call the check_root function to verify that the script is executed with root privileges
check_root

# Define a function to gather and store system-related information
function system_information() {
  # Check if the /etc/os-release file exists, which contains information about the OS
  if [ -f /etc/os-release ]; then
    # If the /etc/os-release file is present, source it to load system details into environment variables
    # shellcheck source=/dev/null  # Instructs shellcheck to ignore warnings about sourcing files
    source /etc/os-release
    # Set the CURRENT_DISTRO variable to the system's distribution ID (e.g., 'ubuntu', 'debian')
    CURRENT_DISTRO=${ID}
    # Set the CURRENT_DISTRO_VERSION variable to the system's version ID (e.g., '20.04' for Ubuntu 20.04)
    CURRENT_DISTRO_VERSION=${VERSION_ID}
    # Set the CURRENT_SYSTEM_ARCHITECTURE variable to the system's architecture (e.g., 'x86_64', 'arm64')
    CURRENT_SYSTEM_ARCHITECTURE=$(uname -m)
  else
    # If the /etc/os-release file is not present, show an error message and exit
    echo "Error: /etc/os-release file not found. Unable to gather system information."
    exit 1 # Exit the script with a non-zero status to indicate an error
  fi
}

# Call the system_information function to gather the system details
system_information

# Function to install either resolvconf or openresolv, depending on the distribution.
function install_resolvconf_or_openresolv() {
  # Check if resolvconf is already installed on the system.
  if [ ! -x "$(command -v resolvconf)" ]; then
    # If resolvconf is not installed, install it for Ubuntu, Debian, Raspbian, Pop, Kali, Linux Mint, and Neon distributions.
    if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
      apt-get install resolvconf -y
    # For CentOS, RHEL, AlmaLinux, and Rocky distributions, install openresolv.
    elif { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ] || [ "${CURRENT_DISTRO}" == "amzn" ]; }; then
      # If the distribution is CentOS 7, enable the copr repository before installing openresolv.
      if [ "${CURRENT_DISTRO}" == "centos" ] && [ "${CURRENT_DISTRO_MAJOR_VERSION}" == 7 ]; then
        yum copr enable macieks/openresolv -y
      fi
      yum install openresolv -y
    # For Fedora and Oracle Linux distributions, install openresolv.
    elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "ol" ]; }; then
      yum install openresolv -y
    # For Arch, Arch ARM, and Manjaro distributions, install resolvconf.
    elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
      # Check for updates.
      pacman -Sy
      # Install resolvconf.
      pacman -Su --noconfirm --needed resolvconf
    # For Alpine Linux, install resolvconf.
    elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
      apk update
      apk add openresolv
    # For FreeBSD, install resolvconf.
    elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
      pkg install resolvconf
    elif [ "${CURRENT_DISTRO}" == "mageia" ]; then
      urpmi.update -a
      yes | urpmi resolvconf
    elif [ "${CURRENT_DISTRO}" == "opensuse-tumbleweed" ]; then
      zypper refresh
      zypper install -y openresolv
    fi
  fi
}

# Invoke the function to install either resolvconf or openresolv, depending on the distribution.
install_resolvconf_or_openresolv

# Define a function to check system requirements
function installing_system_requirements() {
  # Check if the current Linux distribution is supported
  if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ] || [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ] || [ "${CURRENT_DISTRO}" == "amzn" ] || [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ] || [ "${CURRENT_DISTRO}" == "alpine" ] || [ "${CURRENT_DISTRO}" == "freebsd" ] || [ "${CURRENT_DISTRO}" == "ol" ] || [ "${CURRENT_DISTRO}" == "mageia" ] || [ "${CURRENT_DISTRO}" == "opensuse-tumbleweed" ]; }; then
    # Check if required packages are already installed
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v sudo)" ] || [ ! -x "$(command -v bash)" ] || [ ! -x "$(command -v cut)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v ip)" ] || [ ! -x "$(command -v systemd-detect-virt)" ] || [ ! -x "$(command -v ps)" ] || [ ! -x "$(command -v lsof)" ] || [ ! -x "$(command -v haveged)" ] || [ ! -x "$(command -v bash)" ]; }; then
      # Install required packages depending on the Linux distribution
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get update
        apt-get install curl sudo bash coreutils jq iproute2 systemd procps lsof haveged bash -y
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ] || [ "${CURRENT_DISTRO}" == "amzn" ]; }; then
        # For Red Hat-based distributions, check for updates and install required packages
        yum check-update
        if { [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
          # Install necessary packages for AlmaLinux
          yum install epel-release elrepo-release -y
        else
          yum install epel-release elrepo-release -y --skip-unavailable
        fi
        yum install curl sudo bash coreutils jq iproute2 systemd procps-ng lsof haveged bash -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        # Check for updates.
        pacman -Sy
        # Initialize the GPG keyring.
        pacman-key --init
        # Populate the keyring with the default Arch Linux keys
        pacman-key --populate archlinux
        # For Arch-based distributions, update the keyring and install required packages
        pacman -Sy --noconfirm --needed archlinux-keyring
        #
        pacman -Su --noconfirm --needed curl sudo bash coreutils jq iproute2 systemd procps-ng lsof haveged bash
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        # Alpine linux
        apk update
        apk add curl sudo bash coreutils jq iproute2 systemd procps-ng lsof haveged bash
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        # For FreeBSD, update package lists and install required packages
        pkg update
        pkg install curl sudo bash coreutils jq iproute2 systemd procps-ng lsof haveged bash
      elif [ "${CURRENT_DISTRO}" == "ol" ]; then
        # For Oracle Linux (OL), check for updates and install required packages
        yum check-update
        yum install curl sudo bash coreutils jq iproute2 systemd procps-ng lsof haveged bash -y --allowerasing
      elif [ "${CURRENT_DISTRO}" == "mageia" ]; then
        # For Mageia, update package lists and install required packages
        urpmi.update -a
        yes | urpmi curl sudo bash coreutils jq iproute2 systemd procps-ng lsof haveged bash
      elif [ "${CURRENT_DISTRO}" == "opensuse-tumbleweed" ]; then
        # For OpenSUSE Tumbleweed, update package lists and install required packages
        zypper refresh
        zypper install -y curl sudo bash coreutils jq iproute2 systemd procps-ng lsof haveged bash
      fi
    fi
  else
    echo "Error: Your current distribution ${CURRENT_DISTRO} version ${CURRENT_DISTRO_VERSION} is not supported by this script. Please consider updating your distribution or using a supported one."
    exit
  fi
}

# Call the function to check for system requirements and install necessary packages if needed
installing_system_requirements

# Checking For Virtualization
function virt_check() {
  # This code checks if the system is running in a supported virtualization.
  # It returns the name of the virtualization if it is supported, or "none" if
  # it is not supported. This code is used to check if the system is running in
  # a virtual machine, and if so, if it is running in a supported virtualization.
  # systemd-detect-virt is a utility that detects the type of virtualization
  # that the system is running on. It returns a string that indicates the name
  # of the virtualization, such as "kvm" or "vmware".
  CURRENT_SYSTEM_VIRTUALIZATION=$(systemd-detect-virt)
  # This case statement checks if the virtualization that the system is running
  # on is supported. If it is not supported, the script will print an error
  # message and exit.
  case ${CURRENT_SYSTEM_VIRTUALIZATION} in
  "amazon" | "docker" | "google" | "kvm" | "lxc" | "microsoft" | "none" | "qemu" | "vmware" | "xen") ;;
  *)
    echo "Error: the ${CURRENT_SYSTEM_VIRTUALIZATION} virtualization is currently not supported. Please stay tuned for future updates."
    exit
    ;;
  esac
}

# Call the virt_check function to check for supported virtualization.
virt_check

# The following function checks if the current init system is one of the allowed options.
function check_current_init_system() {
  # Get the current init system by checking the process name of PID 1.
  CURRENT_INIT_SYSTEM=$(ps -p 1 -o comm= | awk -F'/' '{print $NF}') # Extract only the command name without the full path.
  # Convert to lowercase to make the comparison case-insensitive.
  CURRENT_INIT_SYSTEM=$(echo "$CURRENT_INIT_SYSTEM" | tr '[:upper:]' '[:lower:]')
  # Log the detected init system (optional for debugging purposes).
  echo "Detected init system: ${CURRENT_INIT_SYSTEM}"
  # Define a list of allowed init systems (case-insensitive).
  ALLOWED_INIT_SYSTEMS=("systemd" "sysvinit" "init" "upstart" "bash" "sh")
  # Check if the current init system is in the list of allowed init systems
  if [[ ! "${ALLOWED_INIT_SYSTEMS[*]}" =~ ${CURRENT_INIT_SYSTEM} ]]; then
    # If the init system is not allowed, display an error message and exit with an error code.
    echo "Error: The '${CURRENT_INIT_SYSTEM}' initialization system is not supported. Please stay tuned for future updates."
    exit # Exit the script with an error code.
  fi
}

# The check_current_init_system function is being called.
check_current_init_system

# The following function checks if there's enough disk space to proceed with the installation.
function check_disk_space() {
  # This function checks if there is more than 1 GB of free space on the drive.
  FREE_SPACE_ON_DRIVE_IN_MB=$(df -m / | tr -s " " | tail -n1 | cut -d" " -f4)
  # This line calculates the available free space on the root partition in MB.
  if [ "${FREE_SPACE_ON_DRIVE_IN_MB}" -le 1024 ]; then
    # If the available free space is less than or equal to 1024 MB (1 GB), display an error message and exit.
    echo "Error: You need more than 1 GB of free space to install everything. Please free up some space and try again."
    exit 1 # Exit the script with an error code.
  fi
}

# Calls the check_disk_space function.
check_disk_space

# Global variables
# Assigns the path of the current script to a variable
CURRENT_FILE_PATH=$(realpath "${0}")
# Set the TUN_PATH variable to the path of the TUN device
LOCAL_TUN_PATH="/dev/net/tun"
# Assigns a path for the DNS resolver configuration file
RESOLV_CONFIG="/etc/resolv.conf"
# Assigns a path for the old DNS resolver configuration file
RESOLV_CONFIG_OLD="${RESOLV_CONFIG}.old"
# Assigns a path for Unbound DNS resolver
UNBOUND_ROOT="/etc/unbound"
# Assigns a path for the Unbound configuration file
UNBOUND_CONFIG="${UNBOUND_ROOT}/unbound.conf"
# Assigns a path for the Unbound root hints file
UNBOUND_ROOT_HINTS="${UNBOUND_ROOT}/root.hints"
# Assigns a path for the Unbound anchor file
UNBOUND_ANCHOR="/var/lib/unbound/root.key"
if { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
  UNBOUND_ANCHOR="${UNBOUND_ROOT}/root.key"
fi
# Assigns a path for the Unbound configuration directory
UNBOUND_CONFIG_DIRECTORY="${UNBOUND_ROOT}/unbound.conf.d"
# Assigns a path for the Unbound hosts configuration file
UNBOUND_CONFIG_HOST="${UNBOUND_CONFIG_DIRECTORY}/hosts.conf"
# Set the path to the openvpn server directory
OPENVPN_DIRECTORY="/etc/openvpn"
# Set the path to the openvpn server directory
OPENVPN_SERVER_DIRECTORY="${OPENVPN_DIRECTORY}/server"
# Set the path to the openvpn server client directory
OPENVPN_SERVER_CLIENT_DIRECTORY="${OPENVPN_DIRECTORY}/ccd"
# Set the path to the openvpn IP persist file
IFCONFIG_POOL_PERSIST_FILE="${OPENVPN_SERVER_DIRECTORY}/ipp.txt"
# Set the path to the openvpn server config
OPENVPN_SERVER_CONFIG="${OPENVPN_SERVER_DIRECTORY}/server.conf"
# Set the path to the openvpn easy-rsa directory
OPENVPN_SERVER_EASY_RSA_DIRECTORY="${OPENVPN_DIRECTORY}/easy-rsa"
# Set the path to the openvpn pki directory
OPENVPN_PKI_DIRECTORY="${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/pki"
# Set the path to the openvpn server certificate index file
OPENVPN_SERVER_CERTIFICATE_INDEX="${OPENVPN_PKI_DIRECTORY}/index.txt"
# Set the path to the easyrsa script in the easy-rsa directory
OPENVPN_SERVER_EASY_RSA_SCRIPT="${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/easyrsa"
# Set the path to the openvpn server easy-rsa variables file
OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE="${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars"
# Set the path to the openvpn server certificate authority
OPENVPN_SERVER_CERTIFICATE_AUTHORITY="${OPENVPN_PKI_DIRECTORY}/ca.crt"
# Set the path to the openvpn server diffie Hellman parameters file
OPENVPN_SERVER_DIFFIE_HELLMAN_PARAMETERS="${OPENVPN_PKI_DIRECTORY}/dh.pem"
# Set the path to the openvpn server tls-crypt key
OPENVPN_SERVER_TLS_CRYPT_KEY="${OPENVPN_SERVER_DIRECTORY}/tls-crypt.key"
# Set the path to the openvpn server ssl certificate
OPENVPN_SERVER_SSL_CERTIFICATE="${OPENVPN_PKI_DIRECTORY}/issued/server.crt"
# Set the path to the openvpn server ssl key
OPENVPN_SERVER_SSL_KEY="${OPENVPN_PKI_DIRECTORY}/private/server.key"
# Set the path to the openvpn server ssl certificate revocation list
OPENVPN_SERVER_SSL_CERTIFICATE_REVOCATION_LIST="${OPENVPN_PKI_DIRECTORY}/crl.pem"
# Set the path to the openvpn server ssl certificate revocation list link
OPENVPN_SERVER_SSL_CERTIFICATE_REVOCATION_LIST_LINK="${OPENVPN_SERVER_DIRECTORY}/crl.pem"
# Encryption cipher suite for the control channel
CONTROL_CHANNEL_ENCRYPTION="TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384"
# Encryption cipher for the data channel
DATA_CHANNEL_ENCRYPTION="AES-256-GCM"
# Encryption cipher for the data channel
DATA_CHIPER="AES-256-GCM"
# Elliptic curve used for the certificate key
CERTIFICATE_ECDSA_CURVE="secp521r1"
# HMAC digest algorithm for authentication
HMAC_ALGORITHM="SHA512"
# Generate a random number within the range 1-1 (always 1) and use it in a case statement
case $(shuf --input-range=1-1 --head-count=1) in
1)
  # Set the URL for the Unbound root server configuration file
  UNBOUND_ROOT_SERVER_CONFIG_URL="https://raw.githubusercontent.com/Strong-Foundation/openvpn-manager/refs/heads/main/assets/named.cache"
  ;; # End of case statement
esac

# Generate a random number within the range 1-1 (always 1) and use it in a case statement
case $(shuf --input-range=1-1 --head-count=1) in
1)
  # Set the URL for the Unbound host configuration file
  UNBOUND_CONFIG_HOST_URL="https://raw.githubusercontent.com/Strong-Foundation/openvpn-manager/refs/heads/main/assets/hosts"
  ;; # End of case statement
esac

# Set the environment variable to avoid interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Define the function check_local_tun
function check_local_tun() {
  # Check if the TUN device path does not exist
  if [ ! -e "${LOCAL_TUN_PATH}" ]; then
    # Print an error message if the path doesn't exist
    echo "Error: ${LOCAL_TUN_PATH} not found!"
    # Try to load the TUN module
    echo "Attempting to load the TUN module..."
    sudo modprobe tun
    # Wait a moment for the module to load and then check again
    sleep 30
    # Check again if the TUN device exists after trying to load the module
    if [ ! -e "${LOCAL_TUN_PATH}" ]; then
      # If still not found, print an error and exit with an error code
      echo "Error: ${LOCAL_TUN_PATH} still not found after loading the module!"
      exit
    else
      # If the device is found after loading the module, print a success message
      echo "TUN device found at ${LOCAL_TUN_PATH}."
    fi
  else
    # If the device is found initially, print a success message
    echo "TUN device found at ${LOCAL_TUN_PATH}."
  fi
}

# Call the check_local_tun function to check for the TUN device
# check_local_tun

# This is a Bash function named "get_network_information" that retrieves network information.
function get_network_information() {
  # This variable will store the IPv4 address of the default network interface by querying the "ipengine" API using "curl" command and extracting it using "jq" command.
  DEFAULT_INTERFACE_IPV4="$(curl --ipv4 --connect-timeout 5 --tlsv1.2 --silent 'https://checkip.amazonaws.com')"
  # If the IPv4 address is empty, try getting it from another API.
  if [ -z "${DEFAULT_INTERFACE_IPV4}" ]; then
    DEFAULT_INTERFACE_IPV4="$(curl --ipv4 --connect-timeout 5 --tlsv1.3 --silent 'https://icanhazip.com')"
  fi
  # This variable will store the IPv6 address of the default network interface by querying the "ipengine" API using "curl" command and extracting it using "jq" command.
  DEFAULT_INTERFACE_IPV6="$(curl --ipv6 --connect-timeout 5 --tlsv1.3 --silent 'https://ifconfig.co')"
  # If the IPv6 address is empty, try getting it from another API.
  if [ -z "${DEFAULT_INTERFACE_IPV6}" ]; then
    DEFAULT_INTERFACE_IPV6="$(curl --ipv6 --connect-timeout 5 --tlsv1.3 --silent 'https://icanhazip.com')"
  fi
}

function usage_guide() {
  echo "Usage: ./$(basename "${0}") <command>"
  echo "  --install     Installs the OpenVPN service on your system"
  echo "  --start       Starts the OpenVPN service if it's not already running"
  echo "  --stop        Stops the OpenVPN service if it's currently running"
  echo "  --restart     Restarts the OpenVPN service"
  echo "  --list        Lists all active OpenVPN connections"
  echo "  --add         Adds a new client configuration to the OpenVPN server"
  echo "  --remove      Removes a specified client from the OpenVPN server"
  echo "  --uninstall   Uninstalls the OpenVPN service from your system"
  echo "  --update      Updates the OpenVPN Manager to the latest version"
  echo "  --backup      Creates a backup of your current OpenVPN configuration"
  echo "  --restore     Restores the OpenVPN configuration from a previous backup"
  echo "  --purge       Removes all client configurations from the OpenVPN server"
  echo "  --firewall    Configures the firewall to allow OpenVPN traffic"
  echo "  --help        Displays this usage guide"
}

function usage() {
  # Check if there are any command line arguments left
  while [ $# -ne 0 ]; do
    # Use a switch-case statement to check the value of the first argument
    case ${1} in
    --install) # If it's "--install", set the variable HEADLESS_INSTALL to "true"
      shift
      HEADLESS_INSTALL=${HEADLESS_INSTALL=true}
      ;;
    --start) # If it's "--start", set the variable OPENVPN_OPTIONS to 2
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=2}
      ;;
    --stop) # If it's "--stop", set the variable OPENVPN_OPTIONS to 3
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=3}
      ;;
    --restart) # If it's "--restart", set the variable OPENVPN_OPTIONS to 4
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=4}
      ;;
    --list) # If it's "--list", set the variable OPENVPN_OPTIONS to 1
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=1}
      ;;
    --add) # If it's "--add", set the variable OPENVPN_OPTIONS to 5
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=5}
      ;;
    --remove) # If it's "--remove", set the variable OPENVPN_OPTIONS to 6
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=6}
      ;;
    --uninstall) # If it's "--uninstall", set the variable OPENVPN_OPTIONS to 7
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=7}
      ;;
    --update) # If it's "--update", set the variable OPENVPN_OPTIONS to 8
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=8}
      ;;
    --backup) # If it's "--backup", set the variable OPENVPN_OPTIONS to 9
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=9}
      ;;
    --restore) # If it's "--restore", set the variable OPENVPN_OPTIONS to 10
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=10}
      ;;
    --purge) # If it's "--purge", set the variable OPENVPN_OPTIONS to 13
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=13}
      ;;
    --firewall) # If it's "--firewall", set the variable OPENVPN_OPTIONS to 16
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=16}
      ;;
    --help) # If it's "--help", call the function usage_guide
      shift
      usage_guide
      ;;
    *) # If it's anything else, print an error message and call the function usage_guide, then exit
      echo "Invalid argument: ${1}"
      usage_guide
      exit
      ;;
    esac
  done
}

# Call the function usage with all the command line arguments
usage "$@"

# The function defines default values for configuration variables when installing OpenVPN in headless mode.
# These variables include private subnet settings, server host settings, NAT choice, port settings, MTU settings, client configuration options, automatic updates, automatic backups, DNS provider settings, content blocker settings, client name, and automatic configuration removal.
function headless_install() {
  # If headless installation is specified, set default values for configuration variables.
  if [ "${HEADLESS_INSTALL}" == true ]; then
    PRIVATE_SUBNET_V4_SETTINGS=${PRIVATE_SUBNET_V4_SETTINGS=1} # Default to 1 (10.0.0.0/8)
    PRIVATE_SUBNET_V6_SETTINGS=${PRIVATE_SUBNET_V6_SETTINGS=1} # Default to 1 (fd00:00:00::0/8)
    SERVER_HOST_V4_SETTINGS=${SERVER_HOST_V4_SETTINGS=1}       # Default to 1 (IPv4)
    SERVER_HOST_V6_SETTINGS=${SERVER_HOST_V6_SETTINGS=1}       # Default to 1 (IPv6)
    SERVER_HOST_SETTINGS=${SERVER_HOST_SETTINGS=1}             # Default to 1 (IPv4)
    SERVER_PUB_NIC_SETTINGS=${SERVER_PUB_NIC_SETTINGS=1}       # Default to 1 (IP Route)
    PROTOCOL_CHOICE=${PROTOCOL_CHOICE=1}                       # Default to 1 (UDP as primary, TCP as secondary)
    SERVER_PORT_SETTINGS=${SERVER_PORT_SETTINGS=1}             # Default to 1 (1194)
    DNS_PROVIDER_SETTINGS=${DNS_PROVIDER_SETTINGS=1}           # Default to 1 (Unbound)
    CONTENT_BLOCKER_SETTINGS=${CONTENT_BLOCKER_SETTINGS=1}     # Default to 1 (Yes)
    CLIENT_NAME=${CLIENT_NAME=$(openssl rand -hex 5)}          # Set the client name
  fi
}

# Call the headless_install function to set default values for configuration variables in headless mode.
headless_install

# Set up the openvpn, if config it isn't already there.
if [ ! -f "${OPENVPN_SERVER_CONFIG}" ]; then

  # Define a function to set a custom IPv4 subnet
  function set_ipv4_subnet() {
    # Prompt the user for the desired IPv4 subnet
    echo "Please specify the IPv4 subnet you want to use for the OpenVPN interface. This should be a private subnet that is not in use elsewhere on your network."
    echo "  1) 10.64.0.0/12 (Recommended)"
    echo "  2) Custom (Advanced)"
    # Keep prompting the user until they enter a valid subnet choice
    until [[ "${PRIVATE_SUBNET_V4_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Subnet Choice [1-2]:" -e -i 1 PRIVATE_SUBNET_V4_SETTINGS
    done
    # Based on the user's choice, set the private IPv4 subnet
    case ${PRIVATE_SUBNET_V4_SETTINGS} in
    1)
      PRIVATE_SUBNET_V4="10.64.0.0/12" # Set a default OpenVPN IPv4 subnet
      ;;
    2)
      read -rp "Custom IPv4 Subnet:" PRIVATE_SUBNET_V4 # Prompt user for custom subnet
      if [ -z "${PRIVATE_SUBNET_V4}" ]; then           # If the user did not enter a subnet, set default
        PRIVATE_SUBNET_V4="10.64.0.0/12"
      fi
      ;;
    esac
  }

  # Call the function to set the custom IPv4 subnet
  set_ipv4_subnet

  # Define a function to set a custom IPv6 subnet
  function set_ipv6_subnet() {
    # Ask the user which IPv6 subnet they want to use
    echo "Please specify the IPv6 subnet you want to use for the OpenVPN interface. This should be a private subnet that is not in use elsewhere on your network."
    echo "  1) fd64:00:00::0/12 (Recommended)"
    echo "  2) Custom (Advanced)"
    # Use a loop to ensure the user inputs a valid option
    until [[ "${PRIVATE_SUBNET_V6_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "Please choose the IPv6 subnet for your OpenVPN interface [Option 1-2]: " -e -i 1 PRIVATE_SUBNET_V6_SETTINGS
    done
    # Use a case statement to set the IPv6 subnet based on the user's choice
    case ${PRIVATE_SUBNET_V6_SETTINGS} in
    1)
      # Use the recommended IPv6 subnet if the user chooses option 1
      PRIVATE_SUBNET_V6="fd64:00:00::0/12"
      ;;
    2)
      # Ask the user for a custom IPv6 subnet if they choose option 2
      read -rp "Please enter a custom IPv6 subnet for your OpenVPN interface: " PRIVATE_SUBNET_V6
      # If the user does not input a subnet, use the recommended one
      if [ -z "${PRIVATE_SUBNET_V6}" ]; then
        PRIVATE_SUBNET_V6="fd64:00:00::0/12"
      fi
      ;;
    esac
  }

  # Call the set_ipv6_subnet function to set the custom IPv6 subnet
  set_ipv6_subnet

  # Define the private subnet mask for the IPv4 network used by the OpenVPN interface
  PRIVATE_SUBNET_MASK_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="/" --fields=2) # Get the subnet mask of IPv4
  # Define the IPv4 gateway for the OpenVPN interface
  GATEWAY_ADDRESS_V4=$(echo "${PRIVATE_SUBNET_V4}" | cut --delimiter="." --fields=1-3).1 # Get the gateway address of IPv4
  # Define the private subnet mask for the IPv6 network used by the OpenVPN interface
  PRIVATE_SUBNET_MASK_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter="/" --fields=2) # Get the subnet mask of IPv6
  # Define the IPv6 gateway for the OpenVPN interface
  GATEWAY_ADDRESS_V6=$(echo "${PRIVATE_SUBNET_V6}" | cut --delimiter=":" --fields=1-3)::1 # Get the gateway address of IPv6
  # Retrieve the networking configuration details
  get_network_information

  function test_connectivity_v4() {
    echo "How would you like to detect IPv4?"                       # Ask user how to detect IPv4
    echo "  1) Curl (Recommended)"                                  # Option 1: Use Curl for automatic detection
    echo "  2) Custom (Advanced)"                                   # Option 2: User manually enters an IP
    until [[ "${SERVER_HOST_V4_SETTINGS}" =~ ^[1-2]$ ]]; do         # Ensure valid input
      read -rp "IPv4 Choice [1-2]:" -e -i 1 SERVER_HOST_V4_SETTINGS # Prompt user
    done
    case ${SERVER_HOST_V4_SETTINGS} in
    1)
      SERVER_HOST_V4=${DEFAULT_INTERFACE_IPV4} # Use default detected IPv4
      ;;
    2)
      read -rp "Custom IPv4:" SERVER_HOST_V4 # Prompt user for custom IPv4
      if [ -z "${SERVER_HOST_V4}" ]; then    # If no input, fallback to default
        SERVER_HOST_V4=${DEFAULT_INTERFACE_IPV4}
      fi
      ;;
    esac
  }

  test_connectivity_v4 # Call function to retrieve IPv4 address

  function test_connectivity_v6() {
    echo "How would you like to detect IPv6?"                       # Ask user how to detect IPv6
    echo "  1) Curl (Recommended)"                                  # Option 1: Use Curl for automatic detection
    echo "  2) Custom (Advanced)"                                   # Option 2: User manually enters an IP
    until [[ "${SERVER_HOST_V6_SETTINGS}" =~ ^[1-2]$ ]]; do         # Ensure valid input
      read -rp "IPv6 Choice [1-2]:" -e -i 1 SERVER_HOST_V6_SETTINGS # Prompt user
    done
    case ${SERVER_HOST_V6_SETTINGS} in
    1)
      SERVER_HOST_V6=${DEFAULT_INTERFACE_IPV6} # Use default detected IPv6
      ;;
    2)
      read -rp "Custom IPv6:" SERVER_HOST_V6 # Prompt user for custom IPv6
      if [ -z "${SERVER_HOST_V6}" ]; then    # If no input, fallback to default
        SERVER_HOST_V6=${DEFAULT_INTERFACE_IPV6}
      fi
      ;;
    esac
  }

  test_connectivity_v6 # Call function to retrieve IPv6 address

  function ipvx_select_openvpn() {
    echo "Which IP version do you want to use for the OpenVPN server?" # Ask user for IP version
    echo "  1) IPv4 (Recommended)"                                     # Option 1: Use IPv4
    echo "  2) IPv6"                                                   # Option 2: Use IPv6
    until [[ "${SERVER_HOST_SETTINGS}" =~ ^[1-2]$ ]]; do               # Ensure valid input
      read -rp "IP Version Choice [1-2]:" -e -i 1 SERVER_HOST_SETTINGS # Prompt user
    done
    case ${SERVER_HOST_SETTINGS} in
    1)
      if [ -n "${SERVER_HOST_V4}" ]; then # Check if IPv4 is available
        SERVER_HOST="${SERVER_HOST_V4}"   # Set server host to IPv4
      else
        SERVER_HOST="[${SERVER_HOST_V6}]" # Fallback to IPv6 if IPv4 is unavailable
      fi
      ;;
    2)
      if [ -n "${SERVER_HOST_V6}" ]; then # Check if IPv6 is available
        SERVER_HOST="[${SERVER_HOST_V6}]" # Set server host to IPv6
      else
        SERVER_HOST="${SERVER_HOST_V4}" # Fallback to IPv4 if IPv6 is unavailable
      fi
      ;;
    esac
  }

  # Invoke the function to select the IP version for OpenVPN
  ipvx_select_openvpn

  # Define a function to identify the public Network Interface Card (NIC).
  function server_pub_nic() {
    # Prompt the user to select the method for identifying the NIC.
    echo "How would you like to identify the Network Interface Card (NIC)?"
    echo "  1) IP Route (Recommended)"
    echo "  2) Custom Input (Advanced)"
    # Loop until the user provides a valid input (either 1 or 2).
    until [[ "${SERVER_PUB_NIC_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "NIC Choice [1-2]:" -e -i 1 SERVER_PUB_NIC_SETTINGS
    done
    # Execute a case statement based on the user's choice.
    case ${SERVER_PUB_NIC_SETTINGS} in
    1)
      # Use the IP route command to automatically identify the NIC.
      SERVER_PUB_NIC="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
      # If no NIC is found, exit the script with an error message.
      if [ -z "${SERVER_PUB_NIC}" ]; then
        echo "Error: Unable to identify your server's public network interface."
        exit
      fi
      ;;
    2)
      # Prompt the user to manually input the NIC.
      read -rp "Custom NIC:" SERVER_PUB_NIC
      # If the user doesn't provide an input, use the IP route command to identify the NIC.
      if [ -z "${SERVER_PUB_NIC}" ]; then
        SERVER_PUB_NIC="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
      fi
      ;;
    esac
  }

  # Call the function to identify the public NIC.
  server_pub_nic

  # Define a function to configure the protocol settings for OpenVPN
  function configure_protocol() {
    # Prompt the user to configure the primary and secondary protocols
    echo "Select the primary and secondary protocols for OpenVPN:"
    echo "  1) UDP (Recommended)"
    echo "  2) TCP"
    # Loop until the user provides a valid input
    until [[ "${PROTOCOL_CHOICE}" =~ ^[1-2]$ ]]; do
      read -rp "Protocol Choice [1-2]: " -e -i 1 PROTOCOL_CHOICE
    done
    # Set the protocols based on the user's choice
    case ${PROTOCOL_CHOICE} in
    1)
      PRIMARY_PROTOCOL="udp4"
      ;;
    2)
      PRIMARY_PROTOCOL="tcp4"
      ;;
    esac
  }

  # Call the function to configure the protocol settings
  configure_protocol

  # Define a function to configure OpenVPN server ports with two separate checks
  function configure_openvpn_ports() {
    # Show the default and custom port options to the user
    echo "  1) 1194 (Default and Recommended)"
    echo "  2) Custom (Advanced)"
    # Prompt the user until a valid option (1 or 2) is selected
    until [[ "${SERVER_PORT_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Ask the user to choose a port option, defaulting to 1 (1194)
      read -rp "Port Choice [1-2]: " -e -i 1 SERVER_PORT_SETTINGS
    done
    # Set the server port based on the user's choice
    case ${SERVER_PORT_SETTINGS} in
    1)
      # If the user selects option 1, set the port to the default OpenVPN port (1194)
      SERVER_PORT="1194"
      # Check if the selected port is already in use for either UDP or TCP
      if { [ "$(lsof -i UDP:"${SERVER_PORT}")" ] || [ "$(lsof -i TCP:"${SERVER_PORT}")" ]; }; then
        # If the port is in use, display an error message and exit the script
        echo "Error: The port ${SERVER_PORT} is already in use. Please choose a different port."
        exit
      fi
      ;;
    2)
      # If the user selects option 2, prompt for a custom port
      # Continue prompting until a valid port (1–65535) is provided
      until [[ "${SERVER_PORT}" =~ ^[0-9]+$ ]] && [ "${SERVER_PORT}" -ge 1 ] && [ "${SERVER_PORT}" -le 65535 ]; do
        # Ask the user to input a custom port number, with 1194 as the default option
        read -rp "Custom port [1-65535]: " -e -i 1194 SERVER_PORT
      done
      # If no input is provided for the custom port, default to 1194
      if [ -z "${SERVER_PORT}" ]; then
        SERVER_PORT="1194" # Default port for OpenVPN
      fi
      # Check if the chosen custom port is already in use for UDP or TCP
      if [ "$(lsof -i UDP:"${SERVER_PORT}")" ]; then
        # If the custom port is in use, display an error message and exit the script
        echo "Error: The port ${SERVER_PORT} is already in use. Please choose a different port."
        exit
      fi
      ;;
    esac
  }

  # Call the function to execute the OpenVPN port configuration process
  configure_openvpn_ports

  # Function to prompt the user for their preferred DNS provider.
  function ask_install_dns() {
    # Display the DNS provider options to the user.
    echo "Which DNS provider would you like to use?"
    echo "  1) Unbound (Recommended)"
    echo "  2) Custom (Advanced)"
    # Continue prompting until the user enters a valid choice (1 or 2).
    until [[ "${DNS_PROVIDER_SETTINGS}" =~ ^[1-2]$ ]]; do
      # Read the user's DNS provider choice and store it in DNS_PROVIDER_SETTINGS.
      read -rp "DNS provider [1-2]:" -e -i 1 DNS_PROVIDER_SETTINGS
    done
    # Set variables based on the user's DNS provider choice.
    case ${DNS_PROVIDER_SETTINGS} in
    1)
      # If the user chose Unbound, set INSTALL_UNBOUND to true.
      INSTALL_UNBOUND=true
      # Ask the user if they want to install a content-blocker.
      echo "Do you want to prevent advertisements, tracking, malware, and phishing using the content-blocker?"
      echo "  1) Yes (Recommended)"
      echo "  2) No"
      # Continue prompting until the user enters a valid choice (1 or 2).
      until [[ "${CONTENT_BLOCKER_SETTINGS}" =~ ^[1-2]$ ]]; do
        # Read the user's content blocker choice and store it in CONTENT_BLOCKER_SETTINGS.
        read -rp "Content Blocker Choice [1-2]:" -e -i 1 CONTENT_BLOCKER_SETTINGS
      done
      # Set INSTALL_BLOCK_LIST based on the user's content blocker choice.
      case ${CONTENT_BLOCKER_SETTINGS} in
      1)
        # If the user chose to install the content blocker, set INSTALL_BLOCK_LIST to true.
        INSTALL_BLOCK_LIST=true
        ;;
      2)
        # If the user chose not to install the content blocker, set INSTALL_BLOCK_LIST to false.
        INSTALL_BLOCK_LIST=false
        ;;
      esac
      ;;
    2)
      # If the user chose to use a custom DNS provider, set CUSTOM_DNS to true.
      CUSTOM_DNS=true
      ;;
    esac
  }

  # Invoke the ask_install_dns function to begin the DNS provider selection process.
  ask_install_dns

  # Function to allow users to select a custom DNS provider.
  function custom_dns() {
    # If the custom DNS option is enabled, proceed with the DNS selection.
    if [ "${CUSTOM_DNS}" == true ]; then
      # Present the user with a list of DNS providers to choose from.
      echo "Select the DNS provider you wish to use with your OpenVPN connection:"
      echo "  1) Cloudflare (Recommended)"
      echo "  2) AdGuard"
      echo "  3) NextDNS"
      echo "  4) OpenDNS"
      echo "  5) Google"
      echo "  6) Verisign"
      echo "  7) Quad9"
      echo "  8) FDN"
      echo "  9) Custom (Advanced)"
      # If Pi-Hole is installed, add it as an option.
      if [ -x "$(command -v pihole)" ]; then
        echo "  10) Pi-Hole (Advanced)"
      fi
      # Prompt the user to make a selection from the list of DNS providers.
      until [[ "${CLIENT_DNS_SETTINGS}" =~ ^[0-9]+$ ]] && [ "${CLIENT_DNS_SETTINGS}" -ge 1 ] && [ "${CLIENT_DNS_SETTINGS}" -le 10 ]; do
        read -rp "DNS [1-10]:" -e -i 1 CLIENT_DNS_SETTINGS
      done
      # Based on the user's selection, set the DNS addresses.
      case ${CLIENT_DNS_SETTINGS} in
      1)
        # Set DNS addresses for Cloudflare.
        CLIENT_DNS_PRIMARY_IPV4_DNS="1.1.1.1"
        CLIENT_DNS_SECONDARY_IPV4_DNS="1.0.0.1"
        CLIENT_DNS_PRIMARY_IPV6_DNS="2606:4700:4700::1111"
        CLIENT_DNS_SECONDARY_IPV6_DNS="2606:4700:4700::1001"
        ;;
      2)
        # Set DNS addresses for AdGuard.
        CLIENT_DNS_PRIMARY_IPV4_DNS="94.140.14.14"
        CLIENT_DNS_SECONDARY_IPV4_DNS="94.140.15.15"
        CLIENT_DNS_PRIMARY_IPV6_DNS="2a10:50c0::ad1:ff"
        CLIENT_DNS_SECONDARY_IPV6_DNS="2a10:50c0::ad2:ff"
        ;;
      3)
        # Set DNS addresses for NextDNS.
        CLIENT_DNS_PRIMARY_IPV4_DNS="45.90.28.167"
        CLIENT_DNS_SECONDARY_IPV4_DNS="45.90.30.167"
        CLIENT_DNS_PRIMARY_IPV6_DNS="2a07:a8c0::12:cf53"
        CLIENT_DNS_SECONDARY_IPV6_DNS="2a07:a8c1::12:cf53"
        ;;
      4)
        # Set DNS addresses for OpenDNS.
        CLIENT_DNS_PRIMARY_IPV4_DNS="208.67.222.222"
        CLIENT_DNS_SECONDARY_IPV4_DNS="208.67.220.220"
        CLIENT_DNS_PRIMARY_IPV6_DNS="2620:119:35::35"
        CLIENT_DNS_SECONDARY_IPV6_DNS="2620:119:53::53"
        ;;
      5)
        # Set DNS addresses for Google.
        CLIENT_DNS_PRIMARY_IPV4_DNS="8.8.8.8"
        CLIENT_DNS_SECONDARY_IPV4_DNS="8.8.4.4"
        CLIENT_DNS_PRIMARY_IPV6_DNS="2001:4860:4860::8888"
        CLIENT_DNS_SECONDARY_IPV6_DNS="2001:4860:4860::8844"
        ;;
      6)
        # Set DNS addresses for Verisign.
        CLIENT_DNS_PRIMARY_IPV4_DNS="64.6.64.6"
        CLIENT_DNS_SECONDARY_IPV4_DNS="64.6.65.6"
        CLIENT_DNS_PRIMARY_IPV6_DNS="2620:74:1b::1:1"
        CLIENT_DNS_SECONDARY_IPV6_DNS="2620:74:1c::2:2"
        ;;
      7)
        # Set DNS addresses for Quad9.
        CLIENT_DNS_PRIMARY_IPV4_DNS="9.9.9.9"
        CLIENT_DNS_SECONDARY_IPV4_DNS="149.112.112.112"
        CLIENT_DNS_PRIMARY_IPV6_DNS="2620:fe::fe"
        CLIENT_DNS_SECONDARY_IPV6_DNS="2620:fe::9"
        ;;
      8)
        # Set DNS addresses for FDN.
        CLIENT_DNS_PRIMARY_IPV4_DNS="80.67.169.40"
        CLIENT_DNS_SECONDARY_IPV4_DNS="80.67.169.12"
        CLIENT_DNS_PRIMARY_IPV6_DNS="2001:910:800::40"
        CLIENT_DNS_SECONDARY_IPV6_DNS="2001:910:800::12"
        ;;
      9)
        # Prompt the user to enter a custom DNS address.
        read -rp "Custom primary IPv4 DNS: " CLIENT_DNS_PRIMARY_IPV4_DNS
        read -rp "Custom secondary IPv4 DNS: " CLIENT_DNS_SECONDARY_IPV4_DNS
        read -rp "Custom primary IPv6 DNS: " CLIENT_DNS_PRIMARY_IPV6_DNS
        read -rp "Custom secondary IPv6 DNS: " CLIENT_DNS_SECONDARY_IPV6_DNS
        # If the user doesn't provide a custom DNS, default to Google's DNS.
        if [ -z "${CLIENT_DNS_PRIMARY_IPV4_DNS}" ]; then
          CLIENT_DNS_PRIMARY_IPV4_DNS="8.8.8.8"
        fi
        if [ -z "${CLIENT_DNS_SECONDARY_IPV4_DNS}" ]; then
          CLIENT_DNS_SECONDARY_IPV4_DNS="8.8.4.4"
        fi
        if [ -z "${CLIENT_DNS_PRIMARY_IPV6_DNS}" ]; then
          CLIENT_DNS_PRIMARY_IPV6_DNS="2001:4860:4860::8888"
        fi
        if [ -z "${CLIENT_DNS_SECONDARY_IPV6_DNS}" ]; then
          CLIENT_DNS_SECONDARY_IPV6_DNS="2001:4860:4860::8844"
        fi
        ;;
      10)
        # If Pi-Hole is installed, use its DNS. Otherwise, install Unbound and enable the block list.
        if [ -x "$(command -v pihole)" ]; then
          CLIENT_DNS_PRIMARY_IPV4_DNS="${GATEWAY_ADDRESS_V4}"
          CLIENT_DNS_PRIMARY_IPV6_DNS="${GATEWAY_ADDRESS_V6}"
        else
          INSTALL_UNBOUND=true
          INSTALL_BLOCK_LIST=true
        fi
        ;;
      esac
    fi
  }

  # Invoke the custom_dns function to allow the user to select a DNS provider.
  custom_dns

  # Function to prompt for the name of the first OpenVPN client.
  function client_name() {
    # If CLIENT_NAME variable is not set, prompt the user for input.
    if [ -z "${CLIENT_NAME}" ]; then
      # Display naming rules to the user.
      echo "Please provide a name for the OpenVPN client. The name should be a single word, without special characters or spaces."
      # Read the user's input, offering a random string as the default name.
      read -rp "Client name:" -e -i "$(openssl rand -hex 5)" CLIENT_NAME
    fi
    # Input validation loop to ensure the name is alphanumeric.
    while [[ ! "$CLIENT_NAME" =~ ^[a-zA-Z0-9]+$ ]]; do
      echo "Invalid name. The name should contain only letters and numbers (no spaces or special characters)."
      read -rp "Client name:" -e -i "$(openssl rand -hex 5)" CLIENT_NAME
    done
    # If no name is provided by the user, assign a random string as the name.
    if [ -z "${CLIENT_NAME}" ]; then
      CLIENT_NAME="$(openssl rand -hex 5)"
    fi
  }

  # Invoke the function to prompt for the first WireGuard peer's name.
  client_name

  # Function to install Unbound, a DNS resolver, if required and not already installed.
  function install_unbound() {
    # If INSTALL_UNBOUND is true and Unbound is not installed, proceed with installation.
    if [ "${INSTALL_UNBOUND}" == true ]; then
      if [ ! -x "$(command -v unbound)" ]; then
        # Check if the root hints file does not exist.
        if [ ! -f "${UNBOUND_ROOT_HINTS}" ]; then
          # If the root hints file is missing, download it from the specified URL.
          LOCAL_UNBOUND_ROOT_HINTS_COPY=$(curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}")
        fi
        # Check if we are install unbound blocker
        if [ "${INSTALL_BLOCK_LIST}" == true ]; then
          # Check if the block list file does not exist.
          if [ ! -f "${UNBOUND_CONFIG_HOST}" ]; then
            # If the block list file is missing, download it from the specified URL.
            LOCAL_UNBOUND_BLOCKLIST_COPY=$(curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}')
          fi
        fi
        # Installation commands for Unbound vary based on the Linux distribution.
        # The following checks the distribution and installs Unbound accordingly.
        # For Debian-based distributions:
        if { [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
          apt-get install unbound unbound-host unbound-anchor -y
          # If the distribution is Ubuntu, disable systemd-resolved.
          if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
            systemctl disable --now systemd-resolved
          elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
            service systemd-resolved stop
          fi
        # For CentOS, RHEL, AlmaLinux, and Rocky:
        elif { [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ]; }; then
          yum install unbound unbound-host unbound-anchor -y
        # For Fedora:
        elif [ "${CURRENT_DISTRO}" == "fedora" ]; then
          dnf install unbound unbound-host unbound-anchor -y
        # For Arch-based distributions:
        elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
          pacman -Su --noconfirm --needed unbound
        # For Alpine Linux:
        elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
          apk add unbound unbound-host unbound-anchor
        # For FreeBSD:
        elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
          pkg install unbound unbound-host unbound-anchor
        # For Oracle Linux:
        elif [ "${CURRENT_DISTRO}" == "ol" ]; then
          yum install unbound unbound-host unbound-anchor -y
        # For Amazon Linux:
        elif [ "${CURRENT_DISTRO}" == "amzn" ]; then
          yum install unbound unbound-host unbound-anchor -y
        # For Mageia:
        elif [ "${CURRENT_DISTRO}" == "mageia" ]; then
          urpmi unbound unbound-host unbound-anchor
        # For openSUSE Tumbleweed:
        elif [ "${CURRENT_DISTRO}" == "opensuse-tumbleweed" ]; then
          zypper install -y unbound # unbound-host unbound-anchor
        fi
      fi
      # Configure Unbound to use the auto-trust-anchor-file.
      unbound-anchor -a "${UNBOUND_ANCHOR}"
      # Configure Unbound to use the root hints file.
      printf "%s" "${LOCAL_UNBOUND_ROOT_HINTS_COPY}" >"${UNBOUND_ROOT_HINTS}"
      # Configure Unbound settings.
      # The settings are stored in a temporary variable and then written to the Unbound configuration file.
      # If INSTALL_BLOCK_LIST is true, include a block list in the Unbound configuration.
      # Configure Unbound settings.
      UNBOUND_TEMP_INTERFACE_INFO="server:
\tnum-threads: $(nproc)
\tverbosity: 0
\troot-hints: ${UNBOUND_ROOT_HINTS}
\tauto-trust-anchor-file: ${UNBOUND_ANCHOR}
\tinterface: 0.0.0.0
\tinterface: ::0
\tport: 53
\tmax-udp-size: 3072
\taccess-control: 0.0.0.0/0\trefuse
\taccess-control: ::0\trefuse
\taccess-control: ${PRIVATE_SUBNET_V4}\tallow
\taccess-control: ${PRIVATE_SUBNET_V6}\tallow
\taccess-control: 127.0.0.1\tallow
\taccess-control: ::1\tallow
\tprivate-address: ${PRIVATE_SUBNET_V4}
\tprivate-address: ${PRIVATE_SUBNET_V6}
\tprivate-address: 10.0.0.0/8
\tprivate-address: 127.0.0.0/8
\tprivate-address: 169.254.0.0/16
\tprivate-address: 172.16.0.0/12
\tprivate-address: 192.168.0.0/16
\tprivate-address: ::ffff:0:0/96
\tprivate-address: fd00::/8
\tprivate-address: fe80::/10
\tdo-ip4: yes
\tdo-ip6: yes
\tdo-udp: yes
\tdo-tcp: yes
\tchroot: \"\"
\thide-identity: yes
\thide-version: yes
\tharden-glue: yes
\tharden-dnssec-stripped: yes
\tharden-referral-path: yes
\tunwanted-reply-threshold: 10000000
\tcache-min-ttl: 86400
\tcache-max-ttl: 2592000
\tprefetch: yes
\tqname-minimisation: yes
\tprefetch-key: yes"
      echo -e "${UNBOUND_TEMP_INTERFACE_INFO}" | awk '!seen[$0]++' >"${UNBOUND_CONFIG}"
      # Check if we are installing a block list.
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        # Include the block list in the Unbound configuration.
        echo -e "\tinclude: ${UNBOUND_CONFIG_HOST}" >>"${UNBOUND_CONFIG}"
      fi
      # If INSTALL_BLOCK_LIST is true, make the unbound directory.
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        # If the Unbound configuration directory does not exist, create it.
        if [ ! -d "${UNBOUND_CONFIG_DIRECTORY}" ]; then
          # Create the Unbound configuration directory.
          mkdir --parents "${UNBOUND_CONFIG_DIRECTORY}"
        fi
      fi
      # If the block list is enabled, configure Unbound to use the block list.
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        # Write the block list to the Unbound configuration block file.
        printf "%s" "${LOCAL_UNBOUND_BLOCKLIST_COPY}" >"${UNBOUND_CONFIG_HOST}"
      fi
      # Update ownership of Unbound's root directory.
      chown --recursive "${USER}":"${USER}" "${UNBOUND_ROOT}"
      # Update the resolv.conf file to use Unbound.
      if [ -f "${RESOLV_CONFIG_OLD}" ]; then
        rm --force "${RESOLV_CONFIG_OLD}"
      fi
      if [ -f "${RESOLV_CONFIG}" ]; then
        chattr -i "${RESOLV_CONFIG}"
        mv "${RESOLV_CONFIG}" "${RESOLV_CONFIG_OLD}"
      fi
      echo "nameserver 127.0.0.1" >"${RESOLV_CONFIG}"
      echo "nameserver ::1" >>"${RESOLV_CONFIG}"
      chattr +i "${RESOLV_CONFIG}"
      # Set CLIENT_DNS to use gateway addresses.
      CLIENT_DNS="${GATEWAY_ADDRESS_V4},${GATEWAY_ADDRESS_V6}"
    fi
  }

  # Call the function to install Unbound.
  install_unbound

  # Function to enable and start the haveged service.
  function enable_haveged() {
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl enable --now haveged
      systemctl start haveged
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service haveged start
    fi
  }

  # Call the function to enable and start the haveged service.
  enable_haveged

  # Function to install openvpn.
  function install_openvpn() {
    # Check if required packages are already installed
    if { [ ! -x "$(command -v openvpn)" ] || [ ! -x "$(command -v openssl)" ] || [ ! -x "$(command -v gpg)" ] || [ ! -x "$(command -v make-cadir)" ] || [ ! -x "$(command -v nft)" ]; }; then
      # Install required packages depending on the Linux distribution
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        # For Debian-based distributions, check for updates and install required packages
        apt-get update
        apt-get install openvpn openssl gnupg ca-certificates easy-rsa nftables -y
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ] || [ "${CURRENT_DISTRO}" == "amzn" ]; }; then
        # For Red Hat-based distributions, check for updates and install required packages
        yum update -y
        yum install openvpn openssl gnupg ca-certificates easy-rsa nftables -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        # Check for updates.
        pacman -Sy
        pacman -S --noconfirm --needed openvpn openssl gnupg ca-certificates easy-rsa nftables
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        # For Alpine Linux
        apk update
        apk add openvpn openssl gnupg ca-certificates easy-rsa nftables
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        # For FreeBSD, install OpenVPN and Easy-RSA
        pkg install openvpn easy-rsa -y
      elif [ "${CURRENT_DISTRO}" == "ol" ]; then
        # For Oracle Linux, install OpenVPN and Easy-RSA
        yum install openvpn easy-rsa -y
      elif [ "${CURRENT_DISTRO}" == "mageia" ]; then
        # For Mageia, install OpenVPN and Easy-RSA
        urpmi openvpn easy-rsa nftables
      elif [ "${CURRENT_DISTRO}" == "opensuse-tumbleweed" ]; then
        # For openSUSE Tumbleweed, install OpenVPN and Easy-RSA
        zypper install -y openvpn easy-rsa nftables
      fi
    fi

    # Create the easy-rsa directory if it doesn't exist.
    if [ ! -d "${OPENVPN_SERVER_EASY_RSA_DIRECTORY}" ]; then
      # Create the Easy-RSA directory.
      make-cadir ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}
      # Fix the Easy-RSA configuration variables in the vars file.
      # Uncomments and sets the EASYRSA variable to the directory containing Easy-RSA scripts.
      sed -i '0,/^#set_var EASYRSA/ s|#set_var EASYRSA|set_var EASYRSA|' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the Easy-RSA OpenSSL binary path.
      sed -i 's|#set_var EASYRSA_OPENSSL\s*"openssl"|set_var EASYRSA_OPENSSL\t"openssl"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the path to the PKI directory.
      sed -i 's|#set_var EASYRSA_PKI\s*"\$PWD/pki"|set_var EASYRSA_PKI\t"$PWD/pki"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the temporary directory variable.
      sed -i 's|#set_var EASYRSA_TEMP_DIR\s*"\$EASYRSA_PKI"|set_var EASYRSA_TEMP_DIR\t"$EASYRSA_PKI"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the Distinguished Name mode to "cn_only".
      sed -i 's|#set_var EASYRSA_DN\s*"cn_only"|set_var EASYRSA_DN\t"cn_only"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the default country for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_COUNTRY\s*"US"|set_var EASYRSA_REQ_COUNTRY\t"US"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the default province for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_PROVINCE\s*"California"|set_var EASYRSA_REQ_PROVINCE\t"California"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the default city for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_CITY\s*"San Francisco"|set_var EASYRSA_REQ_CITY\t"San Francisco"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the organization name for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_ORG\s*"Copyleft Certificate Co"|set_var EASYRSA_REQ_ORG\t"Copyleft Certificate Co"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the email address for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_EMAIL\s*"me@example.net"|set_var EASYRSA_REQ_EMAIL\t"me@example.net"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the Organizational Unit for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_OU\s*"My Organizational Unit"|set_var EASYRSA_REQ_OU\t"My Organizational Unit"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and preserves the Distinguished Name during certificate renewal.
      sed -i 's|#set_var EASYRSA_PRESERVE_DN\s*1|set_var EASYRSA_PRESERVE_DN\t1|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and disables password protection for private keys.
      sed -i 's|#set_var EASYRSA_NO_PASS\s*1|set_var EASYRSA_NO_PASS\t1|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the default key size for certificates.
      sed -i 's|#set_var EASYRSA_KEY_SIZE\s*2048|set_var EASYRSA_KEY_SIZE\t4096|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the cryptographic algorithm.
      sed -i 's|#set_var EASYRSA_ALGO\s*rsa|set_var EASYRSA_ALGO\tec|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the elliptic curve for EC certificates.
      sed -i 's|#set_var EASYRSA_CURVE\s*secp384r1|set_var EASYRSA_CURVE\tsecp384r1|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the CA certificate expiration period (in days).
      sed -i 's|#set_var EASYRSA_CA_EXPIRE\s*3650|set_var EASYRSA_CA_EXPIRE\t3650|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the certificate expiration period (in days).
      sed -i 's|#set_var EASYRSA_CERT_EXPIRE\s*825|set_var EASYRSA_CERT_EXPIRE\t825|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the CRL expiration period (in days).
      sed -i 's|#set_var EASYRSA_CRL_DAYS\s*180|set_var EASYRSA_CRL_DAYS\t180|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and enables the use of random serial numbers.
      sed -i 's|#set_var EASYRSA_RAND_SN\s*"yes"|set_var EASYRSA_RAND_SN\t"yes"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the pre-expiry notification window (in days).
      sed -i 's|#set_var EASYRSA_PRE_EXPIRY_WINDOW\s*90|set_var EASYRSA_PRE_EXPIRY_WINDOW\t90|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and disables Netscape certificate support.
      sed -i 's|#set_var EASYRSA_NS_SUPPORT\s*"no"|set_var EASYRSA_NS_SUPPORT\t"no"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the Netscape certificate comment.
      sed -i 's|#set_var EASYRSA_NS_COMMENT\s*"Easy-RSA Generated Certificate"|set_var EASYRSA_NS_COMMENT\t"Easy-RSA Generated Certificate"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the x509 extension directory.
      sed -i 's|#set_var EASYRSA_EXT_DIR\s*"\$EASYRSA/x509-types"|set_var EASYRSA_EXT_DIR\t"$EASYRSA/x509-types"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the Kerberos realm.
      sed -i 's|#set_var EASYRSA_KDC_REALM\s*"CHANGEME.EXAMPLE.COM"|set_var EASYRSA_KDC_REALM\t"CHANGEME.EXAMPLE.COM"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the SSL configuration file path.
      sed -i 's|#set_var EASYRSA_SSL_CONF\s*"\$EASYRSA_PKI/openssl-easyrsa.cnf"|set_var EASYRSA_SSL_CONF\t"$EASYRSA_PKI/openssl-easyrsa.cnf"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets the default digest algorithm for certificates.
      sed -i 's|#set_var EASYRSA_DIGEST\s*"sha256"|set_var EASYRSA_DIGEST\t"sha256"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
      # Uncomments and sets batch mode to an empty string.
      sed -i 's|#set_var EASYRSA_BATCH\s*""|set_var EASYRSA_BATCH\t"yes"|g' ${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}
    fi
    # Change the working directory to the Easy-RSA directory.
    cd ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}
    # Initialize the Public Key Infrastructure (PKI) directory, setting up the necessary structure for key and certificate management. (pki)
    ${OPENVPN_SERVER_EASY_RSA_SCRIPT} --pki-dir=${OPENVPN_PKI_DIRECTORY} init-pki
    # Build the Certificate Authority (CA). This creates the root certificate and private key for signing other certificates. (ca.crt)
    ${OPENVPN_SERVER_EASY_RSA_SCRIPT} --pki-dir=${OPENVPN_PKI_DIRECTORY} --vars=${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE} build-ca nopass
    # Build a server certificate for OpenVPN with Easy-RSA, skipping the passphrase. This generates the server's public certificate and private key. (server.crt and server.key)
    ${OPENVPN_SERVER_EASY_RSA_SCRIPT} --pki-dir=${OPENVPN_PKI_DIRECTORY} --vars=${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE} build-server-full server nopass
    # These parameters enhance the security of the connection by enabling Perfect Forward Secrecy (PFS). (ta.key)
    # ${OPENVPN_SERVER_EASY_RSA_SCRIPT} --pki-dir=${OPENVPN_PKI_DIRECTORY} --vars=${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE} gen-dh
    openssl dhparam -dsaparam -out ${OPENVPN_SERVER_DIFFIE_HELLMAN_PARAMETERS} 4096
    # Generate a certificate revocation list (CRL) for OpenVPN using Easy-RSA. This list is used to revoke certificates that are no longer valid. (crl.pem)
    ${OPENVPN_SERVER_EASY_RSA_SCRIPT} --pki-dir=${OPENVPN_PKI_DIRECTORY} --vars=${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE} gen-crl
    # Make the (crt.pem) file readable by the OpenVPN server.
    chmod 644 ${OPENVPN_SERVER_SSL_CERTIFICATE_REVOCATION_LIST}
    # Copy the (crt.pem) file to the OpenVPN directory.
    ln ${OPENVPN_SERVER_SSL_CERTIFICATE_REVOCATION_LIST} ${OPENVPN_SERVER_SSL_CERTIFICATE_REVOCATION_LIST_LINK}
    # Generate the TLS Auth Key
    openvpn --genkey secret ${OPENVPN_SERVER_TLS_CRYPT_KEY}

    # Check the path to the bash binary
    BASH_BINARY_PATH=$(which bash)

    # Create the OpenVPN server configuration file with the specified settings.
    OPEN_VPN_SERVER_CONFIG="# - Network Interface & Port Settings -

# Listen on all available interfaces (IPv6 & IPv4 via dual-stack)
local 0.0.0.0 # ${SERVER_HOST}
# Use port ${SERVER_PORT} for incoming VPN connections
port ${SERVER_PORT}
# Use UDP over IPv6 (dual-stack will allow IPv4 if IPV6_V6ONLY is disabled)
proto ${PRIMARY_PROTOCOL}
# Create a routed IP tunnel (tun); use \"tap\" if you require bridging
dev tun

# - VPN IP Addressing & Routing -

# Define the IPv4 pool for clients (${PRIVATE_SUBNET_V4})
server ${PRIVATE_SUBNET_V4} 255.255.255.0
# Define the IPv6 pool for clients (a standard /64 subnet)
server-ipv6 ${GATEWAY_ADDRESS_V6}/64
# Use subnet topology for individual client IP assignment
topology subnet
# Push IPv6 support to connecting clients
push \"tun-ipv6\"
# Redirect all IPv6 traffic through the VPN tunnel
push \"redirect-gateway ipv6\"
# Push route for globally routable IPv6 addresses (covers 2000::/3)
push \"route-ipv6 2000::/3\"
# Provide primary IPv4 DNS server (Cloudflare) to clients
push \"dhcp-option DNS 1.1.1.1\"
# Provide secondary IPv4 DNS server (Cloudflare) to clients
push \"dhcp-option DNS 1.0.0.1\"
# Provide primary IPv6 DNS server (Cloudflare) to clients
push \"dhcp-option DNS 2606:4700:4700::1111\"
# Provide secondary IPv6 DNS server (Cloudflare) to clients
push \"dhcp-option DNS 2606:4700:4700::1001\"
# Redirect all IPv4 traffic through the VPN while bypassing local DHCP
push \"redirect-gateway def1 bypass-dhcp\"
# Prevent DNS leaks on Windows clients by blocking external DNS
push \"block-outside-dns\"

# - Client Configuration & Persistence -

# Specify the directory for per-client configuration files
client-config-dir ${OPENVPN_SERVER_CLIENT_DIRECTORY}
# Do not re-read key files on restart (speeds up reconnections)
persist-key
# Keep the tunnel device open across restarts
persist-tun
# Persist client IP assignments between sessions
ifconfig-pool-persist ${IFCONFIG_POOL_PERSIST_FILE}

# - Certificate & Key Files -

# Path to the Certificate Authority (CA) certificate
ca ${OPENVPN_SERVER_CERTIFICATE_AUTHORITY}
# Path to the servers certificate
cert ${OPENVPN_SERVER_SSL_CERTIFICATE}
# Path to the servers private key
key ${OPENVPN_SERVER_SSL_KEY}
# Path to Diffie-Hellman parameters for key exchange
dh ${OPENVPN_SERVER_DIFFIE_HELLMAN_PARAMETERS}
# Verify client certificates against this CRL
crl-verify ${OPENVPN_SERVER_SSL_CERTIFICATE_REVOCATION_LIST_LINK}

# - TLS & Cryptographic Settings -

# Use tls-crypt for control channel encryption/authentication (requires OpenVPN 2.5+)
tls-crypt ${OPENVPN_SERVER_TLS_CRYPT_KEY}
# Enable TLS server mode for secure client connections
tls-server
# Enforce TLS 1.3 for the best available security
tls-version-min 1.3
# Specify the TLS cipher for the control channel
tls-cipher ${CONTROL_CHANNEL_ENCRYPTION}
# Use ${DATA_CHIPER} for data channel encryption (modern and fast)
cipher ${DATA_CHIPER}
# Allow ${DATA_CHANNEL_ENCRYPTION} for data channel encryption (fast and secure)
data-ciphers ${DATA_CHANNEL_ENCRYPTION}
# Use the ${CERTIFICATE_ECDSA_CURVE} elliptic curve for ECDH key exchange (provides strong security)
tls-groups ${CERTIFICATE_ECDSA_CURVE}
# Use ${HMAC_ALGORITHM} for HMAC message authentication to ensure data integrity
auth ${HMAC_ALGORITHM}
# - Connection & Performance Settings -

# Enable fast I/O to improve performance by reducing system calls
fast-io
# Ping every 10 seconds; mark connection down after 60 seconds without a response
keepalive 10 60
# Force key renegotiation every 3600 seconds (1 hour) for forward secrecy
reneg-sec 3600
# Send explicit exit notifications to clients upon server restart or shutdown
explicit-exit-notify 2

# - Security Enhancements -

# Drop privileges to the \"nobody\" user after initialization for improved security
user nobody
# Drop privileges to the \"nogroup\" group after initialization for improved security
group nogroup
# Allow execution of external scripts with safe restrictions
script-security 2
# Enable IP forwarding when OpenVPN starts
up \"${BASH_BINARY_PATH} -c 'sudo bash ${CURRENT_FILE_PATH} --firewall'\"
# Disable IP forwarding when OpenVPN stops
down \"${BASH_BINARY_PATH} -c 'sudo bash ${CURRENT_FILE_PATH} --firewall'\"

# - Logging & Debugging -

# Disable logging (no logs will be written)
verb 0"

    # Put the server config into the server config file.
    echo -e "${OPEN_VPN_SERVER_CONFIG}" | awk '!seen[$0]++' >${OPENVPN_SERVER_CONFIG}

    # Delete the OpenVPN client configuration directory if it exist.
    if [ -d "${OPENVPN_SERVER_CLIENT_DIRECTORY}" ]; then
      rm -rf ${OPENVPN_SERVER_CLIENT_DIRECTORY}
    fi
    # Create the OpenVPN client configuration directory if it doesn't exist.
    if [ ! -d "${OPENVPN_SERVER_CLIENT_DIRECTORY}" ]; then
      mkdir --parents ${OPENVPN_SERVER_CLIENT_DIRECTORY}
    fi
    # Manage the service based on the init system
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl enable --now nftables
      systemctl enable --now openvpn-server@server.service
      if [ "${INSTALL_UNBOUND}" == true ]; then
        systemctl enable --now unbound
        systemctl restart unbound
      fi
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service nftables start
      service openvpn-server@server.service start
      if [ "${INSTALL_UNBOUND}" == true ]; then
        service unbound restart
      fi
    fi

    # Generate the client certificate and key.
    ${OPENVPN_SERVER_EASY_RSA_SCRIPT} --pki-dir=${OPENVPN_PKI_DIRECTORY} --vars=${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE} build-client-full "${CLIENT_NAME}" nopass

    # Read the content of the certificate authority (CA) file into a variable
    OPENVPN_SERVER_CERTIFICATE_AUTHORITY_CONTENT=$(cat ${OPENVPN_SERVER_CERTIFICATE_AUTHORITY})
    # Extract and store the content of the client certificate (specified by CLIENT_NAME) from the .crt file
    OPENVPN_SERVER_CLIENT_CERTIFICATE_CONTENT=$(awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' /etc/openvpn/easy-rsa/pki/issued/"${CLIENT_NAME}".crt)
    # Read the content of the private key for the client (specified by CLIENT_NAME) into a variable
    OPENVPN_SERVER_CLIENT_CERTIFICATE_KEY_CONTENT=$(cat /etc/openvpn/easy-rsa/pki/private/"${CLIENT_NAME}".key)
    # Read the content of the TLS crypt key into a variable
    OPENVPN_SERVER_TLS_CRYPT_KEY_CONTENT=$(cat ${OPENVPN_SERVER_TLS_CRYPT_KEY})

    # Create the OpenVPN client configuration file with the specified settings.
    OPEN_VPN_CLIENT_CONFIG="# - Client Basic Settings -
#
client
# Specify the OpenVPN protocol and use UDP for better performance
proto ${PRIMARY_PROTOCOL}
# Define the remote server IP or hostname and the port number
remote ${SERVER_HOST} ${SERVER_PORT}
# Use a tunnel device (tun) instead of an ethernet bridge (tap)
dev tun

# - Cryptographic & Security Settings -

# Enable TLS client mode to establish a secure connection
tls-client
# Verify that the server certificate is signed by a valid CA
remote-cert-tls server
# Enforce TLS 1.3 for stronger security
tls-version-min 1.3
# Specify the TLS cipher suite for the control channel
tls-cipher ${CONTROL_CHANNEL_ENCRYPTION}
# Use ${DATA_CHANNEL_ENCRYPTION} for data encryption (fast and secure)
cipher ${DATA_CHANNEL_ENCRYPTION}
# Use ${HMAC_ALGORITHM} for HMAC message authentication to ensure data integrity
auth ${HMAC_ALGORITHM}

# - Connection Settings -

# Do not bind to a specific local port (let the OS choose)
nobind
# Send a ping every 10 seconds; disconnect if no response within 60 seconds
keepalive 10 60

# - Routing & DNS -

# Redirect all IPv4 traffic through the VPN tunnel
redirect-gateway def1
# Redirect all IPv6 traffic through the VPN tunnel
redirect-gateway ipv6
# Ensure DNS queries go through the VPN (prevents leaks)
setenv opt block-outside-dns
# Route all domain-based queries through the VPN
dhcp-option DOMAIN-ROUTE .
# Use Cloudflare DNS for better privacy and security
dhcp-option DNS 1.1.1.1  # Primary IPv4 DNS
dhcp-option DNS 1.0.0.1  # Secondary IPv4 DNS
dhcp-option DNS 2606:4700:4700::1111  # Primary IPv6 DNS
dhcp-option DNS 2606:4700:4700::1001  # Secondary IPv6 DNS
# If the VPN server does not support IPv6, ignore IPv6-related settings
pull-filter ignore \"route-ipv6\"
pull-filter ignore \"ifconfig-ipv6\"

# - Low-Power Mode for Mobile Devices -

# Automatically disconnect if inactive for 15 minutes (900 seconds)
inactive 900

# - Compression & Logging -

# Set logging verbosity (increase for debugging, lower for less output)
verb 0

# - Embedded Certificates & Keys -

# The CA certificate verifies the servers certificate and ensures its signed by a trusted authority
<ca>
${OPENVPN_SERVER_CERTIFICATE_AUTHORITY_CONTENT}
</ca>
# The client certificate authenticates the client to the server during the TLS handshake
<cert>
${OPENVPN_SERVER_CLIENT_CERTIFICATE_CONTENT}
</cert>
# The client private key proves ownership of the client certificate during the TLS handshake
<key>
${OPENVPN_SERVER_CLIENT_CERTIFICATE_KEY_CONTENT}
</key>
# The TLS-crypt key secures the control channel and protects against attacks like DoS and traffic analysis
<tls-crypt>
${OPENVPN_SERVER_TLS_CRYPT_KEY_CONTENT}
</tls-crypt>"
    # Put the client config into the client config file.
    echo -e "${OPEN_VPN_CLIENT_CONFIG}" >"${OPENVPN_SERVER_CLIENT_DIRECTORY}/${CLIENT_NAME}.ovpn"
    echo "The OpenVPN client config is saved at ${OPENVPN_SERVER_CLIENT_DIRECTORY}/${CLIENT_NAME}.ovpn"
  }

  # Install openvpn
  install_openvpn

# If oepnvpn config is found than lets manage it using the manager
else

  # Function to display openvpn configuration
  function display_openvpn_config() {
    # Display the OpenVPN configuration file
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl status openvpn-server@server.service
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service openvpn-server@server.service status
    fi
  }

  # Function to start the OpenVPN service
  function start_openvpn_service() {
    # Start the OpenVPN service
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl start openvpn-server@server.service
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service openvpn-server@server.service start
    fi
  }

  # Function to stop the OpenVPN service
  function stop_openvpn_service() {
    # Stop the OpenVPN service
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl stop openvpn-server@server.service
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service openvpn-server@server.service stop
    fi
  }

  # Function to restart the OpenVPN service
  function restart_openvpn_service() {
    # Restart the OpenVPN service
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl restart openvpn-server@server.service
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service openvpn-server@server.service restart
    fi
  }

  # Function to add a new OpenVPN client
  function add_openvpn_client() {
    # Generate the client certificate and key.
    # If a client name isn't supplied, the script will request one
    if [ -z "${NEW_CLIENT_NAME}" ]; then
      echo "Let's name the OpenVPN Peer. Use one word only, no special characters, no spaces."
      read -rp "New client peer:" -e -i "$(openssl rand -hex 5)" NEW_CLIENT_NAME
    fi
    # Input validation loop to ensure the name is alphanumeric.
    while [[ ! "$NEW_CLIENT_NAME" =~ ^[a-zA-Z0-9]+$ ]]; do
      echo "Invalid name. The name should contain only letters and numbers (no spaces or special characters)."
      read -rp "Client name:" -e -i "$(openssl rand -hex 5)" NEW_CLIENT_NAME
    done
    # If no client name is provided, use openssl to generate a random name
    if [ -z "${NEW_CLIENT_NAME}" ]; then
      NEW_CLIENT_NAME="$(openssl rand -hex 5)"
    fi
    # Generate the client certificate and key.
    ${OPENVPN_SERVER_EASY_RSA_SCRIPT} --pki-dir=${OPENVPN_PKI_DIRECTORY} --vars=${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE} build-client-full "${NEW_CLIENT_NAME}" nopass
    # Read the content of the certificate authority (CA) file into a variable
    OPENVPN_SERVER_CERTIFICATE_AUTHORITY_CONTENT=$(cat ${OPENVPN_SERVER_CERTIFICATE_AUTHORITY})
    # Extract and store the content of the client certificate (specified by CLIENT_NAME) from the .crt file
    OPENVPN_SERVER_CLIENT_CERTIFICATE_CONTENT=$(awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/' /etc/openvpn/easy-rsa/pki/issued/"${NEW_CLIENT_NAME}".crt)
    # Read the content of the private key for the client (specified by CLIENT_NAME) into a variable
    OPENVPN_SERVER_CLIENT_CERTIFICATE_KEY_CONTENT=$(cat /etc/openvpn/easy-rsa/pki/private/"${NEW_CLIENT_NAME}".key)
    # Read the content of the TLS crypt key into a variable
    OPENVPN_SERVER_TLS_CRYPT_KEY_CONTENT=$(cat ${OPENVPN_SERVER_TLS_CRYPT_KEY})
    # Extract the current port used the server.
    OPENVPN_SERVER_PORT_EXTRACT=$(grep -E "^port [0-9]+" ${OPENVPN_SERVER_CONFIG} | awk '{print $2}')
    # Extract the current protocol used by the server.
    OPENVPN_SERVER_PROTOCOL_EXTRACT=$(grep -E "^proto [a-z0-9]+" ${OPENVPN_SERVER_CONFIG} | awk '{print $2}')
    # Extract the current IP used by the server.
    OPENVPN_SERVER_IP_EXTRACT=$(grep "^local" ${OPENVPN_SERVER_CONFIG} | awk -F'#' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    # Create the OpenVPN client configuration file with the specified settings.
    OPEN_VPN_CLIENT_CONFIG="# - Client Basic Settings -
#
client
# Specify the OpenVPN protocol and use UDP for better performance
proto ${OPENVPN_SERVER_PROTOCOL_EXTRACT}
# Define the remote server IP or hostname and the port number
remote ${OPENVPN_SERVER_IP_EXTRACT} ${OPENVPN_SERVER_PORT_EXTRACT}
# Use a tunnel device (tun) instead of an ethernet bridge (tap)
dev tun

# - Cryptographic & Security Settings -

# Enable TLS client mode to establish a secure connection
tls-client
# Verify that the server certificate is signed by a valid CA
remote-cert-tls server
# Enforce TLS 1.3 for stronger security
tls-version-min 1.3
# Specify the TLS cipher suite for the control channel
tls-cipher ${CONTROL_CHANNEL_ENCRYPTION}
# Use ${DATA_CHANNEL_ENCRYPTION} for data encryption (fast and secure)
cipher ${DATA_CHANNEL_ENCRYPTION}
# Use ${HMAC_ALGORITHM} for HMAC message authentication to ensure data integrity
auth ${HMAC_ALGORITHM}

# - Connection Settings -

# Do not bind to a specific local port (let the OS choose)
nobind
# Send a ping every 10 seconds; disconnect if no response within 60 seconds
keepalive 10 60

# - Routing & DNS -

# Redirect all IPv4 traffic through the VPN tunnel
redirect-gateway def1
# Redirect all IPv6 traffic through the VPN tunnel
redirect-gateway ipv6
# Ensure DNS queries go through the VPN (prevents leaks)
setenv opt block-outside-dns
# Route all domain-based queries through the VPN
dhcp-option DOMAIN-ROUTE .
# Use Cloudflare DNS for better privacy and security
dhcp-option DNS 1.1.1.1  # Primary IPv4 DNS
dhcp-option DNS 1.0.0.1  # Secondary IPv4 DNS
dhcp-option DNS 2606:4700:4700::1111  # Primary IPv6 DNS
dhcp-option DNS 2606:4700:4700::1001  # Secondary IPv6 DNS
# If the VPN server does not support IPv6, ignore IPv6-related settings
pull-filter ignore \"route-ipv6\"
pull-filter ignore \"ifconfig-ipv6\"

# - Low-Power Mode for Mobile Devices -

# Automatically disconnect if inactive for 15 minutes (900 seconds)
inactive 900

# - Compression & Logging -

# Set logging verbosity (increase for debugging, lower for less output)
verb 0

# - Embedded Certificates & Keys -

# The CA certificate verifies the servers certificate and ensures its signed by a trusted authority
<ca>
${OPENVPN_SERVER_CERTIFICATE_AUTHORITY_CONTENT}
</ca>
# The client certificate authenticates the client to the server during the TLS handshake
<cert>
${OPENVPN_SERVER_CLIENT_CERTIFICATE_CONTENT}
</cert>
# The client private key proves ownership of the client certificate during the TLS handshake
<key>
${OPENVPN_SERVER_CLIENT_CERTIFICATE_KEY_CONTENT}
</key>
# The TLS-crypt key secures the control channel and protects against attacks like DoS and traffic analysis
<tls-crypt>
${OPENVPN_SERVER_TLS_CRYPT_KEY_CONTENT}
</tls-crypt>"
    # Put the client config into the client config file.
    echo -e "${OPEN_VPN_CLIENT_CONFIG}" >"${OPENVPN_SERVER_CLIENT_DIRECTORY}/${NEW_CLIENT_NAME}.ovpn"
    echo "The OpenVPN client config is saved at ${OPENVPN_SERVER_CLIENT_DIRECTORY}/${NEW_CLIENT_NAME}.ovpn"
  }

  # Function to remove an OpenVPN client
  function remove_openvpn_client() {
    # Count the number of installed OpenVPN clients
    NUMBER_OF_CLIENTS_INSTALLED=$(tail --lines=+2 "${OPENVPN_SERVER_CERTIFICATE_INDEX}" | grep --count "^V")
    # Check if there are any clients installed
    if [[ "${NUMBER_OF_CLIENTS_INSTALLED}" == "0" ]]; then
      echo "Error: No OpenVPN clients found."
      exit
    fi
    echo "Which OpenVPN client would you like to remove?"
    # List all clients with numbers for selection
    CLIENTS=($(tail --lines=+2 "${OPENVPN_SERVER_CERTIFICATE_INDEX}" | awk -F'/CN=' '/^V/ {print $2}'))
    # Display the clients with a numbered list
    PS3="Select a client (enter the number): "
    select CLIENT_NAME in "${CLIENTS[@]}"; do
      if [[ -n "$CLIENT_NAME" ]]; then
        break
      else
        echo "Invalid selection. Please choose a valid number."
      fi
    done
    # Revoke the client certificate
    "${OPENVPN_SERVER_EASY_RSA_SCRIPT}" --pki-dir="${OPENVPN_PKI_DIRECTORY}" --vars="${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}" revoke "${CLIENT_NAME}"
    # Remove the client .ovpn file
    rm -f "${OPENVPN_SERVER_CLIENT_DIRECTORY}/${CLIENT_NAME}.ovpn"
    echo "OpenVPN client '${CLIENT_NAME}' has been successfully removed."
  }

  # Function to uninstall the OpenVPN service
  function uninstall_openvpn() {
    # Uninstall the OpenVPN service
    # Check if required packages are already installed
    if { [ -x "$(command -v openvpn)" ] || [ -x "$(command -v openssl)" ] || [ -x "$(command -v gpg)" ] || [ -x "$(command -v make-cadir)" ] || [ -x "$(command -v nft)" ]; }; then
      # Install required packages depending on the Linux distribution
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ] || [ "${CURRENT_DISTRO}" == "pop" ] || [ "${CURRENT_DISTRO}" == "kali" ] || [ "${CURRENT_DISTRO}" == "linuxmint" ] || [ "${CURRENT_DISTRO}" == "neon" ]; }; then
        apt-get update
        apt-get remove --purge openvpn openssl gnupg ca-certificates easy-rsa nftables -y
      elif { [ "${CURRENT_DISTRO}" == "fedora" ] || [ "${CURRENT_DISTRO}" == "centos" ] || [ "${CURRENT_DISTRO}" == "rhel" ] || [ "${CURRENT_DISTRO}" == "almalinux" ] || [ "${CURRENT_DISTRO}" == "rocky" ] || [ "${CURRENT_DISTRO}" == "amzn" ]; }; then
        yum check-update
        yum remove --purge openvpn openssl gnupg ca-certificates easy-rsa nftables -y
      elif { [ "${CURRENT_DISTRO}" == "arch" ] || [ "${CURRENT_DISTRO}" == "archarm" ] || [ "${CURRENT_DISTRO}" == "manjaro" ]; }; then
        pacman -Syu --noconfirm
        pacman -R --noconfirm openvpn openssl gnupg ca-certificates easy-rsa nftables
      elif [ "${CURRENT_DISTRO}" == "alpine" ]; then
        apk update
        apk del openvpn openssl gnupg ca-certificates easy-rsa nftables
      elif [ "${CURRENT_DISTRO}" == "freebsd" ]; then
        pkg update
        pkg purge --yes openvpn openssl gnupg ca-certificates easy-rsa nftables
      elif [ "${CURRENT_DISTRO}" == "ol" ]; then
        yum check-update
        yum remove --purge openvpn openssl gnupg ca-certificates easy-rsa nftables -y
      elif [ "${CURRENT_DISTRO}" == "mageia" ]; then
        urpmi.update -a
        yes | urpmi --remove openvpn openssl gnupg ca-certificates easy-rsa nftables
      elif [ "${CURRENT_DISTRO}" == "opensuse-tumbleweed" ]; then
        # For OpenSUSE Tumbleweed, update package lists and install required packages
        zypper refresh
        zypper remove --clean-deps --yes openvpn openssl gnupg ca-certificates easy-rsa nftables
      fi
    fi
  }

  # Function to update the OpenVPN management script
  function update_openvpn_script() {
    # Update the OpenVPN management script
    # Update OpenVPN Manager script.
    # Calculate the SHA3-512 hash of the current OpenVPN Manager script
    CURRENT_OPENVPN_MANAGER_HASH=$(openssl dgst -sha3-512 "${CURRENT_FILE_PATH}" | cut --delimiter=" " --fields=2)
    # Calculate the SHA3-512 hash of the latest OpenVPN Manager script from the remote source
    NEW_OPENVPN_MANAGER_HASH=$(curl --silent "${OPENVPN_MANAGER_UPDATE}" | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
    # If the hashes don't match, update the local OpenVPN Manager script
    if [ "${CURRENT_OPENVPN_MANAGER_HASH}" != "${NEW_OPENVPN_MANAGER_HASH}" ]; then
      curl "${OPENVPN_MANAGER_UPDATE}" -o "${CURRENT_FILE_PATH}"
      chmod +x "${CURRENT_FILE_PATH}"
      echo "Updating OpenVPN Manager script..."
    fi

    # Update the Unbound DNS server configuration if Unbound is installed
    if [ -x "$(command -v unbound)" ]; then
      # Update the Unbound root hints file if it exists
      if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
        CURRENT_ROOT_HINTS_HASH=$(openssl dgst -sha3-512 "${UNBOUND_ROOT_HINTS}" | cut --delimiter=" " --fields=2)
        NEW_ROOT_HINTS_HASH=$(curl --silent "${UNBOUND_ROOT_SERVER_CONFIG_URL}" | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
        if [ "${CURRENT_ROOT_HINTS_HASH}" != "${NEW_ROOT_HINTS_HASH}" ]; then
          curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}" -o "${UNBOUND_ROOT_HINTS}"
          echo "Updating Unbound root hints file..."
          LOCAL_RESTART_UNBOUND=true
        fi
      fi

      # Update the Unbound configuration hosts file if it exists
      if [ -f "${UNBOUND_CONFIG_HOST}" ]; then
        CURRENT_UNBOUND_HOSTS_HASH=$(openssl dgst -sha3-512 "${UNBOUND_CONFIG_HOST}" | cut --delimiter=" " --fields=2)
        NEW_UNBOUND_HOSTS_HASH=$(curl --silent "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' | openssl dgst -sha3-512 | cut --delimiter=" " --fields=2)
        if [ "${CURRENT_UNBOUND_HOSTS_HASH}" != "${NEW_UNBOUND_HOSTS_HASH}" ]; then
          curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' >"${UNBOUND_CONFIG_HOST}"
          echo "Updating Unbound configuration host file..."
          LOCAL_RESTART_UNBOUND=true
        fi
      fi

      # Restart Unbound service if necessary
      if [ "${LOCAL_RESTART_UNBOUND}" == "true" ]; then
        if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
          systemctl restart unbound
          echo "Restarting Unbound service..."
        elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
          service unbound restart
          echo "Restarting Unbound service..."
        fi
      fi
    fi

  }

  # Function to backup the OpenVPN configuration
  function backup_openvpn_config() {
    # If the OpenVPN config backup file exists, remove it
    if [ -f "${OPENVPN_CONFIG_BACKUP}" ]; then
      rm --force "${OPENVPN_CONFIG_BACKUP}"
      echo "Removing existing backup..."
    fi
    # If the system backup path directory does not exist, create it along with any necessary parent directories
    if [ ! -d "${SYSTEM_BACKUP_PATH}" ]; then
      mkdir --parents "${SYSTEM_BACKUP_PATH}"
      echo "Creating backup directory..."
    fi
    # If the OpenVPN path directory exists, proceed with the backup process
    if [ -d "${OPENVPN_PATH}" ]; then
      # Generate a random 50-character hexadecimal backup password and store it in a file
      BACKUP_PASSWORD="$(openssl rand -hex 10)"
      echo "${BACKUP_PASSWORD}" >"${OPENVPN_BACKUP_PASSWORD_PATH}"
      # Zip the OpenVPN config file using the generated backup password and save it as a backup
      zip -P "${BACKUP_PASSWORD}" -rj "${OPENVPN_CONFIG_BACKUP}" "${OPENVPN_CONFIG}"
      # Echo the backup password and path to the terminal
      echo "Backup Password: ${BACKUP_PASSWORD}"
      echo "Backup Path: ${OPENVPN_CONFIG_BACKUP}"
      echo "Please save the backup password and path in a secure location."
    fi
  }

  # Function to restore the OpenVPN configuration
  function restore_openvpn_config() {
    # Check if the OpenVPN config backup file does not exist, and if so, exit the script
    if [ ! -f "${OPENVPN_CONFIG_BACKUP}" ]; then
      echo "Error: The OpenVPN configuration backup file could not be found. Please ensure it exists and try again."
      exit
    fi
    # Prompt the user to enter the backup password and store it in the OPENVPN_BACKUP_PASSWORD variable
    read -rp "Backup Password: " -e -i "$(cat "${OPENVPN_BACKUP_PASSWORD_PATH}")" OPENVPN_BACKUP_PASSWORD
    # If the OPENVPN_BACKUP_PASSWORD variable is empty, exit the script
    if [ -z "${OPENVPN_BACKUP_PASSWORD}" ]; then
      echo "Error: The backup password field is empty. Please provide a valid password."
      exit
    fi
    # Unzip the backup file, overwriting existing files, using the specified backup password, and extract the contents to the OpenVPN path
    unzip -o -P "${OPENVPN_BACKUP_PASSWORD}" "${OPENVPN_CONFIG_BACKUP}" -d "${OPENVPN_PATH}"
    # If the current init system is systemd, enable and start the OpenVPN service
    if [[ "${CURRENT_INIT_SYSTEM}" == *"systemd"* ]]; then
      systemctl enable --now openvpn-server@server.service
    # If the current init system is init, restart the OpenVPN service
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service openvpn-server@server.service start
    fi
  }

  # Function to update the OpenVPN interface IP
  function update_openvpn_interface_ip() {
    echo "How would you like to update the IP address?"
    echo "  1) Automatically detect the current IP"
    echo "  2) Manually specify the IP"
    # Prompt the user until they enter a valid choice
    until [[ "${IP_UPDATE_METHOD}" =~ ^[1-2]$ ]]; do
      read -rp "Update Method [1-2]:" -e -i 1 IP_UPDATE_METHOD
    done
    case ${IP_UPDATE_METHOD} in
    1)
      # Automatically detect the current IP address of the OpenVPN interface
      get_network_information
      # Extract the current IP address from the OpenVPN config file
      CURRENT_IP_METHOD=$(grep "^local" ${OPENVPN_SERVER_CONFIG} | sed 's/.*#\s*\(.*\)/\1/')
      # If the current IP address is IPv4, set the new server IP to the DEFAULT_INTERFACE_IPV4
      if [[ ${CURRENT_IP_METHOD} != *"["* ]]; then
        OLD_SERVER_HOST=$(grep "^local" ${OPENVPN_SERVER_CONFIG} | sed 's/.*#\s*\(.*\)/\1/')
        NEW_SERVER_HOST=${DEFAULT_INTERFACE_IPV4}
      fi
      # If the current IP address is IPv6, set the new server IP to the DEFAULT_INTERFACE_IPV6
      if [[ ${CURRENT_IP_METHOD} == *"["* ]]; then
        OLD_SERVER_HOST=$(grep "^local" ${OPENVPN_SERVER_CONFIG} | sed 's/.*#\s*\(.*\)/\1/')
        NEW_SERVER_HOST=${DEFAULT_INTERFACE_IPV6}
      fi
      # If the old server host is different from the new one, update the OpenVPN config
      ESCAPED_OLD_SERVER_HOST=$(echo "$OLD_SERVER_HOST" | sed 's/[&/\]/\\&/g')
      if [ "${ESCAPED_OLD_SERVER_HOST}" != "${NEW_SERVER_HOST}" ]; then
        echo "The server IP address in the configuration file ${OPENVPN_SERVER_CONFIG} has been updated to ${NEW_SERVER_HOST}"
        sed --in-place "s#${ESCAPED_OLD_SERVER_HOST}#${NEW_SERVER_HOST}#" ${OPENVPN_SERVER_CONFIG}
      fi
      # Find all .ovpn files and store them in the COMPLETE_CLIENT_LIST array
      COMPLETE_CLIENT_LIST=$(find ${OPENVPN_SERVER_CLIENT_DIRECTORY} -type f -name "*.ovpn")
      # Loop through the array and print each file path
      for CLIENT_PATH in "${COMPLETE_CLIENT_LIST[@]}"; do
        # If the old server host is different from the new one, update the OpenVPN config
        if [ "${ESCAPED_OLD_SERVER_HOST}" != "${NEW_SERVER_HOST}" ]; then
          echo "The server IP address in the configuration file ${CLIENT_PATH} has been updated to ${NEW_SERVER_HOST}"
          sed --in-place "s#${ESCAPED_OLD_SERVER_HOST}#${NEW_SERVER_HOST}#" "${CLIENT_PATH}"
        fi
      done
      ;;
    2)
      # Manually specify the new IP
      read -rp "Enter the new server IP address:" NEW_SERVER_HOST
      if [ -z "${NEW_SERVER_HOST}" ]; then
        echo "No IP address provided. Aborting."
        exit
      fi
      # If the old server host is different from the new one, update the OpenVPN config
      ESCAPED_OLD_SERVER_HOST=$(echo "$OLD_SERVER_HOST" | sed 's/[&/\]/\\&/g')
      if [ "${ESCAPED_OLD_SERVER_HOST}" != "${NEW_SERVER_HOST}" ]; then
        echo "The server IP address in the configuration file ${OPENVPN_SERVER_CONFIG} has been updated to ${NEW_SERVER_HOST}"
        sed --in-place "s#${ESCAPED_OLD_SERVER_HOST}#${NEW_SERVER_HOST}#" ${OPENVPN_SERVER_CONFIG}
      fi
      # Find all .ovpn files and store them in the COMPLETE_CLIENT_LIST array
      COMPLETE_CLIENT_LIST=$(find ${OPENVPN_SERVER_CLIENT_DIRECTORY} -type f -name "*.ovpn")
      # Loop through the array and print each file path
      for CLIENT_PATH in "${COMPLETE_CLIENT_LIST[@]}"; do
        # If the old server host is different from the new one, update the OpenVPN config
        if [ "${ESCAPED_OLD_SERVER_HOST}" != "${NEW_SERVER_HOST}" ]; then
          echo "The server IP address in the configuration file ${CLIENT_PATH} has been updated to ${NEW_SERVER_HOST}"
          sed --in-place "s#${ESCAPED_OLD_SERVER_HOST}#${NEW_SERVER_HOST}#" "${CLIENT_PATH}"
        fi
      done
      ;;
    esac
  }

  # Function to update the OpenVPN interface port
  function update_openvpn_interface_port() {
    # Update the OpenVPN interface port
    # If the user selects option 2, prompt for a custom port
    # Continue prompting until a valid port (1–65535) is provided
    until [[ "${NEW_OPENVPN_PORT}" =~ ^[0-9]+$ ]] && [ "${NEW_OPENVPN_PORT}" -ge 1 ] && [ "${NEW_OPENVPN_PORT}" -le 65535 ]; do
      # Ask the user to input a custom port number, with 1194 as the default option
      read -rp "Custom port [1-65535]: " -e -i 1194 NEW_OPENVPN_PORT
    done
    # If no input is provided for the custom port, default to 1194
    if [ -z "${NEW_OPENVPN_PORT}" ]; then
      NEW_OPENVPN_PORT="1194" # Default port for OpenVPN
    fi
    # Check if the chosen custom port is already in use for UDP or TCP
    if [ "$(lsof -i UDP:"${NEW_OPENVPN_PORT}")" ]; then
      # If the custom port is in use, display an error message and exit the script
      echo "Error: The port ${NEW_OPENVPN_PORT} is already in use. Please choose a different port."
      exit
    fi
    # Replace the port in the server config.
    sed -i "/^port /s/\([0-9]\+\)$/${NEW_OPENVPN_PORT}/" ${OPENVPN_SERVER_CONFIG}
    # Find all the configs from the config direcotry.
    OPENVPN_CLIENT_CONFIG_FILES=$(find "${OPENVPN_SERVER_CLIENT_DIRECTORY}" -type f -name "*.ovpn")
    for OPENVPN_CLIENT_CONFIG_FILE in "${OPENVPN_CLIENT_CONFIG_FILES[@]}"; do
      echo "Opening the current file: ${OPENVPN_CLIENT_CONFIG_FILE}"
      sed -i "/^remote /s/\([0-9]\+\)$/${NEW_OPENVPN_PORT}/" "${OPENVPN_CLIENT_CONFIG_FILE}"
    done
    # Restart the OpenVPN service to apply the changes.
    if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
      systemctl restart openvpn-server@server.service
    elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
      service openvpn-server@server.service restart
    fi
  }

  # Function to remove all OpenVPN clients
  function remove_all_openvpn_clients() {
    # Count the number of installed OpenVPN clients
    NUMBER_OF_CLIENTS_INSTALLED=$(tail --lines=+2 "${OPENVPN_SERVER_CERTIFICATE_INDEX}" | grep --count "^V")
    # Check if there are any clients installed
    if [[ "${NUMBER_OF_CLIENTS_INSTALLED}" == "0" ]]; then
      echo "Error: No OpenVPN clients found."
      exit
    fi
    # List all clients' common names
    CLIENTS=($(tail --lines=+2 "${OPENVPN_SERVER_CERTIFICATE_INDEX}" | awk -F'/CN=' '/^V/ {print $2}'))
    # Revoke each client's certificate and remove their .ovpn file
    for CLIENT_NAME in "${CLIENTS[@]}"; do
      echo "Revoking certificate and removing configuration for client: ${CLIENT_NAME}"
      # Revoke the client certificate
      "${OPENVPN_SERVER_EASY_RSA_SCRIPT}" --pki-dir="${OPENVPN_PKI_DIRECTORY}" --vars="${OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE}" revoke "${CLIENT_NAME}"
      # Remove the client .ovpn file
      echo "Removing the client configuration for client: ${CLIENT_NAME}"
      rm -f "${OPENVPN_SERVER_CLIENT_DIRECTORY}/${CLIENT_NAME}.ovpn"
    done

  }

  # Function to show OpenVPN client configuration
  function show_openvpn_client_configuration() {
    # Show OpenVPN client configuration
    # Count the number of installed OpenVPN clients
    NUMBER_OF_CLIENTS_INSTALLED=$(tail --lines=+2 "${OPENVPN_SERVER_CERTIFICATE_INDEX}" | grep --count "^V")
    # Check if there are any clients installed
    if [[ "${NUMBER_OF_CLIENTS_INSTALLED}" == "0" ]]; then
      echo "Error: No OpenVPN clients found."
      exit
    fi
    echo "Here are the available OpenVPN clients:"
    # List all clients with numbers for selection
    CLIENTS=($(tail --lines=+2 "${OPENVPN_SERVER_CERTIFICATE_INDEX}" | awk -F'/CN=' '/^V/ {print $2}'))
    # Display the clients with a numbered list
    PS3="Select a client:"
    select CLIENT_NAME in "${CLIENTS[@]}"; do
      if [[ -n "${CLIENT_NAME}" ]]; then
        echo "The OpenVPN client config is saved at ${OPENVPN_SERVER_CLIENT_DIRECTORY}/${CLIENT_NAME}.ovpn"
        break
      else
        echo "Invalid selection. Please choose a valid number."
      fi
    done
  }

  # Function to verify OpenVPN configuration
  function verify_openvpn_configuration() {
    # Verify OpenVPN configuration
    openvpn --config ${OPENVPN_SERVER_CONFIG} --test
  }

  # Function to manage network firewall configuration
  function network_firewall_configuration() {
    # Network Firewall Configuration
    # Check if the OpenVPN server service is active
    OPENVPN_SERVER_SERVICE_STATUS=$(systemctl is-active openvpn-server@server.service)
    # Get the public network interface name from the OpenVPN server configuration
    OPENVPN_SERVER_PUB_NIC="$(ip route | grep default | head --lines=1 | cut --delimiter=" " --fields=5)"
    if [ "${OPENVPN_SERVER_SERVICE_STATUS}" = "active" ]; then
      # Enable IP forwarding for IPv4
      sysctl --write net.ipv4.ip_forward=1
      # Enable IP forwarding for IPv6
      sysctl --write net.ipv6.conf.all.forwarding=1
      # Check if the nftables table for the OpenVPN server exists
      if [[ "$(nft list ruleset)" != *openvpn* ]]; then
        # Create a new nftables table for the OpenVPN server
        nft add table inet openvpn-"${OPENVPN_SERVER_PUB_NIC}"
        # Add a new chain for the OpenVPN server
        nft add chain inet openvpn-"${OPENVPN_SERVER_PUB_NIC}" postrouting { type nat hook postrouting priority srcnat \; }
        # Add a new rule to the chain to masquerade traffic
        nft add rule inet openvpn-"${OPENVPN_SERVER_PUB_NIC}" postrouting oifname "${OPENVPN_SERVER_PUB_NIC}" masquerade
      fi
    else
      # Disable IP forwarding for IPv4
      sysctl --write net.ipv4.ip_forward=0
      # Disable IP forwarding for IPv6
      sysctl --write net.ipv6.conf.all.forwarding=0
      if [[ "$(nft list ruleset)" == *openvpn* ]]; then
        # Flush the nftables table for the OpenVPN server
        nft delete table inet openvpn-"${OPENVPN_SERVER_PUB_NIC}"
      fi
    fi
  }

  # Function to manage OpenVPN service and configuration
  function openvpn_management() {
    # Display a list of available actions for the OpenVPN management interface
    echo "Please select an action:"
    echo "   1) Display OpenVPN configuration"
    echo "   2) Start OpenVPN service"
    echo "   3) Stop OpenVPN service"
    echo "   4) Restart OpenVPN service"
    echo "   5) Add a new OpenVPN client"
    echo "   6) Remove an OpenVPN client"
    echo "   7) Uninstall OpenVPN service"
    echo "   8) Update this management script"
    echo "   9) Backup OpenVPN configuration"
    echo "   10) Restore OpenVPN configuration"
    echo "   11) Update OpenVPN interface IP"
    echo "   12) Update OpenVPN interface port"
    echo "   13) Remove all OpenVPN clients"
    echo "   14) Show OpenVPN client configuration"
    echo "   15) Verify OpenVPN configuration integrity"
    echo "   16) Network Firewall Configuration"

    # Keep asking for a valid option until one is selected
    until [[ "${OPENVPN_OPTIONS}" =~ ^[0-9]+$ ]] && [ "${OPENVPN_OPTIONS}" -ge 1 ] && [ "${OPENVPN_OPTIONS}" -le 16 ]; do
      read -rp "Select an Option [1-17]: " -e -i 0 OPENVPN_OPTIONS
    done

    # Switch statement to handle the selected action
    case ${OPENVPN_OPTIONS} in
    1)
      # Show the OpenVPN configuration details
      display_openvpn_config
      ;;
    2)
      # Start the OpenVPN service
      start_openvpn_service
      ;;
    3)
      # Stop the OpenVPN service
      stop_openvpn_service
      ;;
    4)
      # Restart the OpenVPN service
      restart_openvpn_service
      ;;
    5)
      # Add a new OpenVPN client (peer)
      add_openvpn_client
      ;;
    6)
      # Remove an existing OpenVPN client (peer)
      remove_openvpn_client
      ;;
    7)
      # Uninstall the OpenVPN service
      uninstall_openvpn
      ;;
    8)
      # Update the OpenVPN management script
      update_openvpn_script
      ;;
    9)
      # Backup the current OpenVPN configuration
      backup_openvpn_config
      ;;
    10)
      # Restore a previously backed-up OpenVPN configuration
      restore_openvpn_config
      ;;
    11)
      # Update the OpenVPN interface's IP address
      update_openvpn_interface_ip
      ;;
    12)
      # Update the OpenVPN interface's listening port
      update_openvpn_interface_port
      ;;
    13)
      # Remove all OpenVPN clients (peers)
      remove_all_openvpn_clients
      ;;
    14)
      # Generate a QR code for OpenVPN configuration for clients
      show_openvpn_client_configuration
      ;;
    15)
      # Verify OpenVPN configurations for integrity and correctness
      verify_openvpn_configuration
      ;;
    16)
      # Network Firewall Configuration
      network_firewall_configuration
      ;;
    esac
  }

  # Call the OpenVPN management interface function to begin interaction
  openvpn_management

fi
