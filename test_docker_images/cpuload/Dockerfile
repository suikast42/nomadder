# Use a base image with a minimal OS
FROM ubuntu:latest

# Install the stress tool
RUN apt-get update && \
    apt-get install -y stress && \
    rm -rf /var/lib/apt/lists/*

# Run stress with high CPU load
CMD ["stress", "--cpu", "8", "--timeout", "3600s"]