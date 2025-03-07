#!/bin/bash

# Set the Instance ID and path to the .env file
INSTANCE_ID="i-0828d309bdb80220c"

# Retrieve the public IP address of the specified EC2 instance
ipv4_address=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

# Path to the .env file
file_to_find="../frontend/.env.docker"

# Check if the .env file exists
if [ ! -f $file_to_find ]; then
    echo -e "\e[31m❌ ERROR: File not found: $file_to_find\e[0m"
    exit 1
fi

# Read the current file content
current_url=$(cat $file_to_find)

# Construct the expected VITE_API_PATH line
new_url="VITE_API_PATH=\"http://${ipv4_address}:31100\""

# Update the .env file if the IP address has changed
if [[ "$current_url" != "$new_url" ]]; then
    sed -i -e "s|VITE_API_PATH.*|$new_url|g" $file_to_find
    echo -e "\e[32m✔ Successfully updated VITE_API_PATH to $new_url\e[0m"
else
    echo -e "\e[33mℹ No changes needed. VITE_API_PATH is already up to date.\e[0m"
fi
