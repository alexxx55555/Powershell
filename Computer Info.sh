#!/bin/bash

while true; do

# Display a menu to the user
echo -e "\nPlease select the information you want to see:"
echo "1. Date and time"
echo "2. OS version"
echo "3. Hostname"
echo "4. IP address"
echo "5. MAC address"
echo "6. System uptime"
echo "7. Disk space"
echo "8. Installed software"
echo "9. CPU and memory"
echo "10. Exit"
echo -n "Enter your choice: "

# Read the user's choice
read choice

# Get the selected information
case $choice in
    1)
        echo -e "\nDate and time: $(date)"
        ;;
    2)
        os_version=$(lsb_release -d | awk '{print $2, $3}')
            echo -e "\nOS version: $os_version"
            ;;
    3)
        echo -e "\nHostname: $(hostname)"
        ;;
    4)
        # Get the IPv4 address and store it in a variable
        ip_address=$(ip -4 route get 1 | awk '{print $NF;exit}')
        echo -e "\nIP address: $(ip route get 1 | grep -oP '(?<=src )(\d{1,3}\.){3}\d{1,3}')"
        ;;
    5)
        echo -e "\nMAC address: $(ifconfig | awk '/ether/{print $2}')"
        ;;
    6)
        echo -e "\nSystem uptime: $(uptime -p)"
        ;;
    7)
        echo -e "\nDisk space: $(df -h)"
        ;;
    8)
        echo -e "\nInstalled software: $(dpkg-query -l)"
        ;;
    9)
        echo -e "\nCPU and memory:"
        echo -e "CPU Usage: $(top -bn1 | grep Cpu | awk '{print $2}')%"
        echo -e "Memory Usage: $(free -h | awk '/Mem/{print $3}') used out of $(free -h | awk '/Mem/{print $2}')"
        ;;
    10)
        echo "Exiting script..."
        exit 0
        ;;
    *)
        echo -e "\nInvalid choice"
        ;;
esac

done
