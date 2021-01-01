#!/bin/bash

RED='\033[0;41;30m'
PURP='\033[0;45;30m'
GREN='\033[0;42;30m'
ORNG='\033[0;43;30m'
RRED='\e[31m'
STD='\033[0;0;39m'
targets=$1
outdir=$2

# Usage
display_usage() {
                echo -e "${GREN}Usage: ./automata.sh /path/to/target/file.txt /output/path{$STD}"
}

if [ $# -le 1 ]
then
	display_usage
        exit 1
fi

main_loop(){
	banner
	while :
	do
	echo "1. Just Create Directories"
	echo "2. Do Quick Nmap Scans"
	echo "3. Do Full Nmap Scans"
	echo "4. Get a Summary of a Previous Scan"
	echo "5. Show the awesome banner again"
	echo -e "6. Exit\n" 
	local choice
	read -p "Enter choice [ 1 - 6] " choice
	clear
	case $choice in
		1) make_dirs ;;
		2) quick ;;
		3) full ;;
		4) summary ;;
		5) banner ;;
		6) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
	sleep 2
done
}


make_dirs(){
	mkdir -p $outdir/nmap_results
	mkdir -p $outdir/screenshots
	mkdir -p $outdir/www
	echo -e "\n${RRED}Directories Created${STD}\n"
}


quick(){
	make_dirs
	for ip in $(cat $targets); do nmap -sV -vvv --top-ports 10000 -n $ip -oN $outdir/nmap_results/quick_scan.nmap ; done
	create_notes
}


full(){
	make_dirs
	echo -e "${RED}Full scan selected, this can take some time${STD}"
	for ip in $(cat $targets); do nmap -p- -Pn -vvv -n $ip -oN $outdir/nmap_results/all_ports_$ip ; done

	echo -e "[*] - ${RED}Found the following open ports: ${STD}\n"
	echo -n $( cat $outdir/nmap_results/all_ports_$ip  | grep open | cut -d "/" -f1) | sed 's/ /,/g' | tee $outdir/nmap_results/port_list_$ip
	echo -e "\n"
	for ip in $(cat $targets); do  nmap -sV -sC -vvv -p $(cat $outdir/nmap_results/port_list_$ip) $ip -oN $outdir/nmap_results/targetted_scan_$ip.nmap ; done
	create_notes
}


create_notes(){
	sleep 2
	echo -e "${PURP}Creating Notes${STD}"
	sleep 2
	for ip in $(cat $targets); do echo -e "# Target - $ip\n" ; done | tee Notes.md

	# Dump Nmap Results
	echo -e "\n*Nmap Results (clipped)*" | tee -a Notes.md
	echo -e "\n\`\`\`" | tee -a Notes.md
	cat $outdir/nmap_results/*.nmap | grep open | tee -a Notes.md
	echo -e "\`\`\`\n" | tee -a Notes.md

	# Notes Area
	echo -e '\n## Target Notes\n' | tee -a Notes.md
	for port in $(cat $outdir/nmap_results/*.nmap | grep open | cut -d "/" -f1); do
		echo -e "### $port\n" | tee -a Notes.md
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
	ip=$(cat target.txt)

	# Do the host summary
        echo -e "---===[[ SCAN SUMMARY ]]===---\n"
        echo -e "[*] - Found ${GREN} $(cat $outdir/nmap_results/port_list_$ip | sed 's/,/\n/g' | wc | awk '{print $2}') ${STD} Running Services"
        echo -e "[*] - Hostname: ${GREN} $(cat $outdir/nmap_results/targetted_scan_$ip.nmap | grep "scan report" | awk '{print $5}') ${STD}\n"
	
	# Check webservers and interesting ports
        webserver_check
        interesting_ports

	# Output some basic information about the files
        echo -e "\nNotes location: ${PURP} $(readlink -f $outdir) ${STD}"
        echo -e "Scans location: ${PURP} $(readlink -f $outdir/nmap_results/) ${STD}\n"
        echo -e "${RED} GOOD HUNTING! ${STD}\n"
}

banner(){
	clear
	echo -e "\n${RED}Automata (Using escape characters to look fancy since 2020) v0.4${STD}\n"
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

# Perform the main loop
main_loop
