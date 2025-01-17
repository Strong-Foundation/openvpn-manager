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
    CURRENT_DISTRO=${ID}                                                                              # CURRENT_DISTRO holds the system's ID
    CURRENT_DISTRO_VERSION=${VERSION_ID}                                                              # CURRENT_DISTRO_VERSION holds the system's VERSION_ID
    CURRENT_DISTRO_MAJOR_VERSION=$(echo "${CURRENT_DISTRO_VERSION}" | cut --delimiter="." --fields=1) # CURRENT_DISTRO_MAJOR_VERSION holds the major version of the system (e.g., "16" for Ubuntu 16.04)
  fi
}

# Invoke the system_information function
system_information

# Define a function to check system requirements
function installing_system_requirements() {
  # Check if the current Linux distribution is supported
  if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ]; }; then
    # Check if required packages are already installed
    if { [ ! -x "$(command -v curl)" ] || [ ! -x "$(command -v cut)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v ip)" ]; }; then
      # Install required packages depending on the Linux distribution
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ]; }; then
        apt-get update
        apt-get install sudo bash coreutils procps-ng kmod -y
      fi
    fi
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
# Set the path to the oepnvpn server directory
OPENVPN_SERVER_DIRECTORY="/etc/openvpn"
# Set the path to the openvpn server config
OPENVPN_SERVER_CONFIG=${OPENVPN_SERVER_DIRECTORY}"/server.conf"

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
check_local_tun

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

# Set up the openvpn, if config it isn't already there.
if [ ! -f "${OPENVPN_SERVER_CONFIG}" ]; the

  # Define a function to retrieve the IPv4 address of the WireGuard interface
  function test_connectivity_v4() {
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
      PRIMARY_PROTOCOL="udp"
      SECONDARY_PROTOCOL="tcp"
      ;;
    2)
      PRIMARY_PROTOCOL="tcp"
      SECONDARY_PROTOCOL="udp"
      ;;
    3)
      PRIMARY_PROTOCOL="udp"
      SECONDARY_PROTOCOL="none"
      ;;
    4)
      PRIMARY_PROTOCOL="tcp"
      SECONDARY_PROTOCOL="none"
      ;;
    esac
  }

  # Call the function to configure the protocol settings
  configure_protocol

# If oepnvpn config is found than lets manage it using the manager
else

fi
