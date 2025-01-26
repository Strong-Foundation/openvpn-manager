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

# Check if the script is running as root
function check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
  fi
}

# Call the function to check root privileges
check_root

# Function to gather current system details
function system_information() {
  # This function fetches the ID, version, and major version of the current system
  if [ -f /etc/os-release ]; then
    # If /etc/os-release file is present, source it to obtain system details
    # shellcheck source=/dev/null
    source /etc/os-release
    CURRENT_DISTRO=${ID}                 # CURRENT_DISTRO holds the system's ID
    CURRENT_DISTRO_VERSION=${VERSION_ID} # CURRENT_DISTRO_VERSION holds the system's VERSION_ID
  fi
}

# Invoke the system_information function
system_information

# Define a function to check system requirements
function installing_system_requirements() {
  # Check if the current Linux distribution is supported
  if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ]; }; then
    # Check if required packages are already installed
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v sudo)" ] || [ ! -x "$(command -v bash)" ] || [ ! -x "$(command -v cut)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v ip)" ] || [ ! -x "$(command -v systemd-detect-virt)" ] || [ ! -x "$(command -v ps)" ] || [ ! -x "$(command -v lsof)" ]; }; then
      # Install required packages depending on the Linux distribution
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ]; }; then
        apt-get update
        apt-get install curl sudo bash coreutils jq iproute2 systemd procps lsof -y
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
  "kvm" | "none" | "qemu" | "lxc" | "microsoft" | "vmware" | "xen" | "amazon" | "docker") ;;
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
    exit 1 # Exit the script with an error code.
  fi
}

# The check_current_init_system function is being called.
check_current_init_system

# The following function checks if there's enough disk space to proceed with the installation.
function check_disk_space() {
  # This function checks if there is more than 1 GB of free space on the drive.
  FREE_SPACE_ON_DRIVE_IN_MB=$(df -m / | tr --squeeze-repeats " " | tail -n1 | cut --delimiter=" " --fields=4)
  # This line calculates the available free space on the root partition in MB.
  if [ "${FREE_SPACE_ON_DRIVE_IN_MB}" -le 1024 ]; then
    # If the available free space is less than or equal to 1024 MB (1 GB), display an error message and exit.
    echo "Error: You need more than 1 GB of free space to install everything. Please free up some space and try again."
    exit
  fi
}

# Calls the check_disk_space function.
check_disk_space

# Global variables
# Assigns the path of the current script to a variable
CURRENT_FILE_PATH=$(realpath "${0}")
# Set the TUN_PATH variable to the path of the TUN device
LOCAL_TUN_PATH="/dev/net/tun"
# Set the path to the opnevpn server directory
OPENVPN_SERVER_DIRECTORY="/etc/openvpn"
# Set the path to the openvpn easy-rsa directory
OPENVPN_SERVER_EASY_RSA_DIRECTORY="${OPENVPN_SERVER_DIRECTORY}/easy-rsa"
# Set the path to the openvpn server easy-rsa variables file
OPENVPN_SERVER_EASY_RSA_VARIABLES_FILE="${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars"
# Set the path to the opnevpn server client directory
OPENVPN_SERVER_CLIENT_DIRECTORY="${OPENVPN_SERVER_DIRECTORY}/clients"
# Set the path to the openvpn server config
OPENVPN_SERVER_CONFIG="${OPENVPN_SERVER_DIRECTORY}/server.conf"
# Set the path to the openvpn server certificate authority
OPENVPN_SERVER_CERTIFICATE_AUTHORITY="/etc/openvpn/server/ca.crt"
# Set the path to the openvpn server certificate authority key
OPENVPN_SERVER_CERTIFICATE_AUTHORITY_KEY="/etc/openvpn/server/ca.key"
# Set the path to the openvpn server diffie Hellman parameters file
OPENVPN_SERVER_DIFFIE_HELLMAN_PARAMETERS="/etc/openvpn/server/dh.pem"
# Set the path to the openvpn server ssl certificate
OPENVPN_SERVER_SSL_CERTIFICATE="/etc/openvpn/server/server.crt"
# Set the path to the openvpn server ssl key
OPENVPN_SERVER_SSL_KEY="/etc/openvpn/server/server.key"
# Set the path to the openvpn server tls-crypt key
OPENVPN_SERVER_TLS_CRYPT_KEY="/etc/openvpn/server/tls-crypt.key"
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
      exit 1
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
  echo "  --reinstall   Reinstalls the OpenVPN service, keeping the current configuration"
  echo "  --uninstall   Uninstalls the OpenVPN service from your system"
  echo "  --update      Updates the OpenVPN Manager to the latest version"
  echo "  --backup      Creates a backup of your current OpenVPN configuration"
  echo "  --restore     Restores the OpenVPN configuration from a previous backup"
  echo "  --purge       Removes all client configurations from the OpenVPN server"
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
    --reinstall) # If it's "--reinstall", set the variable OPENVPN_OPTIONS to 7
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=7}
      ;;
    --uninstall) # If it's "--uninstall", set the variable OPENVPN_OPTIONS to 8
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=8}
      ;;
    --update) # If it's "--update", set the variable OPENVPN_OPTIONS to 9
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=9}
      ;;
    --backup) # If it's "--backup", set the variable OPENVPN_OPTIONS to 10
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=10}
      ;;
    --restore) # If it's "--restore", set the variable OPENVPN_OPTIONS to 11
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=11}
      ;;
    --purge) # If it's "--purge", set the variable OPENVPN_OPTIONS to 14
      shift
      OPENVPN_OPTIONS=${OPENVPN_OPTIONS=14}
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
    SERVER_HOST_V4_SETTINGS=${SERVER_HOST_V4_SETTINGS=1}   # Default to 1 (IPv4)
    SERVER_HOST_V6_SETTINGS=${SERVER_HOST_V6_SETTINGS=1}   # Default to 1 (IPv6)
    PROTOCOL_CHOICE=${PROTOCOL_CHOICE=1}                   # Default to 1 (UDP as primary, TCP as secondary)
    SERVER_PORT_SETTINGS=${SERVER_PORT_SETTINGS=1}         # Default to 1 (1194)
    DNS_PROVIDER_SETTINGS=${DNS_PROVIDER_SETTINGS=1}       # Default to 1 (Unbound)
    CONTENT_BLOCKER_SETTINGS=${CONTENT_BLOCKER_SETTINGS=1} # Default to 1 (Yes)
    CLIENT_NAME=${CLIENT_NAME}                             # Set the client name
  fi
}

# Call the headless_install function to set default values for configuration variables in headless mode.
headless_install

# Set up the openvpn, if config it isn't already there.
if [ ! -f "${OPENVPN_SERVER_CONFIG}" ]; then

  # Define a function to retrieve the IPv4 address of the WireGuard interface
  function test_connectivity_v4() {
    # "get_network_information" that retrieves network information.
    get_network_information
    # Prompt the user to choose the method for detecting the IPv4 address
    echo "How would you like to detect IPv4?"
    echo "  1) Curl (Recommended)"
    echo "  2) Custom (Advanced)"
    # Loop until the user provides a valid input
    until [[ "${SERVER_HOST_V4_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IPv4 Choice [1-2]:" -e -i 1 SERVER_HOST_V4_SETTINGS
    done
    # Choose the method for detecting the IPv4 address based on the user's input
    case ${SERVER_HOST_V4_SETTINGS} in
    1)
      SERVER_HOST_V4=${DEFAULT_INTERFACE_IPV4} # Use the default IPv4 address
      ;;
    2)
      # Prompt the user to enter a custom IPv4 address
      read -rp "Custom IPv4:" SERVER_HOST_V4
      # If the user doesn't provide an input, use the default IPv4 address
      if [ -z "${SERVER_HOST_V4}" ]; then
        SERVER_HOST_V4=${DEFAULT_INTERFACE_IPV4}
      fi
      ;;
    esac
  }

  # Call the function to retrieve the IPv4 address
  test_connectivity_v4

  # Define a function to retrieve the IPv6 address of the WireGuard interface
  function test_connectivity_v6() {
    # Prompt the user to choose the method for detecting the IPv6 address
    echo "How would you like to detect IPv6?"
    echo "  1) Curl (Recommended)"
    echo "  2) Custom (Advanced)"
    # Loop until the user provides a valid input
    until [[ "${SERVER_HOST_V6_SETTINGS}" =~ ^[1-2]$ ]]; do
      read -rp "IPv6 Choice [1-2]:" -e -i 1 SERVER_HOST_V6_SETTINGS
    done
    # Choose the method for detecting the IPv6 address based on the user's input
    case ${SERVER_HOST_V6_SETTINGS} in
    1)
      SERVER_HOST_V6=${DEFAULT_INTERFACE_IPV6} # Use the default IPv6 address
      ;;
    2)
      # Prompt the user to enter a custom IPv6 address
      read -rp "Custom IPv6:" SERVER_HOST_V6
      # If the user doesn't provide an input, use the default IPv6 address
      if [ -z "${SERVER_HOST_V6}" ]; then
        SERVER_HOST_V6=${DEFAULT_INTERFACE_IPV6}
      fi
      ;;
    esac
  }

  # Call the function to retrieve the IPv6 address
  test_connectivity_v6

  # Define a function to configure the protocol settings for OpenVPN
  function configure_protocol() {
    # Prompt the user to configure the primary and secondary protocols
    echo "Select the primary and secondary protocols for OpenVPN:"
    echo "  1) UDP as primary, TCP as secondary (Recommended)"
    echo "  2) TCP as primary, UDP as secondary"
    echo "  3) UDP only (No secondary)"
    echo "  4) TCP only (No secondary)"
    # Loop until the user provides a valid input
    until [[ "${PROTOCOL_CHOICE}" =~ ^[1-4]$ ]]; do
      read -rp "Protocol Choice [1-4]: " -e -i 1 PROTOCOL_CHOICE
    done
    # Set the protocols based on the user's choice
    case ${PROTOCOL_CHOICE} in
    1)
      PRIMARY_PROTOCOL="UDP6"
      SECONDARY_PROTOCOL="TCP6"
      ;;
    2)
      PRIMARY_PROTOCOL="TCP6"
      SECONDARY_PROTOCOL="UDP6"
      ;;
    3)
      PRIMARY_PROTOCOL="UDP6"
      SECONDARY_PROTOCOL="none"
      ;;
    4)
      PRIMARY_PROTOCOL="TCP6"
      SECONDARY_PROTOCOL="none"
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
      if { [ "$(lsof -i UDP:"${SERVER_PORT}")" ] || [ "$(lsof -i TCP:"${SERVER_PORT}")" ]; }; then
        # If the custom port is in use, display an error message and exit the script
        echo "Error: The port ${SERVER_PORT} is already in use. Please choose a different port."
        exit
      fi
      ;;
    esac
  }

  # Call the function to execute the OpenVPN port configuration process
  configure_openvpn_ports

  # Function to install either resolvconf or openresolv, depending on the distribution.
  function install_resolvconf_or_openresolv() {
    # Check if resolvconf is already installed on the system.
    if [ ! -x "$(command -v resolvconf)" ]; then
      # If resolvconf is not installed, install it for Ubuntu, Debian, Raspbian, Pop, Kali, Linux Mint, and Neon distributions.
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ]; }; then
        apt-get install resolvconf -y
      fi
    fi
  }

  # Invoke the function to install either resolvconf or openresolv, depending on the distribution.
  install_resolvconf_or_openresolv

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
      echo "Select the DNS provider you wish to use with your WireGuard connection:"
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
        CLIENT_DNS="1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001"
        ;;
      2)
        # Set DNS addresses for AdGuard.
        CLIENT_DNS="94.140.14.14,94.140.15.15,2a10:50c0::ad1:ff,2a10:50c0::ad2:ff"
        ;;
      3)
        # Set DNS addresses for NextDNS.
        CLIENT_DNS="45.90.28.167,45.90.30.167,2a07:a8c0::12:cf53,2a07:a8c1::12:cf53"
        ;;
      4)
        # Set DNS addresses for OpenDNS.
        CLIENT_DNS="208.67.222.222,208.67.220.220,2620:119:35::35,2620:119:53::53"
        ;;
      5)
        # Set DNS addresses for Google.
        CLIENT_DNS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
        ;;
      6)
        # Set DNS addresses for Verisign.
        CLIENT_DNS="64.6.64.6,64.6.65.6,2620:74:1b::1:1,2620:74:1c::2:2"
        ;;
      7)
        # Set DNS addresses for Quad9.
        CLIENT_DNS="9.9.9.9,149.112.112.112,2620:fe::fe,2620:fe::9"
        ;;
      8)
        # Set DNS addresses for FDN.
        CLIENT_DNS="80.67.169.40,80.67.169.12,2001:910:800::40,2001:910:800::12"
        ;;
      9)
        # Prompt the user to enter a custom DNS address.
        read -rp "Custom DNS:" CLIENT_DNS
        # If the user doesn't provide a custom DNS, default to Google's DNS.
        if [ -z "${CLIENT_DNS}" ]; then
          CLIENT_DNS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
        fi
        ;;
      10)
        # If Pi-Hole is installed, use its DNS. Otherwise, install Unbound and enable the block list.
        if [ -x "$(command -v pihole)" ]; then
          CLIENT_DNS="${GATEWAY_ADDRESS_V4},${GATEWAY_ADDRESS_V6}"
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
      read -rp "Client name: " -e -i "$(openssl rand -hex 5)" CLIENT_NAME
    fi
    # If no name is provided by the user, assign a random string as the name.
    if [ -z "${CLIENT_NAME}" ]; then
      CLIENT_NAME="$(openssl rand -hex 5)"
    fi
  }

  # Invoke the function to prompt for the first OpenVPN client's name.
  client_name

  # Function to install Unbound, a DNS resolver, if required and not already installed.
  function install_unbound() {
    # If INSTALL_UNBOUND is true and Unbound is not installed, proceed with installation.
    if [ "${INSTALL_UNBOUND}" == true ]; then
      if [ ! -x "$(command -v unbound)" ]; then
        # Check if the root hints file does not exist.
        if [ ! -f ${UNBOUND_ROOT_HINTS} ]; then
          # If the root hints file is missing, download it from the specified URL.
          LOCAL_UNBOUND_ROOT_HINTS_COPY=$(curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}")
        fi
        # Check if we are install unbound blocker
        if [ "${INSTALL_BLOCK_LIST}" == true ]; then
          # Check if the block list file does not exist.
          if [ ! -f ${UNBOUND_CONFIG_HOST} ]; then
            # If the block list file is missing, download it from the specified URL.
            LOCAL_UNBOUND_BLOCKLIST_COPY=$(curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}')
          fi
        fi
        # Installation commands for Unbound vary based on the Linux distribution.
        # The following checks the distribution and installs Unbound accordingly.
        # For Debian-based distributions:
        if { [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "raspbian" ]; }; then
          apt-get install unbound unbound-host unbound-anchor -y
          # If the distribution is Ubuntu, disable systemd-resolved.
          if [ "${CURRENT_DISTRO}" == "ubuntu" ]; then
            if [[ "${CURRENT_INIT_SYSTEM}" == "systemd" ]]; then
              systemctl disable --now systemd-resolved
            elif [[ "${CURRENT_INIT_SYSTEM}" == "sysvinit" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "init" ]] || [[ "${CURRENT_INIT_SYSTEM}" == "upstart" ]]; then
              service systemd-resolved stop
            fi
          fi
        fi
      fi
      # Configure Unbound to use the auto-trust-anchor-file.
      unbound-anchor -a ${UNBOUND_ANCHOR}
      # Configure Unbound to use the root hints file.
      printf "%s" "${LOCAL_UNBOUND_ROOT_HINTS_COPY}" >${UNBOUND_ROOT_HINTS}
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
      echo -e "${UNBOUND_TEMP_INTERFACE_INFO}" | awk '!seen[$0]++' >${UNBOUND_CONFIG}
      # Check if we are installing a block list.
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        # Include the block list in the Unbound configuration.
        echo -e "\tinclude: ${UNBOUND_CONFIG_HOST}" >>${UNBOUND_CONFIG}
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
        printf "%s" "${LOCAL_UNBOUND_BLOCKLIST_COPY}" >${UNBOUND_CONFIG_HOST}
      fi
      # Update ownership of Unbound's root directory.
      chown --recursive "${USER}":"${USER}" ${UNBOUND_ROOT}
      # Update the resolv.conf file to use Unbound.
      if [ -f "${RESOLV_CONFIG_OLD}" ]; then
        rm --force ${RESOLV_CONFIG_OLD}
      fi
      if [ -f "${RESOLV_CONFIG}" ]; then
        chattr -i ${RESOLV_CONFIG}
        mv ${RESOLV_CONFIG} ${RESOLV_CONFIG_OLD}
      fi
      echo "nameserver 127.0.0.1" >${RESOLV_CONFIG}
      echo "nameserver ::1" >>${RESOLV_CONFIG}
      chattr +i ${RESOLV_CONFIG}
      # Set CLIENT_DNS to use gateway addresses.
      CLIENT_DNS="${GATEWAY_ADDRESS_V4},${GATEWAY_ADDRESS_V6}"
    fi
  }

  # Call the function to install Unbound.
  install_unbound

  # Set cipher for the data channel
  DATA_CHANNEL_CIPHER="AES-256-GCM" # Stronger encryption for the data channel
  # Set certificate type
  CERTIFICATE_TYPE="ECDSA" # Secure and efficient certificate type
  # Set curve for certificate key
  CERTIFICATE_CURVE="secp521r1" # Strongest curve for ECDSA
  # Set cipher for the control channel
  CONTROL_CHANNEL_CIPHER="ECDHE-ECDSA-AES-256-GCM-SHA384" # Strong cipher for control channel
  # Set Diffie-Hellman key type
  DIFFIE_HELLMAN_KEY="ECDH" # Secure and efficient Diffie-Hellman key exchange
  # Set curve for ECDH key
  ECDH_CURVE="secp521r1" # Strongest ECDH curve for key exchange
  # Set HMAC digest algorithm
  HMAC_DIGEST="SHA-512" # Strongest HMAC digest for better security
  # Set tls-auth or tls-crypt
  TLS_AUTH_MODE="tls-crypt" # Provides encryption and authentication for control channel

  # Function to install openvpn.
  function install_openvpn() {
    # Check if required packages are already installed
    if { [ ! -x "$(command -v openvpn)" ] || [ ! -x "$(command -v openssl)" ] || [ ! -x "$(command -v gpg)" ] || [ ! -x "$(command -v ip)" ]; }; then
      # Install required packages depending on the Linux distribution
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ]; }; then
        apt-get update
        apt-get install openvpn openssl gnupg ca-certificates easy-rsa -y
      fi
    fi

    # Create the easy-rsa directory if it doesn't exist.
    if [ ! -d "${OPENVPN_SERVER_EASY_RSA_DIRECTORY}" ]; then
      # Create the Easy-RSA directory.
      make-cadir ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}
      # Fix the Easy-RSA configuration variables in the vars file.
      # Uncomments and sets the EASYRSA variable to the directory containing Easy-RSA scripts.
      sed -i '0,/^#set_var EASYRSA/ s|#set_var EASYRSA|set_var EASYRSA|' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the Easy-RSA OpenSSL binary path.
      sed -i 's|#set_var EASYRSA_OPENSSL\s*"openssl"|set_var EASYRSA_OPENSSL\t"openssl"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the path to the PKI directory.
      sed -i 's|#set_var EASYRSA_PKI\s*"\$PWD/pki"|set_var EASYRSA_PKI\t"$PWD/pki"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the temporary directory variable.
      sed -i 's|#set_var EASYRSA_TEMP_DIR\s*"\$EASYRSA_PKI"|set_var EASYRSA_TEMP_DIR\t"$EASYRSA_PKI"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the Distinguished Name mode to "cn_only".
      sed -i 's|#set_var EASYRSA_DN\s*"cn_only"|set_var EASYRSA_DN\t"cn_only"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the default country for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_COUNTRY\s*"US"|set_var EASYRSA_REQ_COUNTRY\t"US"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the default province for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_PROVINCE\s*"California"|set_var EASYRSA_REQ_PROVINCE\t"California"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the default city for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_CITY\s*"San Francisco"|set_var EASYRSA_REQ_CITY\t"San Francisco"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the organization name for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_ORG\s*"Copyleft Certificate Co"|set_var EASYRSA_REQ_ORG\t"Copyleft Certificate Co"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the email address for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_EMAIL\s*"me@example.net"|set_var EASYRSA_REQ_EMAIL\t"me@example.net"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the Organizational Unit for the certificate request.
      sed -i 's|#set_var EASYRSA_REQ_OU\s*"My Organizational Unit"|set_var EASYRSA_REQ_OU\t"My Organizational Unit"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and preserves the Distinguished Name during certificate renewal.
      sed -i 's|#set_var EASYRSA_PRESERVE_DN\s*1|set_var EASYRSA_PRESERVE_DN\t1|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and disables password protection for private keys.
      sed -i 's|#set_var EASYRSA_NO_PASS\s*1|set_var EASYRSA_NO_PASS\t1|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the default key size for certificates.
      sed -i 's|#set_var EASYRSA_KEY_SIZE\s*2048|set_var EASYRSA_KEY_SIZE\t4096|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the cryptographic algorithm.
      sed -i 's|#set_var EASYRSA_ALGO\s*rsa|set_var EASYRSA_ALGO\tec|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the elliptic curve for EC certificates.
      sed -i 's|#set_var EASYRSA_CURVE\s*secp384r1|set_var EASYRSA_CURVE\tsecp384r1|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the CA certificate expiration period (in days).
      sed -i 's|#set_var EASYRSA_CA_EXPIRE\s*3650|set_var EASYRSA_CA_EXPIRE\t3650|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the certificate expiration period (in days).
      sed -i 's|#set_var EASYRSA_CERT_EXPIRE\s*825|set_var EASYRSA_CERT_EXPIRE\t825|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the CRL expiration period (in days).
      sed -i 's|#set_var EASYRSA_CRL_DAYS\s*180|set_var EASYRSA_CRL_DAYS\t180|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and enables the use of random serial numbers.
      sed -i 's|#set_var EASYRSA_RAND_SN\s*"yes"|set_var EASYRSA_RAND_SN\t"yes"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the pre-expiry notification window (in days).
      sed -i 's|#set_var EASYRSA_PRE_EXPIRY_WINDOW\s*90|set_var EASYRSA_PRE_EXPIRY_WINDOW\t90|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and disables Netscape certificate support.
      sed -i 's|#set_var EASYRSA_NS_SUPPORT\s*"no"|set_var EASYRSA_NS_SUPPORT\t"no"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the Netscape certificate comment.
      sed -i 's|#set_var EASYRSA_NS_COMMENT\s*"Easy-RSA Generated Certificate"|set_var EASYRSA_NS_COMMENT\t"Easy-RSA Generated Certificate"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the x509 extension directory.
      sed -i 's|#set_var EASYRSA_EXT_DIR\s*"\$EASYRSA/x509-types"|set_var EASYRSA_EXT_DIR\t"$EASYRSA/x509-types"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the Kerberos realm.
      sed -i 's|#set_var EASYRSA_KDC_REALM\s*"CHANGEME.EXAMPLE.COM"|set_var EASYRSA_KDC_REALM\t"CHANGEME.EXAMPLE.COM"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the SSL configuration file path.
      sed -i 's|#set_var EASYRSA_SSL_CONF\s*"\$EASYRSA_PKI/openssl-easyrsa.cnf"|set_var EASYRSA_SSL_CONF\t"$EASYRSA_PKI/openssl-easyrsa.cnf"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets the default digest algorithm for certificates.
      sed -i 's|#set_var EASYRSA_DIGEST\s*"sha256"|set_var EASYRSA_DIGEST\t"sha256"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
      # Uncomments and sets batch mode to an empty string.
      sed -i 's|#set_var EASYRSA_BATCH\s*""|set_var EASYRSA_BATCH\t"yes"|g' ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}/vars
    fi
    # Change the working directory to the Easy-RSA directory.
    cd ${OPENVPN_SERVER_EASY_RSA_DIRECTORY}
    # Initialize the Public Key Infrastructure (PKI) directory, setting up the necessary structure for key and certificate management.
    /etc/openvpn/easy-rsa/easyrsa init-pki
    # Build the Certificate Authority (CA). This creates the root certificate and private key for signing other certificates.
    /etc/openvpn/easy-rsa/easyrsa build-ca
    # Generate a certificate request for the server. This creates the server's private key and certificate request (CSR).
    /etc/openvpn/easy-rsa/easyrsa gen-req server
    # Generate the server's certificate using the previously generated certificate request. This signs the CSR with the CA.
    /etc/openvpn/easy-rsa/easyrsa server
    # Sign the server's certificate request using the CA's private key to issue the final certificate for the server.
    /etc/openvpn/easy-rsa/easyrsa sign-req server server
    # Generate the Diffie-Hellman parameters, which are used for secure key exchange during the VPN connection setup.
    # These parameters enhance the security of the connection by enabling Perfect Forward Secrecy (PFS).
    /etc/openvpn/easy-rsa/easyrsa gen-dh
    # Generate a Certificate Revocation List (CRL), which contains a list of revoked certificates. This is used by OpenVPN to ensure that revoked certificates are not allowed to establish connections.
    /etc/openvpn/easy-rsa/easyrsa gen-crl
    # Generate the TLS Auth Key
    openvpn --genkey --secret ${OPENVPN_TLS_CRYPT_PRIVATE_KEY_PATH}

    # Create the OpenVPN server configuration file with the specified settings.
    OPEN_VPN_SERVER_CONFIG="
# Listen on all available network interfaces (0.0.0.0) for incoming connections.
local 0.0.0.0
# Set the port for OpenVPN to listen on (e.g., 1194).
port 1194
# Set the protocol for OpenVPN to use (e.g., udp or tcp).
proto udp6
# dev tun - routed IP tunnel (e.g., tun), dev tap - ethernet bridge tunnel (e.g., tap)
dev tun
# Define the IPv4 subnet and netmask for the VPN server to assign client IP addresses.
server 10.0.0.0 255.0.0.0
# Define the IPv6 subnet for the VPN server to assign client IPv6 addresses.
server-ipv6 fd00:00:00::0/8
# Set the topology to "subnet" for a routed VPN network, where each client gets its own IP address in the network.
topology subnet
# Enable IPv6 support on the tunnel interface.
tun-ipv6
# Push the IPv6 configuration to connected clients.
push tun-ipv6
# Push the primary DNS server to clients (changeable via the DNS_PRIMARY variable).
push "dhcp-option DNS 1.1.1.1"
# Push the secondary DNS server to clients (changeable via the DNS_SECONDARY variable).
push "dhcp-option DNS 1.0.0.1"
# Redirect all client traffic through the VPN while bypassing local DHCP traffic.
push "redirect-gateway def1 bypass-dhcp"
# Push a route for the IPv6 network 2000::/3 to the client, covering all globally routable IPv6 addresses.
push "route-ipv6 2000::/3"
# Push a directive to redirect all client IPv6 traffic through the VPN gateway.
push "redirect-gateway ipv6"
# Directory containing client configuration files.
client-config-dir /etc/openvpn/clients
# Keep the keys intact across restarts to avoid re-negotiating them.
persist-key
# Keep the tunnel interface open across restarts to avoid recreating it.
persist-tun
# Path to the Certificate Authority (CA) certificate.
ca /etc/openvpn/server/ca.crt
# Path to the server's SSL certificate.
cert /etc/openvpn/easy-rsa/keys/server.crt
# Path to the server's private key.
key /etc/openvpn/easy-rsa/keys/server.key
# Path to the Diffie-Hellman parameters for key exchange.
dh /etc/openvpn/easy-rsa/keys/dh.pem
# Path to the TLS authentication key (for added security).
tls-auth /etc/openvpn/easy-rsa/keys/ta.key
# Verify the certificate revocation list (CRL) using the specified crl.pem file to check for revoked certificates.
crl-verify crl.pem
# The keepalive directive sends ping messages every 10 seconds and considers the remote peer down if no ping is received within 120 seconds.
keepalive 10 120
# Disable compression to avoid the VORACLE attack.
compress disable
# Use AES-256-GCM for encryption, a fast and secure authenticated encryption cipher.
cipher AES-256-GCM
# Set the ciphers for NCP (Negotiate Cipher Protocol) to AES-256-GCM.
ncp-ciphers AES-256-GCM
# Set the elliptic curve Diffie-Hellman (ECDH) curve to secp521r1 for key exchange.
ecdh-curve secp521r1
# Use tls-crypt for control channel encryption and authentication, providing better security than tls-auth.
tls-crypt /etc/openvpn/easy-rsa/keys/tc.key 0
# Set the HMAC (hash-based message authentication code) algorithm to SHA512 for message integrity.
auth SHA512
# Enable TLS server mode, where the OpenVPN server performs the TLS handshake.
tls-server
# Set the minimum required TLS version to 1.3 for stronger encryption and security.
tls-version-min 1.3
# Specify the TLS cipher suite to use, with strong elliptic-curve encryption and SHA-384 for integrity.
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384
# Set the verbosity level of the log (0 is the least verbose, providing only critical errors).
verb 0
"

    # Check if the secondary protocol is used, if its used add SECONDARY_PROTOCOL

    # Put the server config into the server config file.
    echo -e "${OPEN_VPN_SERVER_CONFIG}" | awk '!seen[$0]++' >${OPENVPN_SERVER_CONFIG}

    # Create the OpenVPN client configuration directory if it doesn't exist.
    if [ ! -d "${OPENVPN_SERVER_CLIENT_DIRECTORY}" ]; then
      mkdir --parents ${OPENVPN_SERVER_CLIENT_DIRECTORY}
    fi
    # Create the OpenVPN client configuration file with the specified settings.
    OPEN_VPN_CLIENT_CONFIG="
# Define this as a client configuration file
client
# Specify the server's address and port (replace 0.0.0.0 with actual server IP or DNS name).
remote 0.0.0.0 1194
# Define the VPN device type (tun for routed IP tunnel, tap for bridged Ethernet tunnel).
dev tun
# Use the same protocol as the server (udp or tcp).
proto udp6
# Set verbosity to 0 (minimal logging).
verb 0
# In case of DNS resolution failure, retry indefinitely.
resolv-retry infinite
# Prevent binding to a specific local port, allowing dynamic port assignment.
nobind
# Keep the encryption keys intact across restarts to avoid re-negotiating them.
persist-key
# Keep the tunnel interface open across restarts to avoid recreating it.
persist-tun
# Enable explicit exit notifications. Helps the server know when the client disconnects.
explicit-exit-notify
# Ensure the server's certificate matches during the handshake (for security).
remote-cert-tls server
# Verify the server's X.509 certificate name to ensure authenticity and avoid MITM attacks.
verify-x509-name server_vHgFlVhJGDp4N1VK name
# Use SHA512 for message authentication (ensures message integrity and security).
auth SHA512
# Disable caching of authentication credentials to avoid security issues.
auth-nocache
# Use AES-256-GCM for encryption, which provides secure and efficient encryption.
cipher AES-256-GCM
# Indicate this as a TLS client (required for TLS communication with the server).
tls-client
# Set the minimum required TLS version to 1.2 (for security, older versions like TLS 1.0/1.1 should be avoided).
tls-version-min 1.2
# Specify the TLS cipher suite to use, which includes strong elliptic-curve encryption and SHA-384 for integrity.
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384
# Ignore unknown options that the client doesn't understand (useful for compatibility).
ignore-unknown-option block-outside-dns
# Set an environment variable to block DNS requests outside the VPN tunnel (useful for avoiding DNS leaks on Windows).
setenv opt block-outside-dns
# The CA certificate verifies the server's certificate and ensures it's signed by a trusted authority.
<ca>
</ca>
# The client certificate authenticates the client to the server during the TLS handshake.
<cert>
</cert>
# The client's private key proves ownership of the client certificate during the TLS handshake.
<key>
</key>
# The TLS-crypt key secures the control channel and protects against attacks like DoS and traffic analysis.
<tls-crypt>
</tls-crypt>
"
    # Put the client config into the client config file.
    echo -e "${OPEN_VPN_CLIENT_CONFIG}" | awk '!seen[$0]++' >${OPENVPN_SERVER_CLIENT_DIRECTORY}/${CLIENT_NAME}.ovpn
  }

  # Install openvpn
  install_openvpn

# If oepnvpn config is found than lets manage it using the manager
else

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
    echo "   7) Reinstall OpenVPN service"
    echo "   8) Uninstall OpenVPN service"
    echo "   9) Update this management script"
    echo "   10) Backup OpenVPN configuration"
    echo "   11) Restore OpenVPN configuration"
    echo "   12) Update OpenVPN interface IP"
    echo "   13) Update OpenVPN interface port"
    echo "   14) Remove all OpenVPN clients"
    echo "   15) Show OpenVPN client configuration"
    echo "   16) Verify OpenVPN configuration integrity"

    # Keep asking for a valid option until one is selected
    until [[ "${OPENVPN_OPTIONS}" =~ ^[0-9]+$ ]] && [ "${OPENVPN_OPTIONS}" -ge 1 ] && [ "${OPENVPN_OPTIONS}" -le 16 ]; do
      read -rp "Select an Option [1-16]: " -e -i 0 OPENVPN_OPTIONS
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
      # Reinstall the OpenVPN service
      reinstall_openvpn
      ;;
    8)
      # Uninstall the OpenVPN service
      uninstall_openvpn
      ;;
    9)
      # Update the OpenVPN management script
      update_openvpn_script
      ;;
    10)
      # Backup the current OpenVPN configuration
      backup_openvpn_config
      ;;
    11)
      # Restore a previously backed-up OpenVPN configuration
      restore_openvpn_config
      ;;
    12)
      # Update the OpenVPN interface's IP address
      update_openvpn_interface_ip
      ;;
    13)
      # Update the OpenVPN interface's listening port
      update_openvpn_interface_port
      ;;
    14)
      # Remove all OpenVPN clients (peers)
      remove_all_openvpn_clients
      ;;
    15)
      # Generate a QR code for OpenVPN configuration for clients
      show_openvpn_client_configuration
      ;;
    16)
      # Verify OpenVPN configurations for integrity and correctness
      verify_openvpn_configuration
      ;;
    esac
  }

  # Call the OpenVPN management interface function to begin interaction
  openvpn_management

fi
