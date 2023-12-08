import os
import subprocess

while True:
    # Display a menu to the user
    print("\nPlease select the information you want to see:")
    print("1. Date and time")
    print("2. OS version")
    print("3. Hostname")
    print("4. IP address")
    print("5. MAC address")
    print("6. System uptime")
    print("7. Disk space")
    print("8. Installed software")
    print("9. CPU and memory")
    print("10. Exit")
    choice = input("Enter your choice: ")

    # Get the selected information
    if choice == '1':
        print("\nDate and time:", subprocess.getoutput("date"))
    elif choice == '2':
        os_version = subprocess.getoutput("lsb_release -d | awk '{print $2, $3}'")
        print("\nOS version:", os_version)
    elif choice == '3':
        print("\nHostname:", subprocess.getoutput("hostname"))
    elif choice == '4':
        ip_address = subprocess.getoutput("ip route get 1 | awk '{print $7}'")
        print("\nIP address:", ip_address)
    elif choice == '5':
        mac_address = subprocess.getoutput("ifconfig | awk '/ether/{print $2}'")
        print("\nMAC address:", mac_address)
    elif choice == '6':
        print("\nSystem uptime:", subprocess.getoutput("uptime -p"))
    elif choice == '7':
        print("\nDisk space:", subprocess.getoutput("df -h"))
    elif choice == '8':
        print("\nInstalled software:", subprocess.getoutput("dpkg-query -l"))
    elif choice == '9':
        cpu_usage = subprocess.getoutput("top -bn1 | grep Cpu | awk '{print $2}'")
        mem_usage = subprocess.getoutput("free -h | awk '/Mem/{print $3}'")
        mem_total = subprocess.getoutput("free -h | awk '/Mem/{print $2}'")
        print("\nCPU and memory:")
        print("CPU Usage:", cpu_usage, "%")
        print("Memory Usage:", mem_usage, "used out of", mem_total)
    elif choice == '10':
        print("Exiting script...")
        break
    else:
        print("\nInvalid choice")

