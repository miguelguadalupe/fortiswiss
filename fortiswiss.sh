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



IPSECVPN() {

    clear -x

#phase1-Information
    echo
    echo "Start the configuration for the Phase 1" | lolcat
    echo
    read -p "Enter the name for the phase1: " VPNName
    echo
    echo "Use this command on the fortigate: 'get router info routing-table details 0.0.0.0/0'" | lolcat
    echo
    read -p "Enter the WAN Interface: " Waninterface
    read -p "Enter the IKE version: " IKE
    read -p "Enter the keylife: " keylife
    read -p "Enter the proposal: " proposal
    read -p "Enter the Diffie Helman Group: " dhgrp
    read -p "Enter the remote gateway: " rgateway

#phase2-Information
    echo
    echo "Start the configuration for the Phase 2" | lolcat
    echo
    read -p "Enter the name for the phase2: " phase2Name
    read -p "Enter the proposal: " proposal2
#    read -p "Enter the Diffie Helman Group: " dhgrp2
    read -p "Enter the keylife: " keylife2
    echo "If any network will be shared place 0.0.0.0/0"
    read -p "Enter the src-subnet " srcnet
    read -p "Enter the dst-subnet " dstnet

#Route Information

    echo "Start the Route Configuration" | lolcat







    output+="config vpn ipsec phase1-interface"$'\n'
    output+="edit $VPNName"$'\n'
    output+="set interface $Waninterface"$'\n'
    output+="set ike-version $IKE"$'\n'
    output+="set keylife $keylife"$'\n'
    output+="set peertype any"$'\n'
    output+="set net-device disable"$'\n'
    output+="set proposal $proposal"$'\n'
    output+="set dhgrp $dhgrp"$'\n'
    output+="set remote-gw $rgateway"$'\n'
    output+="set psksecret *******"$'\n'
    output+="set dpd-retryinterval 10"$'\n'
    output+="show"$'\n'
    output+="end"$'\n'
    output+=$'\n'
    output+="config vpn ipsec phase2-interface"$'\n'
    output+="edit $phase2Name"$'\n'
    output+="set phase1name $VPNName"$'\n'
    output+="set proposal $proposal2"$'\n'
    output+="set dhgrp $dhgrp2"$'\n'
    output+="set keylifeseconds $keylife2"$'\n'
    output+="set auto-negotiate enable"$'\n'
    output+="set src-subnet $srcnet"$'\n'
    output+="set dst-subnet $dstnet"$'\n'
    output+="show"$'\n'
    output+="end"$'\n'
    output+=$'\n'
    output+="config router static"$'\n'
    output+="edit 0"$'\n'
    output+="set dst $dstnet"$'\n'
    output+="set device $VPNName"$'\n'
    output+="show"$'\n'
    output+="end"$'\n'
    output+=$'\n'






    # Display the generated configuration
    echo "======================START OF Configuration======================" | lolcat
    echo
    echo "$output" | lolcat
    echo
    echo "======================END OF Configuration======================" | lolcat


    read -p "Press ENTER to finish "
}




Geo_Configure () {

echo -e "

config firewall address
edit Andorra
set type geography
set country AD
next
edit United_Arab_Emirates
set type geography
set country AE
next
edit Afghanistan
set type geography
set country AF
next
edit Antigua_Barbuda
set type geography
set country AG
next
edit Anguilla
set type geography
set country AI
next
edit Albania
set type geography
set country AL
next
edit Armenia
set type geography
set country AM
next
edit Netherlands_Antilles
set type geography
set country AN
next
edit Angola
set type geography
set country AO
next
edit Antarctica
set type geography
set country AQ
next
edit Argentia
set type geography
set country AR
next
edit American_Samoa
set type geography
set country AS
next
edit Austria
set type geography
set country AT
next
edit Australia
set type geography
set country AU
next
edit Aruba
set type geography
set country AW
next
edit Aland_Islands
set type geography
set country AX
next
edit Azerbaijan
set type geography
set country AZ
next
edit Bosnia_Herzegovina
set type geography
set country BA
next
edit Barbados
set type geography
set country BB
next
edit Bangladesh
set type geography
set country BD
next
edit Belgium
set type geography
set country BE
next
edit Burkina_Faso
set type geography
set country BF
next
edit Bulgaria
set type geography
set country BG
next
edit Bahrain
set type geography
set country BH
next
edit Burundi
set type geography
set country BI
next
edit Benin
set type geography
set country BJ
next
edit Saint_Bartelemey
set type geography
set country BL
next
edit Bermuda
set type geography
set country BM
next
edit Brunei_Darussalam
set type geography
set country BN
next
edit Bolivia
set type geography
set country BO
next
edit Bonaire_St_Eustatius_and_Saba
set type geography
set country BQ
next
edit Brazil
set type geography
set country BR
next
edit Bahamas
set type geography
set country BS
next
edit Bhutan
set type geography
set country BT
next
edit Bouvet_Island
set type geography
set country BV
next
edit Botswana
set type geography
set country BW
next
edit Belarus
set type geography
set country BY
next
edit Belize
set type geography
set country BZ
next
edit Canada
set type geography
set country CA
next
edit Cocos_Keeling_Islands
set type geography
set country CC
next
edit Congo_Democratic_Repub
set type geography
set country CD
next
edit Central_African_Republic
set type geography
set country CF
next
edit Congo
set type geography
set country CG
next
edit Switzerland
set type geography
set country CH
next
edit Cote_d_Ivoire
set type geography
set country CI
next
edit Cook_Islands
set type geography
set country CK
next
edit Chile
set type geography
set country CL
next
edit Cameroon
set type geography
set country CM
next
edit China
set type geography
set country CN
next
edit Colombia
set type geography
set country CO
next
edit Costa_Rica
set type geography
set country CR
next
edit Cuba
set type geography
set country CU
next
edit Cape_Verde
set type geography
set country CV
next
edit Curacao
set type geography
set country CW
next
edit Christmas_Island
set type geography
set country CX
next
edit Cyprus
set type geography
set country CY
next
edit Czech_Republic
set type geography
set country CZ
next
edit Germany
set type geography
set country DE
next
edit Djibouti
set type geography
set country DJ
next
edit Denmark
set type geography
set country DK
next
edit Dominican
set type geography
set country DM
next
edit Dominican_Republic
set type geography
set country DO
next
edit Algeria
set type geography
set country DZ
next
edit Ecuador
set type geography
set country EC
next
edit Estonia
set type geography
set country EE
next
edit Egypt
set type geography
set country EG
next
edit Western_Sahara
set type geography
set country EH
next
edit Eritrea
set type geography
set country ER
next
edit Spain
set type geography
set country ES
next
edit Ethiopia
set type geography
set country ET
next
edit Finland
set type geography
set country FI
next
edit Fiji
set type geography
set country FJ
next
edit Falkland_Islands_Malvinas
set type geography
set country FK
next
edit Micronesia_Federated_States
set type geography
set country FM
next
edit Faroe_Islands
set type geography
set country FO
next
edit France
set type geography
set country FR
next
edit Gabon
set type geography
set country GA
next
edit United_Kingdom
set type geography
set country GB
next
edit Grenada
set type geography
set country GD
next
edit Georgia
set type geography
set country GE
next
edit French_Guiana
set type geography
set country GF
next
edit Guernsey
set type geography
set country GG
next
edit Ghana
set type geography
set country GH
next
edit Gibraltar
set type geography
set country GI
next
edit Greenland
set type geography
set country GL
next
edit Gambia
set type geography
set country GM
next
edit Guinea
set type geography
set country GN
next
edit Guadeloupe
set type geography
set country GP
next
edit Equatorial_Guinea
set type geography
set country GQ
next
edit Greece
set type geography
set country GR
next
edit South_Georgia_and_South_Sandwich_Islands
set type geography
set country GS
next
edit Guatemala
set type geography
set country GT
next
edit Guam
set type geography
set country GU
next
edit Guinea-Bissau
set type geography
set country GW
next
edit Guyana
set type geography
set country GY
next
edit Hong_Kong
set type geography
set country HK
next
edit Heard_and_Mcdonald_Islands
set type geography
set country HM
next
edit Honduras
set type geography
set country HN
next
edit Croatia
set type geography
set country HR
next
edit Haiti
set type geography
set country HT
next
edit Hungary
set type geography
set country HU
next
edit Indonesia
set type geography
set country ID
next
edit Ireland
set type geography
set country IE
next
edit Israel
set type geography
set country IL
next
edit Isle_of_Man
set type geography
set country IM
next
edit India
set type geography
set country IN
next
edit British_Indian_Ocean_Territory
set type geography
set country IO
next
edit Iraq
set type geography
set country IQ
next
edit Iran
set type geography
set country IR
next
edit Iceland
set type geography
set country IS
next
edit Italy
set type geography
set country IT
next
edit Jersey
set type geography
set country JE
next
edit Jamaica
set type geography
set country JM
next
edit Jordan
set type geography
set country JO
next
edit Japan
set type geography
set countr JP
next
edit Kenya
set type geography
set country KE
next
edit Kyrgyzstan
set type geography
set country KG
next
edit Cambodia
set type geography
set country KH
next
edit Kiribati
set type geography
set country KI
next
edit Comoros
set type geography
set country KM
next
edit Saint_Kitts_and_Nevis
set type geography
set country KN
next
edit North_Korea
set type geography
set country KP
next
edit South_Korea
set type geography
set country KR
next
edit Kuwait
set type geography
set country KW
next
edit Cayman_Islands
set type geography
set country KY
next
edit Kazakhstan
set type geography
set country KZ
next
edit Lao_Peoples_Democratic_Rep
set type geography
set country LA
next
edit Lebanon
set type geography
set country LB
next
edit Saint_Lucia
set type geography
set country LC
next
edit Liechtenstein
set type geography
set country LI
next
edit Sri_Lanka
set type geography
set country LK
next
edit Liberia
set type geography
set country LR
next
edit Lesotho
set type geography
set country LS
next
edit Lithuania
set type geography
set country LT
next
edit Luxembourg
set type geography
set country LU
next
edit Latvia
set type geography
set country LV
next
edit Lbyan_Arab_Jamahiriya
set type geography
set country LY
next
edit Morocco
set type geography
set country MA
next
edit Monaco
set type geography
set country MC
next
edit Moldova
set type geography
set country MD
next
edit Montenegro
set type geography
set country ME
next
edit Saint_Martin
set type geography
set country MF
next
edit Madagascar
set type geography
set country MG
next
edit Marshall_Islands
set type geography
set country MH
next
edit Macedonia
set type geography
set country MK
next
edit Mali
set type geography
set country ML
next
edit Myanmar
set type geography
set country MM
next
edit Mongolia
set type geography
set country MN
next
edit Macao
set type geography
set country MO
next
edit Northern_Mariana_Islands
set type geography
set country MP
next
edit Martinique
set type geography
set country MQ
next
edit Mauritania
set type geography
set country MR
next
edit Montserrat
set type geography
set country MS
next
edit Malta
set type geography
set country MT
next
edit Mauritius
set type geography
set country MU
next
edit Maldives
set type geography
set country MV
next
edit Malawi
set type geography
set country MW
next
edit Mexico
set type geography
set country MX
next
edit Malaysia
set type geography
set country MY
next
edit Mozambique
set type geography
set country MZ
next
edit Namibia
set type geography
set country NA
next
edit New_Caledonia
set type geography
set country NC
next
edit Niger
set type geography
set country NE
next
edit Norfolk_Island
set type geography
set country NF
next
edit Nigeria
set type geography
set country NG
next
edit Nicaragua
set type geography
set country NI
next
edit Netherlands
set type geography
set country NL
next
edit Norway
set type geography
set country NO
next
edit Nepal
set type geography
set country NP
next
edit Nauru
set type geography
set country NR
next
edit Niue
set type geography
set country NU
next
edit New_Zealand
set type geography
set country NZ
next
edit Oman
set type geography
set country OM
next
edit Panama
set type geography
set country PA
next
edit Peru
set type geography
set country PE
next
edit French_Polynesia
set type geography
set country PF
next
edit Papua_New_Guinea
set type geography
set country PG
next
edit Phillipines
set type geography
set country PH
next
edit Pakistan
set type geography
set country PK
next
edit Poland
set type geography
set country PL
next
edit St_Pierre_and_Miquelon
set type geography
set country PM
next
edit Pitcairn
set type geography
set country PN
next
edit Puerto_Rico
set type geography
set country PR
next
edit Palestinian_Territory
set type geography
set country PS
next
edit Portugal
set type geography
set country PT
next
edit Palau
set type geography
set country PW
next
edit Paraguay
set type geography
set country PY
next
edit Qatar
set type geography
set country QA
next
edit Reunion
set type geography
set country RE
next
edit Romania
set type geography
set country RO
next
edit Serbia
set type geography
set country RS
next
edit Russia
set type geography
set country RU
next
edit Rwanda
set type geography
set country RW
next
edit Saudi_Arabia
set type geography
set country SA
next
edit Solomon_Islands
set type geography
set country SB
next
edit Seychelles
set type geography
set country SC
next
edit Sudan
set type geography
set country SD
next
edit Sweden
set type geography
set country SE
next
edit Singapore
set type geography
set country SG
next
edit Saint_Helena
set type geography
set country SH
next
edit Slovenia
set type geography
set country SI
next
edit Svalbard_and_Jan_Mayen
set type geography
set country SJ
next
edit Slovakia
set type geography
set country SK
next
edit Sierra_Leone
set type geography
set country SL
next
edit San_Marino
set type geography
set country SM
next
edit Senegal
set type geography
set country SN
next
edit Somalia
set type geography
set country SO
next
edit Suriname
set type geography
set country SR
next
edit South_Sudan
set type geography
set country SS
next
edit Sao_Tome_and_Principe
set type geography
set country ST
next
edit El_Salvador
set type geography
set country SV
next
edit Sint_Maarten
set type geography
set country SX
next
edit Syrian_Arab_Republic
set type geography
set country SY
next
edit Swaziland
set type geography
set country SZ
next
edit Turks_and_Caicos_Islands
set type geography
set country TC
next
edit Chad
set type geography
set country TD
next
edit French_Southern_Territories
set type geography
set country TF
next
edit Togo
set type geography
set country TG
next
edit Thailand
set type geography
set country TH
next
edit Tajikistan
set type geography
set country TJ
next
edit Tokelau
set type geography
set country TK
next
edit TimorLeste
set type geography
set country TL
next
edit Turkmenistan
set type geography
set country TM
next
edit Tunisia
set type geography
set country TN
next
edit Tonga
set type geography
set country TO
next
edit Turkey
set type geography
set country TR
next
edit Trinidad_and_Tobago
set type geography
set country TT
next
edit Tuvalu
set type geography
set country TV
next
edit Taiwan
set type geography
set country TW
next
edit Tanzania
set type geography
set country TZ
next
edit Ukraine
set type geography
set country UA
next
edit Uganda
set type geography
set country UG
next
edit US_Minor_Outlying_Islands
set type geography
set country UM
next
edit United_States
set type geography
set country US
next
edit Uruguay
set type geography
set country UY
next
edit Uzbekistan
set type geography
set country UZ
next
edit Holy_See_Vatican_State
set type geography
set country VA
next
edit St_Vincent_and_Grenadines
set type geography
set country VC
next
edit Venezuela
set type geography
set country VE
next
edit British_Virgin_Islands
set type geography
set country VG
next
edit US_Virgin_Islands
set type geography
set country VI
next
edit Vietnam
set type geography
set country VN
next
edit Vanuatu
set type geography
set country VU
next
edit Wallis_and_Futuna
set type geography
set country WF
next
edit Samoa
set type geography
set country WS
next
edit Kosovo
set type geography
set country XK
next
edit Yemen
set type geography
set country YE
next
edit Mayotte
set type geography
set country YT
next
edit South_Africa
set type geography
set country ZA
next
edit Zambia
set type geography
set country ZM
next
edit Zimbabwe
set type geography
set country ZW
next
end
config firewall addrgrp
edit GEO_Fence
set member Afghanistan Aland_Islands Albania Algeria American_Samoa Andorra Angola Anguilla Antarctica Antigua_Barbuda Argentia Armenia Aruba Australia Austria Azerbaijan Bahamas Bahrain Bangladesh Barbados Belarus Belgium Belize Benin Bermuda Bhutan Bolivia Bonaire_St_Eustatius_and_Saba Bosnia_Herzegovina Botswana Bouvet_Island Brazil British_Indian_Ocean_Territory British_Virgin_Islands Brunei_Darussalam Bulgaria Burkina_Faso Burundi Cambodia Cameroon Cape_Verde Cayman_Islands Chad Chile China Christmas_Island Cocos_Keeling_Islands Colombia Costa_Rica Comoros Congo Congo_Democratic_Repub Central_African_Republic Cook_Islands Cote_d_Ivoire Croatia Cuba Curacao Cyprus Czech_Republic Denmark Djibouti Dominican Dominican_Republic Ecuador Egypt El_Salvador Equatorial_Guinea Eritrea Estonia Ethiopia Falkland_Islands_Malvinas Faroe_Islands Fiji Finland France French_Guiana French_Polynesia French_Southern_Territories Gabon Georgia Germany Ghana Gibraltar Greece Greenland Gambia Grenada Guadeloupe Guam Guatemala Guernsey Guinea Guinea-Bissau Guyana Haiti Heard_and_Mcdonald_Islands Holy_See_Vatican_State Honduras Hong_Kong Hungary Iceland India Indonesia Iran Iraq Ireland Isle_of_Man Israel Italy Jamaica Japan Jersey Jordan Kazakhstan Kenya Kiribati Kosovo Kuwait Kyrgyzstan Lao_Peoples_Democratic_Rep Latvia Lbyan_Arab_Jamahiriya Lebanon Lesotho Liberia Liechtenstein Lithuania Luxembourg Macao Macedonia Madagascar Malawi Malaysia Maldives Mali Malta Marshall_Islands Martinique Mauritania Mauritius Mayotte Mexico Micronesia_Federated_States Moldova Monaco Mongolia Montenegro Montserrat Morocco Mozambique Myanmar Namibia Nauru Nepal Netherlands Netherlands_Antilles New_Caledonia New_Zealand Nicaragua Niger Nigeria Niue Norfolk_Island North_Korea Northern_Mariana_Islands Norway Oman Pakistan Palau Palestinian_Territory Panama Papua_New_Guinea Paraguay Peru Phillipines Pitcairn Poland Portugal Puerto_Rico Qatar Reunion Romania Russia Rwanda Saint_Bartelemey Saint_Helena Saint_Kitts_and_Nevis Saint_Lucia Saint_Martin Samoa San_Marino Sao_Tome_and_Principe Saudi_Arabia Senegal Serbia Seychelles Sierra_Leone Singapore Sint_Maarten Slovakia Slovenia Solomon_Islands Somalia South_Africa South_Georgia_and_South_Sandwich_Islands South_Korea South_Sudan Spain Sri_Lanka St_Pierre_and_Miquelon St_Vincent_and_Grenadines Sudan Suriname Svalbard_and_Jan_Mayen Swaziland Sweden Switzerland Syrian_Arab_Republic Taiwan Tajikistan Tanzania Thailand TimorLeste Togo Tokelau Tonga Trinidad_and_Tobago Tunisia Turkey Turkmenistan Turks_and_Caicos_Islands Tuvalu Uganda Ukraine United_Arab_Emirates Uruguay Uzbekistan Vanuatu Venezuela Vietnam Wallis_and_Futuna Western_Sahara Yemen Zambia Zimbabwe
end
" | lolcat

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
   | 5) IPSEC VPN       |
   | 6) GEOFence        |
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
        5) IPSECVPN;;
        6) Geo_Configure;;

        q) break;;
        *) clear
           echo "Invalid option. Try again.";;
    esac
    sleep 0.8
done
