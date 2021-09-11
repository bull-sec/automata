#!/bin/bash

# A wrapper around Nmap for scanning
# Author: @bullsecSecurity

# Added Privileged mode for Custom Scans
# Add the following capabilities to nmap to allow this
# sudo setcap cap_net_raw,cap_net_admin,cap_net_bind_service+eip /usr/bin/nmap
# nmap --privileged should then be aliased

RED='\033[0;41;30m'
PURP='\033[0;45;30m'
GREN='\033[0;42;30m'
ORNG='\033[0;43;30m'
RRED='\e[31m'
STD='\033[0;0;39m'
targets=$(cat target.txt)
outdir=$(pwd)
AUTOMATA_PATH="/home/kali/Tools/automata"

getTarget(){
    read -p "Enter Target IP: " targets
    echo $targets > target.txt
    echo -e "\n"
}

banner(){
    clear
    echo -e "${RED}Automata (Using escape characters to look fancy since 2020) v0.5${STD}\n"
    echo -e "${RRED}
 ▄▄▄       █    ██ ▄▄▄█████▓ ▒█████   ███▄ ▄███▓ ▄▄▄     ▄▄▄█████▓ ▄▄▄      
 ▒████▄     ██  ▓██▒▓  ██▒ ▓▒▒██▒  ██▒▓██▒▀█▀ ██▒▒████▄   ▓  ██▒ ▓▒▒████▄    
 ▒██  ▀█▄  ▓██  ▒██░▒ ▓██░ ▒░▒██░  ██▒▓██    ▓██░▒██  ▀█▄ ▒ ▓██░ ▒░▒██  ▀█▄  
 ░██▄▄▄▄██ ▓▓█  ░██░░ ▓██▓ ░ ▒██   ██░▒██    ▒██ ░██▄▄▄▄██░ ▓██▓ ░ ░██▄▄▄▄██ 
  ▓█   ▓██▒▒▒█████▓   ▒██▒ ░ ░ ████▓▒░▒██▒   ░██▒ ▓█   ▓██▒ ▒██▒ ░  ▓█   ▓██▒
   ▒▒   ▓▒█░░▒▓▒ ▒ ▒   ▒ ░░   ░ ▒░▒░▒░ ░ ▒░   ░  ░ ▒▒   ▓▒█░ ▒ ░░    ▒▒   ▓▒█░
     ▒   ▒▒ ░░░▒░ ░ ░     ░      ░ ▒ ▒░ ░  ░      ░  ▒   ▒▒ ░   ░      ▒   ▒▒ ░
       ░   ▒    ░░░ ░ ░   ░      ░ ░ ░ ▒  ░      ░     ░   ▒    ░        ░   ▒   
             ░  ░   ░                  ░ ░         ░         ░  ░              ░  ░
    ${STD}"
}

# Usage
display_usage() {
        echo -e "\nUsage: ./automata.sh"
    echo -e "Run script, use menu, profit"
}

if [ $# -ge 1 ]
then
    display_usage
        exit 1
fi

# Menu Loop
main_loop(){
    banner
    # Check if we need to prompt for an IP
    if [ ! -f "target.txt" ]; then
        getTarget
    else
        targets=$(cat target.txt)
    fi

    while :
    do
    echo -e "${PURP}Current Target: $targets${STD}\n"
    echo "1. Create Directories"
    echo "2. Custom Nmap Scan"
    echo "3. Full Nmap Scans (preferred)"
    echo "4. Read Nmap Results"
    echo "5. Summarise Previous Scan"
    echo "6. Update/Change Target"
    echo "7. Dump File Tree"
    echo "8. Show the AWESOME banner again"
    echo "9. Create Notes Template"
    echo -e "0. Exit\n" 
    local choice
    read -p "Enter choice [ 1 - 9 ] " choice
    clear
    case $choice in
        1) make_dirs ;;
        2) custom ;;
        3) full ;;
        4) nmap_results ;;
        5) summary ;;
        6) getTarget ;;
        7) dump_filetree ;;
        8) banner ;;
	9) create_notes ;;
        0) exit 0;;
        *) echo -e "${RED}Error...${STD}" && sleep 2
    esac
done
}

make_dirs(){
    mkdir -p $outdir/nmap_results
    mkdir -p $outdir/screenshots
    mkdir -p $outdir/www
    cp -R $AUTOMATA_PATH/.vscode $outdir/
    echo -e "\n${RED}Directories Created${STD}\n"
}

# Do custom scans
custom(){
    make_dirs
    echo -e "${RED}[!] - WARNING, CUSTOM SCANS OVERIDE ANY OTHER SCAN RESULTS ${STD}\n"
    read -p "Please Enter Custom Scan Arguments: " custom_scan

    for ip in $targets; do /usr/bin/nmap --privileged $custom_scan $ip -oN $outdir/nmap_results/custom_scan_$ip.nmap ; done
    echo -n $( cat $outdir/nmap_results/custom_scan_$ip.nmap  | grep open | cut -d "/" -f1) | sed 's/ /,/g' > $outdir/nmap_results/port_list_$ip
    create_notes
    summary
}

# quick(){
#     make_dirs
#     for ip in $targets; do nmap -sV -vvv --top-ports 10000 -n $ip -oN $outdir/nmap_results/quick_scan_$ip.nmap ; done
#     create_notes
# }

full(){
    make_dirs
    echo -e "${RED}Full scan selected, this can take some time${STD}\n"

    # Run a full port scan
    for ip in $targets; do nmap -p- -Pn -vvv -n $ip -oN $outdir/nmap_results/all_ports_$ip ; done

    # Compile a list of ports
    echo -n $( cat $outdir/nmap_results/all_ports_$ip  | grep open | cut -d "/" -f1) | sed 's/ /,/g' > $outdir/nmap_results/port_list_$ip

    # Run Nmap Service Scan on list of ports
    for ip in $targets; do  nmap -sV -sC -vvv -Pn -p $(cat $outdir/nmap_results/port_list_$ip) $ip -oN $outdir/nmap_results/targetted_scan_$ip.nmap ; done
    create_notes
    summary
}

nmap_results(){
    if [ -f "$outdir/nmap_results/custom_scan_$targets.nmap" ]; then
        cat $outdir/nmap_results/custom_scan_$targets.nmap | less
    else
        cat $outdir/nmap_results/targetted_scan_$targets.nmap | less
    fi
}

dump_filetree(){
    find . | sed -e 's/:$//' -e 's/[^-][^\/]*\//──/g' -e 's/─/├/' -e '$s/├/└/' | less
}

create_notes(){
    sleep 2
    echo -e "\n${PURP}Creating Notes Template${STD}\n"
    sleep 2
    for ip in $targets; do echo -e "# Target - $ip\n" ; done > Notes.md

    # Dump the IP/Hostname/DNS names if available
    echo -e "IP Address: $(cat target.txt)" >> Notes.md
    if [ -f "$outdir/nmap_results/custom_scan_$targets.nmap" ]; then
        echo -e "[*] - Hostname: ${GREN} $(cat $outdir/nmap_results/custom_scan_$targets.nmap | grep "scan report" | awk '{print $5}') ${STD}"
        echo -e "[*] - DNS/Host/Common Name: ${GREN} $(cat $outdir/nmap_results/custom_scan_$targets.nmap | grep "DNS_Computer_Name:" | awk '{print $3}' | uniq) ${STD}\n"
    else
        echo -e "Hostname: $(cat $outdir/nmap_results/targetted_scan_$targets.nmap | grep "scan report" | awk '{print $5}')" >> Notes.md
        echo -e "DNS/Host/Common Name: $(cat $outdir/nmap_results/targetted_scan_$targets.nmap | grep "DNS_Computer_Name:" | awk '{print $3}' | uniq)" >> Notes.md
    fi

    # Dump Nmap Results
    echo -e "\n*Nmap Results (clipped)*" >> Notes.md
    echo -e "\n\`\`\`" >> Notes.md
    if [ -f "$outdir/nmap_results/custom_scan_$targets.nmap" ]; then
        cat $outdir/nmap_results/custom_scan_$targets.nmap | grep open >> Notes.md
    else
        cat $outdir/nmap_results/targetted_scan_$targets.nmap | grep open >> Notes.md
    fi
    echo -e "\`\`\`\n" >> Notes.md

    # Print Headers
    echo -e '---' >> Notes.md
    echo -e '\n## Enumeration\n' >> Notes.md
    echo -e '\n## Exploitation\n' >> Notes.md
    echo -e '\n## Privilege Escalation\n' >> Notes.md
    echo -e '\n## Proof\n' >> Notes.md
    echo -e '\n## Remediation\n' >> Notes.md

    }

webserver_check(){                                                                                   
        echo -e "[!] Webservers found:"                                                              
        for port in $(cat $outdir/nmap_results/port_list_$ip | sed 's/,/\n/g'); do 
                if [ $port == "80" ] || 
                        [ $port == "443" ] || 
                        [ $port == "3000" ] ||
                        [ $port == "5000" ] ||
                        [ $port == "7443" ] ||
                        [ $port == "8000" ] || 
                        [ $port == "8001" ] ||
                        [ $port == "8008" ] ||
                        [ $port == "8080" ] ||
                        [ $port == "8083" ] ||
                        [ $port == "8443" ] ||
                        [ $port == "8834" ] ||
                        [ $port == "8888" ]; then
                       echo -e "[*] - ${ORNG} $port ${STD}";
                else
                        continue
                fi
        done
}

interesting_ports(){
        echo -e "\n[!] - Other interesting ports:"
        for port in $(cat $outdir/nmap_results/port_list_$ip | sed 's/,/\n/g'); do
                if [ $port == "21" ] ||
                        [ $port == "22" ] ||
                        [ $port == "23" ] ||
                        [ $port == "445" ] ||
                        [ $port == "3306" ] ||
                        [ $port == "3389" ] ||
                        [ $port == "5432" ] ||
                        [ $port == "1433" ] ||
                        [ $port == "1434" ] ||
                        [ $port == "5900" ] ||
                        [ $port == "33060" ]; then
                        echo -e "[*] - ${ORNG} $port ${STD}"
                else
                        continue
                fi
        done
}

summary(){
    # Reset the $ip variable so we can run the
    # summary() function without running a scan first
    ip=$targets

    # Do the host summary
    echo -e "---===[[ SCAN SUMMARY ]]===---\n"
    echo -e "[!] Found ${GREN} $(cat $outdir/nmap_results/port_list_$ip | sed 's/,/\n/g' | wc | awk '{print $2}') ${STD} Running Services"
    echo -e "[*] - IP: ${GREN} $targets ${STD}"
    if [ -f "$outdir/nmap_results/custom_scan_$targets.nmap" ]; then
        echo -e "[*] - Hostname: ${GREN} $(cat $outdir/nmap_results/custom_scan_$ip.nmap | grep "scan report" | awk '{print $5}') ${STD}"
        echo -e "[*] - DNS Name: ${GREN} $(cat $outdir/nmap_results/custom_scan_$ip.nmap | grep "DNS_Computer_Name:" | awk '{print $3}' | uniq) ${STD}\n"
    else
        echo -e "[*] - Hostname: ${GREN} $(cat $outdir/nmap_results/targetted_scan_$ip.nmap | grep "scan report" | awk '{print $5}') ${STD}"
        echo -e "[*] - DNS Name: ${GREN} $(cat $outdir/nmap_results/targetted_scan_$ip.nmap | grep "DNS_Computer_Name:" | awk '{print $3}' | uniq) ${STD}\n"
    fi

    # Check webservers and interesting ports
    webserver_check
    interesting_ports

    # Output some basic information about the files
    echo -e "\nNotes location: ${PURP} $(readlink -f $outdir)/Notes.md ${STD}"
    echo -e "Scans location: ${PURP} $(readlink -f $outdir/nmap_results/) ${STD}\n"
    echo -e "${RED} THIS IS A SUMMARY, REMEMBER TO CHECK THE NMAP RESULTS! ${STD}\n"
    echo -e "${RED} GOOD HUNTING! ${STD}\n"
    read -p "Press Return to go back to the main menu..."
    clear
}

# Perform the main loop
main_loop

