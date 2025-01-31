FROM ubuntu:latest

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install OpenVPN and required packages
RUN apt-get update &&  \
    apt-get install openvpn iproute2 iptables curl -y

# Create OpenVPN directory
RUN mkdir -p /etc/openvpn

# Copy OpenVPN client configuration
COPY aws.ovpn /etc/openvpn/client.ovpn

# Start OpenVPN and sleep indefinitely to keep the container running
CMD openvpn --config /etc/openvpn/client.ovpn --daemon --log /var/log/openvpn.log && sleep infinity

# Build the Docker Image
# docker build -f Dockerfile.client -t openvpn-client .

# Run the Container
# docker run --dns 1.1.1.1 --dns 1.0.0.1 -d --name openvpn-client --cap-add=NET_ADMIN --device /dev/net/tun openvpn-client

# Access the Running Container
# docker exec -it openvpn-client bash

# Check OpenVPN Logs
# docker exec -it openvpn-client cat /var/log/openvpn.log
