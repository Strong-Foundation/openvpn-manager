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
# Set the path to the opnevpn server client directory
OPENVPN_SERVER_CLIENT_DIRECTORY="${OPENVPN_SERVER_DIRECTORY}/clients"
# Set the path to the openvpn server config
OPENVPN_SERVER_CONFIG="${OPENVPN_SERVER_DIRECTORY}/server.conf"

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
      PRIMARY_PROTOCOL="UDP"
      SECONDARY_PROTOCOL="TCP"
      ;;
    2)
      PRIMARY_PROTOCOL="TCP"
      SECONDARY_PROTOCOL="UDP"
      ;;
    3)
      PRIMARY_PROTOCOL="UDP"
      SECONDARY_PROTOCOL="none"
      ;;
    4)
      PRIMARY_PROTOCOL="TCP"
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
  #
  OPENVPN_TLS_CRYPT_PRIVATE_KEY_PATH="/etc/openvpn/tls-crypt.key"

  # Function to install openvpn.
  function install_openvpn() {
    # Check if required packages are already installed
    if { [ ! -x "$(command -v openvpn)" ] || [ ! -x "$(command -v cut)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v ip)" ]; }; then
      # Install required packages depending on the Linux distribution
      if { [ "${CURRENT_DISTRO}" == "ubuntu" ] || [ "${CURRENT_DISTRO}" == "debian" ] || [ "${CURRENT_DISTRO}" == "raspbian" ]; }; then
        apt-get update
        apt-get install ca-certificates gnupg openvpn openssl easy-rsa ca-certificates -y
      fi
    fi
    # Generate the keys
    openvpn --genkey --secret ${OPENVPN_TLS_CRYPT_PRIVATE_KEY_PATH}
    
    echo "" >>${OPENVPN_SERVER_CONFIG}
  }

  # Install openvpn
  install_openvpn

  # Function to install Unbound, a DNS resolver, if required and not already installed.
  function install_unbound() {
    # If INSTALL_UNBOUND is true and Unbound is not installed, proceed with installation.
    if [ "${INSTALL_UNBOUND}" == true ]; then
      if [ ! -x "$(command -v unbound)" ]; then
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
      # Configure Unbound using anchor and root hints.
      unbound-anchor -a ${UNBOUND_ANCHOR}
      # Download root hints.
      curl "${UNBOUND_ROOT_SERVER_CONFIG_URL}" --create-dirs -o ${UNBOUND_ROOT_HINTS}
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
      # Configure block list if INSTALL_BLOCK_LIST is true.
      if [ "${INSTALL_BLOCK_LIST}" == true ]; then
        echo -e "\tinclude: ${UNBOUND_CONFIG_HOST}" >>${UNBOUND_CONFIG}
        if [ ! -d "${UNBOUND_CONFIG_DIRECTORY}" ]; then
          mkdir --parents "${UNBOUND_CONFIG_DIRECTORY}"
        fi
        curl "${UNBOUND_CONFIG_HOST_URL}" | awk '{print "local-zone: \""$1"\" always_refuse"}' >${UNBOUND_CONFIG_HOST}
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
