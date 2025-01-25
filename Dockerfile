# Use the official Ubuntu base image
FROM ubuntu:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update the system for dependencies
RUN apt-get update && \
    apt-get install curl -y

# Copy the OpenVPN manager script into the container
COPY openvpn-manager.sh /usr/local/bin/openvpn-manager.sh

# Grant execution permissions to the script
RUN chmod +x /usr/local/bin/openvpn-manager.sh

# Expose the OpenVPN port
EXPOSE 1194/udp

# Run the OpenVPN manager script
RUN bash /usr/local/bin/openvpn-manager.sh --install

# Sleep to keep the container running
CMD ["sleep", "infinity"]

# Build the cointainer
# docker build -t openvpn-manager .
# Run the container
# docker run -d --name openvpn-container --cap-add=NET_ADMIN -p 1194:1194/udp openvpn-manager
# Connect to the container
# docker exec -it openvpn-container bash