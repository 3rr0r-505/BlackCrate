#!/usr/bin/env bash

declare -A tools
declare -a order

order=(
    "Reconnaissance - Passive"
    "Reconnaissance - Active"
    "Web Application"
    "Password & Hash Attacks"
    "Exploitation"
    "Active Directory & Windows"
    "Linux Privilege Escalation"
    "Windows Privilege Escalation"
    "Network & Traffic"
    "Post Exploitation & C2"
    "Pivoting & Tunneling"
    "Wireless"
    "Reverse Engineering"
    "Forensics & Steganography"
    "Encoding & Crypto"
    "Wordlists & Payloads"
    "Utility & Workflow"
)

tools["Reconnaissance - Passive"]="whois dig host nslookup theHarvester maltego recon-ng spiderfoot amass dnsx subfinder shodan censys"
tools["Reconnaissance - Active"]="nmap masscan rustscan netdiscover nuclei nikto whatweb wafw00f sslscan testssl.sh"
tools["Web Application"]="burpsuite ffuf gobuster feroxbuster dirsearch sqlmap xsstrike arjun wfuzz caido jwt_tool dalfox"
tools["Password & Hash Attacks"]="hashcat john hydra medusa cewl crunch cupp mentalist hash-identifier hashid"
tools["Exploitation"]="msfconsole msfvenom searchsploit"
tools["Active Directory & Windows"]="psexec.py secretsdump.py GetUserSPNs.py GetNPUsers.py wmiexec.py smbclient.py mimikatz.py bloodhound sharphound bloodhound-python crackmapexec netexec evil-winrm kerbrute kerberoast ldapdomaindump enum4linux enum4linux-ng smbmap rpcclient powerview rubeus"
tools["Linux Privilege Escalation"]="peass-ng/ lse.sh pspy"
tools["Windows Privilege Escalation"]="peass-ng/ powerup wesng"
tools["Network & Traffic"]="wireshark tshark tcpdump responder mitm6 bettercap netcat ncat"
tools["Post Exploitation & C2"]="sliver havoc powershell-empire cobalt-strike"
tools["Pivoting & Tunneling"]="chisel ligolo-ng sshuttle proxychains socat plink"
tools["Wireless"]="aircrack-ng airodump-ng aireplay-ng hcxdumptool hcxtools wifite kismet"
tools["Reverse Engineering"]="ghidra radare2 cutter gdb pwndbg peda binwalk strings file exiftool ltrace strace"
tools["Forensics & Steganography"]="volatility3 autopsy foremost scalpel steghide zsteg exiftool"
tools["Encoding & Crypto"]="openssl base64 xxd od"
tools["Wordlists & Payloads"]="wordlists/ seclists/ rockyou.txt"
tools["Utility & Workflow"]="tmux curl wget jq python3 php ruby base64 xxd scp rsync ssh"

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

is_installed() {
    command -v "$1" &>/dev/null || whereis -b "$1" | grep -q "/$1"
}

file_exists() {
    find / -type f -name "$1" 2>/dev/null | grep -q .
}

dir_exists() {
    find / -type d -name "${1%/}" 2>/dev/null | grep -q .
}

show_help() {
    cat << EOF
BlackCrate - Offensive Security Tool Checker

Usage:
  ./blackcrate.sh [OPTION]

Options:
  --installed      Show only installed tools
  --missing        Show only missing tools
  --list-all       Show installed and missing tools
  --help, -h       Display this help message

Examples:
  ./blackcrate.sh --installed
  ./blackcrate.sh --missing
  ./blackcrate.sh --list-all
  ./blackcrate.sh --help

Legend:
  [✔] Installed / Exists
  [✘] Not Installed

EOF
}

check_installed() {
    for category in "${order[@]}"; do
        echo ""
        printf "${BOLD}==================== %s ====================${RESET}\n" "$category"
        for tool in ${tools[$category]}; do
            if is_installed "$tool"; then
                printf "  ${GREEN}[✔] %s: installed${RESET}\n" "$tool"
            elif [[ "$tool" == */ ]] && dir_exists "$tool"; then
                printf "  ${GREEN}[✔] %s: dir exists${RESET}\n" "$tool"
            elif [[ "$tool" == *.* ]] && file_exists "$tool"; then
                printf "  ${GREEN}[✔] %s: file exists${RESET}\n" "$tool"
            else
                continue
            fi
        done
    done

    echo ""
}

check_missing() {
    for category in "${order[@]}"; do
        echo ""
        printf "${BOLD}==================== %s ====================${RESET}\n" "$category"
        for tool in ${tools[$category]}; do
            if is_installed "$tool"; then
                continue
            elif [[ "$tool" == */ ]] && dir_exists "$tool"; then
                continue
            elif [[ "$tool" == *.* ]] && file_exists "$tool"; then
                continue
            else
                printf "  ${RED}[✘] %s: not installed${RESET}\n" "$tool"
            fi
        done
    done

    echo ""
}

check_all() {
    for category in "${order[@]}"; do
        echo ""
        printf "${BOLD}==================== %s ====================${RESET}\n" "$category"
        for tool in ${tools[$category]}; do
            if is_installed "$tool"; then
                printf "  ${GREEN}[✔] %s: installed${RESET}\n" "$tool"
            elif [[ "$tool" == */ ]] && dir_exists "$tool"; then
                printf "  ${GREEN}[✔] %s: dir exists${RESET}\n" "$tool"
            elif [[ "$tool" == *.* ]] && file_exists "$tool"; then
                printf "  ${GREEN}[✔] %s: file exists${RESET}\n" "$tool"
            else
                printf "  ${RED}[✘] %s: not installed${RESET}\n" "$tool"
            fi
        done
    done

    echo ""
}

main() {
    case "${1:-}" in
        --installed)
            check_installed
            ;;
        --missing)
            check_missing
            ;;
        --list-all)
            check_all
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
}

main "$@"