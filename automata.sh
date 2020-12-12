#!/bin/bash

RED='\033[0;41;30m'
PURP='\033[0;45;30m'
GREN='\033[0;42;30m'
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
	echo -e "*Open Ports*\n" | tee -a Notes.md
	# Get Port List
	for port in $(cat $outdir/nmap_results/*.nmap | grep open | cut -d "/" -f1); do 
		echo - $port | tee -a Notes.md
	done

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

main_loop

