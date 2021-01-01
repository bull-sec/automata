#!/bin/bash

# A wrapper around Nmap for scanning
# Author: @bullsecSecurity

RED='\033[0;41;30m'
PURP='\033[0;45;30m'
GREN='\033[0;42;30m'
ORNG='\033[0;43;30m'
RRED='\e[31m'
STD='\033[0;0;39m'

outdir=$(pwd)

getTarget(){
	read -p "Enter Target IP: " targets
	echo -e "\n"
}

banner(){
	clear
	echo -e "\n${RED}Automata (Using escape characters to look fancy since 2020) v0.5${STD}\n"
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
	getTarget
	while :
	do
	echo -e "${RED}Current Target: $targets${STD}"
	echo "1. Create Directories"
	echo "2. Quick Nmap Scan"
	echo "3. Full Nmap Scans (preferred)"
	echo "4. Read Nmap Results"
	echo "5. Summarise Previous Scan"
	echo "6. Update/Change Target"
	echo "7. Dump File Tree"
	echo "8. Show the AWESOME banner again"
	echo -e "9. Exit\n" 
	local choice
	read -p "Enter choice [ 1 - 9 ] " choice
	clear
	case $choice in
		1) make_dirs ;;
		2) quick ;;
		3) full ;;
		4) nmap_results ;;
		5) summary ;;
		6) getTarget ;;
		7) dump_filetree ;;
		8) banner ;;
		9) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
done
}

make_dirs(){
	mkdir -p $outdir/nmap_results
	mkdir -p $outdir/screenshots
	mkdir -p $outdir/www
	echo -e "\n${RED}Directories Created${STD}\n"
}

quick(){
	make_dirs
	for ip in $targets; do nmap -sV -vvv --top-ports 10000 -n $ip -oN $outdir/nmap_results/quick_scan_$ip.nmap ; done
	create_notes
}


full(){
	make_dirs
	echo -e "${RED}Full scan selected, this can take some time${STD}\n"

	# Run a full port scan
	for ip in $targets; do nmap -p- -Pn -vvv -n $ip -oN $outdir/nmap_results/all_ports_$ip ; done

	# Compile a list of ports
	echo -n $( cat $outdir/nmap_results/all_ports_$ip  | grep open | cut -d "/" -f1) | sed 's/ /,/g' >> $outdir/nmap_results/port_list_$ip

	# Run Nmap Service Scan on list of ports
	for ip in $targets; do  nmap -sV -sC -vvv -p $(cat $outdir/nmap_results/port_list_$ip) $ip -oN $outdir/nmap_results/targetted_scan_$ip.nmap ; done
	create_notes
	summary
}

nmap_results(){
	cat $outdir/nmap_results/targetted_scan_$targets.nmap | less
}

dump_filetree(){
	tree | less
}

create_notes(){
	sleep 2
	echo -e "\n${PURP}Creating Notes${STD}\n"
	sleep 2
	for ip in $targets; do echo -e "# Target - $ip\n" ; done > Notes.md

	# Dump Nmap Results
	echo -e "\n*Nmap Results (clipped)*" >> Notes.md
	echo -e "\n\`\`\`" >> Notes.md
	cat $outdir/nmap_results/*.nmap | grep open >> Notes.md
	echo -e "\`\`\`\n" >> Notes.md

	# Notes Area
	echo -e '\n## Target Notes\n' >> Notes.md
	for port in $(cat $outdir/nmap_results/*.nmap | grep open | cut -d "/" -f1); do
		echo -e "### $port\n" >> Notes.md
	done

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
        echo -e "[*] - Hostname: ${GREN} $(cat $outdir/nmap_results/targetted_scan_$ip.nmap | grep "scan report" | awk '{print $5}') ${STD}"
        echo -e "[*] - DNS Name: ${GREN} $(cat $outdir/nmap_results/targetted_scan_$ip.nmap | grep "DNS_Computer_Name:" | awk '{print $3}' | uniq) ${STD}\n"
	
	# Check webservers and interesting ports
        webserver_check
        interesting_ports

	# Output some basic information about the files
        echo -e "\nNotes location: ${PURP} $(readlink -f $outdir) ${STD}"
        echo -e "Scans location: ${PURP} $(readlink -f $outdir/nmap_results/) ${STD}\n"
	echo -e "${RED} THIS IS A SUMMARY, REMEMBER TO CHECK THE NMAP RESULTS! ${STD}\n"
        echo -e "${RED} GOOD HUNTING! ${STD}\n"
	read -p "Press any key to return to the main menu"
	clear
}

# Perform the main loop
main_loop

