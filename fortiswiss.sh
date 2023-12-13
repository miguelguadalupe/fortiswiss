#!/bin/bash

#Created By MGuadalupe

# Function to convert CIDR to Subnet Mask
cidr_to_netmask() {
    local i mask=""
    local full_octets=$(($1/8))
    local partial_octet=$(($1%8))

    for ((i=0; i<4; i++)); do
        if [ $i -lt $full_octets ]; then
            mask+=255
        elif [ $i -eq $full_octets ]; then
            mask+=$((256 - 2**(8-$partial_octet)))
        else
            mask+=0
        fi
        test $i -lt 3 && mask+=.
    done

    echo $mask
}

# Function for fgmassconfig script
fgmassconfig() {
    clear -x

    echo "This function is created to facilitate the address creation on the firewalls."
    echo
    # Prompt the user for the name of the IP address object and address group
    read -p "Enter the name of the IP address object: " ip_object_name

    clear -x
    # Open nano to edit the IP list file
    nano ip_list.txt
    cat ip_list.txt | sort -u > temp.txt && mv temp.txt ip_list.txt

    # Read the contents of the IP list file
    ip_list=$(cat ip_list.txt)

    # Store the output in a variable
    output=""
    output+="config firewall address"$'\n'

    # Iterate through each IP address in the list
    for entry in $ip_list; do
        if [[ $entry == *"/"* ]]; then
            # Extract IP address and CIDR suffix
            ip=${entry%/*}
            cidr=${entry#*/}
            netmask=$(cidr_to_netmask $cidr)
        else
            # Default to /32 if no CIDR suffix is given
            ip=$entry
            netmask="255.255.255.255"
        fi

        output+="edit $ip_object_name-$ip"$'\n'
        output+="set subnet $ip $netmask"$'\n'
        output+="show"$'\n'
        output+="next"$'\n'
    done

    output+="end"

    # Display the generated configuration
    echo "======================START OF Configuration======================" | lolcat
    echo
    echo "$output" | lolcat

    echo

    filtered_names=$(echo "$output" | grep -E 'edit ' --color=always | sed 's/edit //' | tr '\n' ' ')

    output2=""
    output2+="config firewall addrgrp"$'\n'
    output2+="edit XXXX"$'\n'
    output2+="show"$'\n'
    output2+="append member $filtered_names"$'\n'
    output2+="show"$'\n'
    output2+="end"

    echo "$output2" | lolcat
    echo
    echo "======================END OF Configuration======================" | lolcat

    rm ip_list.txt
    read -p "Press ENTER to finish: "
}


# function for FQDN
FQDN() {


    clear -x
    # Open nano to edit the IP list file
    nano ip_list.txt
    cat ip_list.txt | sort -u > temp.txt && mv temp.txt ip_list.txt

    # Read the contents of the IP list file
    ip_list=$(cat ip_list.txt)

    # Store the output in a variable
    output=""

    output+="config firewall address"$'\n'

    # Iterate through each IP address in the list
    for ip in $ip_list; do
        output+="edit $ip"$'\n'
        output+="set type fqdn"$'\n'
        output+="set fqdn $ip"$'\n'
        output+="show"$'\n'
        output+="next"$'\n'
    done

    output+="end"

    # Display the generated configuration
    echo "======================START OF Configuration======================" | lolcat
    echo
    echo "$output" | lolcat
    echo
    echo "Append if needed"
    echo

    filtered_names=$(echo "$output" | grep -E 'edit ' --color=always | sed 's/edit //' | tr '\n' ' ')



    output2=""
    output2+="append member $filtered_names"$'\n'
    output2+="show"$'\n'
    output2+="end"


    echo "$output2" | lolcat
    echo
    echo "======================END OF Configuration======================" | lolcat

    rm ip_list.txt

    read -p "Press ENTER to finish "
}


services() {


    clear -x
    # Open nano to edit the IP list file
    nano ip_list.txt
    cat ip_list.txt | sort -u > temp.txt && mv temp.txt ip_list.txt

    # Read the contents of the IP list file
    ip_list=$(cat ip_list.txt)

    # Store the output in a variable
    output=""

    output+="config firewall service custom"$'\n'

    # Iterate through each IP address in the list
    for ip in $ip_list; do
        output+="edit TCP-$ip"$'\n'
        output+="set tcp-portrange $ip"$'\n'
        output+="show"$'\n'
        output+="next"$'\n'
    done

    output+="end"

    # Display the generated configuration
    echo "======================START OF Configuration======================" | lolcat
    echo
    echo "$output" | lolcat
    echo
    echo "Append if needed"
    echo

    filtered_names=$(echo "$output" | grep -E 'edit ' --color=always | sed 's/edit //' | tr '\n' ' ')



    output2=""
    output2+="append service $filtered_names"$'\n'
    output2+="show"$'\n'
    output2+="end"


    echo "$output2" | lolcat
    echo
    echo "======================END OF Configuration======================" | lolcat

    rm ip_list.txt

    read -p "Press ENTER to finish "
}


policylookup() {

    clear -x

    read -p "Enter the source address: " srcaddress
    clear -x
    read -p "Enter the destination address: " dstaddress
    clear -x
    read -p "Enter the destination service port: " serviceport
    clear -x
    read -p "Service port is tcp or udp: " tcudport
    clear -x
    echo "Use this command on the fortigate: 'get router info routing-table details $srcaddress'" | lolcat
    echo
    read -p "Enter the Source Interface: " interface
    echo

    echo "======================This is the command======================" | lolcat
    echo
    echo "diagnose firewall iprope lookup $srcaddress 4444 $dstaddress $serviceport $tcudport $interface" | lolcat
    echo
    echo "===============================================================" | lolcat

    echo

    read -p "Press ENTER to finish "


}








# Function to display the menu
display_menu() {
    menu_text="

    Hello, $USER!
    Welcome to fortiswiss
   *--------------------*
   | 1) Addresses       |
   | 2) FQDN            |
   | 3) Services        |
   | 4) Policy Lookup   |
   |                    |
   | q) Exit            |
   *--------------------*
"
    echo -e "$menu_text" | lolcat
}

# Main loop
while true; do
    clear -x
    display_menu
    read -p "Please Select a value: " -n 1 val
    case "$val" in
        1) fgmassconfig;;
        2) FQDN;;
        3) services;;
        4) policylookup;;
        q) break;;
        *) clear
           echo "Invalid option. Try again.";;
    esac
    sleep 0.8
done
