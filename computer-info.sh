#!/bin/bash

while true; do

    # Display a menu to the user
    echo "Please select the information you want to see:"
    echo "1. Date and time"
    echo "2. OS version"
    echo "3. Hostname"
    echo "4. IP address"
    echo "5. MAC address"
    echo "6. System uptime"
    echo "7. Disk space"
    echo "8. Installed software"
    echo "9. All information"
    echo "10. Exit"
    echo -n "Enter your choice: "

    # Read the user's choice
    read choice

    # Get the selected information
    case $choice in
        1)
            echo "Date and time: $(date)"
            ;;
        2)
            echo "OS version: $(uname -v)"
            ;;
        3)
            echo "Hostname: $(hostname)"
            ;;
        4)
            # Get the IPv4 address and store it in a variable
            ip_address=$(ip -4 route get 1 | awk '{print $NF;exit}')
            echo "IP address: $(ip route get 1 | grep -oP '(?<=src )(\d{1,3}\.){3}\d{1,3}')"


            ;;
        5)
            echo "MAC address: $(ifconfig | awk '/ether/{print $2}')"
            ;;
        6)
            echo "System uptime: $(uptime -p)"
            ;;
        7)
            echo "Disk space: $(df -h)"
            ;;
        8)
            echo "Installed software: $(dpkg-query -l)"
            ;;
        9)
            # Get all the information and display it together
            echo "Date and time: $(date)"
            echo "OS version: $(uname -v)"
            echo "Hostname: $(hostname)"
            ip_address=$(ip -4 route get 1 | awk '{print $NF;exit}')
            echo "IP address: $ip_address"
            echo "MAC address: $(ifconfig | awk '/ether/{print $2}')"
            echo "System uptime: $(uptime -p)"
            echo "Disk space: $(df -h)"
            echo "Installed software: $(dpkg-query -l)"
            ;;
        10)
            echo "Exiting script..."
            exit 0
            ;;
        *)
            echo "Invalid choice"
            ;;
    esac

done
