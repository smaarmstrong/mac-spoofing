#!/bin/zsh

# Define the path to the file where the original MAC address will be stored
MAC_ADDRESS_FILE="./original_mac_address.txt"

# Function to get the current MAC address of en0
get_current_mac() {
  ifconfig en0 | awk '/ether/{print $2}'
}

# Function to generate a random MAC address
generate_random_mac() {
  local mac=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/:$//')
  echo "$mac"
}

# Function to check if WiFi is connected to a network
is_wifi_connected() {
  networksetup -getairportnetwork en0 | grep -qv "You are not associated with an active network"
}

# Function to disconnect from the current WiFi network
disconnect_wifi() {
  echo "Turning off WiFi..."
  networksetup -setairportpower en0 off
}

# Function to turn WiFi back on
turn_wifi_on() {
  echo "Turning WiFi back on..."
  networksetup -setairportpower en0 on
}

# Function to set the MAC address
set_mac_address() {
  sudo ifconfig en0 ether $1
}

# Check if the MAC address file exists
if [[ ! -f $MAC_ADDRESS_FILE ]]; then
  # Save the original MAC address if the file doesn't exist
  ORIGINAL_MAC=$(get_current_mac)
  echo "Saving original MAC address: $ORIGINAL_MAC"
  echo $ORIGINAL_MAC > $MAC_ADDRESS_FILE
else
  # Read the saved original MAC address
  ORIGINAL_MAC=$(cat $MAC_ADDRESS_FILE)
  echo "Original MAC address is: $ORIGINAL_MAC"
fi

# Prompt for user confirmation to revert to the original MAC address
echo "Do you want to revert to the original MAC address? (y/n): \c"
read REPLY
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Check if the current MAC address is different from the original
  CURRENT_MAC=$(get_current_mac)
  if [[ $CURRENT_MAC != $ORIGINAL_MAC ]]; then
    # Turn off WiFi
    disconnect_wifi
    sleep 5  # Wait for a few seconds to ensure WiFi is turned off
    
    echo "Reverting to original MAC address: $ORIGINAL_MAC"
    set_mac_address $ORIGINAL_MAC
    turn_wifi_on  # Turn WiFi back on
    sleep 5  # Wait for a few seconds to ensure WiFi is turned on
    
    echo "MAC address has been reverted to: $(get_current_mac)"
  else
    echo "Current MAC address is already the original one."
  fi
fi

# Prompt for user confirmation to change the MAC address
echo "Do you want to change the MAC address? (y/n): \c"
read REPLY
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Turn off WiFi
  disconnect_wifi
  sleep 5  # Wait for a few seconds to ensure WiFi is turned off
  
  # Generate a new MAC address
  NEW_MAC=$(generate_random_mac)
  echo "Generated new MAC address: $NEW_MAC"
  
  # Change the MAC address
  set_mac_address $NEW_MAC
  turn_wifi_on  # Turn WiFi back on
  sleep 5  # Wait for a few seconds to ensure WiFi is turned on
  
  echo "MAC address has been changed to: $(get_current_mac)"
else
  echo "MAC address change aborted by user."
fi
