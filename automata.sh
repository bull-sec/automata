#!/bin/bash

RED='\033[0;41;30m'
PURP='\033[0;45;30m'
GREN='\033[0;42;30m'
ORNG='\033[0;43;30m'
STD='\033[0;0;39m'
targets=$1
outdir=$2

# "Banner" lol
echo -e "\n${RED}Automata (a BASH command you could probably memorise...) v0.2${STD}\n"

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
	echo "1. Just Create Directories"
	echo "2. Do Quick Nmap Scans"
	echo "3. Do Full Nmap Scans"
	echo -e "4. Exit\n" 
	local choice
	read -p "Enter choice [ 1 - 4] " choice
	case $choice in
		1) make_dirs ;;
		2) quick ;;
		3) full ;;
		4) exit 0;;
		*) echo -e "${RED}Error...${STD}" && sleep 2
	esac
	webserver_check
	interesting_ports
	summary
}


make_dirs(){
	mkdir -p $outdir/nmap_results
	mkdir -p $outdir/screenshots
	mkdir -p $outdir/www
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
	echo -e "${RED}[*] - Found $(cat $outdir/nmap_results/port_list_$ip | sed 's/,/\n/g' | wc -l) Running Services${STD}"
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
		       echo -e "${PURP}Possible Webserver Found on Port:" $port ${STD};
		else
			continue
		fi
	done
}

interesting_ports(){
	echo -e "${ORNG}[!] - Found some other interesting ports:${STD}"
	for port in $(cat $outdir/nmap_results/port_list_$ip | sed 's/,/\n/g'); do
		if [ $port == "21" ] ||
			[ $port == "23" ] ||
			[ $port == "3306" ] ||
			[ $port == "3389" ] ||
			[ $port == "5432" ] ||
			[ $port == "1433" ] ||
			[ $port == "1434" ] ||
			[ $port == "5900" ]; then
			echo -e "${ORNG} [$] $port ${STD}"
		else
			continue
		fi
	done
}

summary(){
	echo -e "\n"
	echo -e "${PURP}Notes written to $(readlink -f $outdir) ${STD}"
	echo -e "${PURP}Scans written to $(readlink -f $outdir/nmap_results/) ${STD}"
	echo -e "${RED}GOOD HUNTING! ${STD}"
}


main_loop

