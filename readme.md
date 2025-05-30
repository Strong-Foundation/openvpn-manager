# OpenVPN Manager

OpenVPN Manager is a powerful and intuitive script designed to automate the setup, management, and maintenance of your OpenVPN server. The script simplifies the process of configuring OpenVPN, managing users, and controlling OpenVPN services with a streamlined user interface.

## Features

- **Automated OpenVPN Installation:** Installs and configures OpenVPN with a single command.
- **Service Management:** Start, stop, or restart the OpenVPN service as needed.
- **User Management:** Add, remove, or list OpenVPN clients.
- **Configuration Management:** Update OpenVPN settings, including IP and port configurations.
- **Backup & Restore:** Backup and restore your OpenVPN configurations.
- **QR Code Generation:** Create QR codes for easy client configuration.
- **Configuration Integrity:** Verify the integrity of OpenVPN configuration files.
- **Comprehensive UI Menu:**
  - Display OpenVPN configuration.
  - Start, stop, or restart the OpenVPN service.
  - Add or remove OpenVPN clients.
  - Reinstall or uninstall OpenVPN service.
  - Update the management script.
  - Backup and restore configurations.
  - Modify OpenVPN interface settings (IP/port).
  - Remove all clients or verify configuration integrity.
  - Generate client configuration files and verify setup.

## Installation

To install OpenVPN Manager, follow these steps:

1. **Download the script:**

   ```bash
   curl https://raw.githubusercontent.com/complexorganizations/openvpn-manager/main/openvpn-manager.sh --create-dirs -o /usr/local/bin/openvpn-manager.sh
   ```

2. **Run the script with root privileges:**
   ```bash
   sudo bash /usr/local/bin/openvpn-manager.sh
   ```

The script will handle everything from the OpenVPN installation to configuration.

## Usage

Run the following command to launch the OpenVPN Manager interface:

```bash
bash openvpn-manager.sh
```

The UI will guide you through various management tasks, including:

- Installing OpenVPN.
- Adding/removing VPN users.
- Starting, stopping, or restarting the OpenVPN service.
- Managing OpenVPN configurations (IP, port, etc.).
- Backing up or restoring configuration files.
- Generating QR codes for clients.

## Troubleshooting

- **Permission Issues:** Ensure you are running the script with `sudo` for proper permissions:

  ```bash
  sudo ./openvpn-manager.sh
  ```

- **VPN Not Connecting:** If you face connection issues, check that the OpenVPN service is running and that the configuration is correct.

## 📐 Architecture

```mermaid
graph LR
  %% VPN Client Devices (Direct Connection)
  subgraph "VPN Client Devices"
    phone[Phone - OpenVPN Client]
    laptop[Laptop - OpenVPN Client]
  end

  %% Local Network Devices Connecting Through Router
  subgraph "Local Network Devices"
    localWatch[Watch] -->|Sends Traffic to Local Router| localRouter[Local Router With OpenVPN]
    localSmartTV[Smart TV] -->|Sends Traffic to Local Router| localRouter
    localRouter
  end

  %% Internet Block
  subgraph "Internet"
    internet -->|"Sends Encrypted Traffic to VPN Server"| vpnServer[OpenVPN VPN Server]
  end

  %% OpenVPN VPN Server - Processing Encrypted Traffic
  subgraph "OpenVPN VPN Server"
    vpnServer -->|Decrypts Traffic| openvpnVPN[VPN Traffic Processor]
    openvpnVPN -->|Handles DNS Requests| dnsServer[DNS Server]
    firewall[Firewall] -->|Filters Incoming/Outgoing Traffic| openvpnVPN
    router[Router] -->|Performs NAT for VPN Traffic| openvpnVPN
    openvpnVPN -->|Routes Decrypted Traffic to Destination| internetDestination["Internet Destination"]
  end

  %% Internet Destination - Services Handling Requests
  subgraph "Internet Destination"
    internetDestination -->|Routes Traffic to Services| destinationServices[Destination Servers]
  end

  %% Connections to the Internet
  internet
  vpnServer
  localRouter -->|"Encrypts Traffic and Sends to Internet"| internet
  laptop -->|"Encrypts Traffic and Sends to Internet"| internet
  phone -->|"Encrypts Traffic and Sends to Internet"| internet
```

## Contributing

We welcome contributions! If you have any suggestions or bug fixes, feel free to fork the repository, create a new branch, and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Additional Resources

- [OpenVPN Documentation](https://openvpn.net/community-resources/)
- [OpenVPN GitHub Repository](https://github.com/OpenVPN)
