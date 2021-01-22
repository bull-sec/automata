#!/bin/bash

# The Summary Functions of Automata in a seperate script
clear

RED='\033[0;41;30m'                               
PURP='\033[0;45;30m'                              
GREN='\033[0;42;30m'                          
ORNG='\033[0;43;30m'                                                                                 
STD='\033[0;0;39m'                                                                                                                                                                                         
ip=$(cat target.txt)
outdir=$(pwd)

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
        echo -e "---===[[ SCAN SUMMARY ]]===---\n"
	echo -e "[*] - Found ${GREN} $(cat $outdir/nmap_results/port_list_$ip | sed 's/,/\n/g' |  wc | awk '{print $2}') ${STD} Running Services"
        echo -e "[*] - Hostname: ${GREN}$(cat $outdir/nmap_results/targetted_scan_$ip.nmap | grep "scan report" | awk '{print $5}')${STD}\n"
        webserver_check
        interesting_ports
        echo -e "\nNotes location: ${PURP}$(readlink -f $outdir) ${STD}"
        echo -e "Scans location: ${PURP}$(readlink -f $outdir/nmap_results/) ${STD}\n"
        echo -e "${RED}GOOD HUNTING! ${STD}"
}

summary
