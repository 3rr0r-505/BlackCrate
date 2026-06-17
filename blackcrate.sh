#!/usr/bin/env bash

# blackcrate - offensive security tool checker
# checks installation status of offsec tools category-wise
# not an installer — detection only

VERSION="v1.1.0"

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Error: Do not source this script. Run it directly."
    return 1
fi

# ─── data structures ─────────────────────────────────────────────────────────
# separate ordered arrays for categories and aliases to preserve output order
# bash associative arrays are unordered — never iterate them directly for display

declare -A tools
declare -A category_map
declare -a order
declare -a alias_order

# ─── category order ───────────────────────────────────────────────────────────
# defines the display order of categories in output

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

# ─── alias order ──────────────────────────────────────────────────────────────
# mirrors category order — used to display aliases in consistent order

alias_order=(
    "recon-passive"
    "recon-active"
    "web"
    "passwords"
    "exploit"
    "ad"
    "linux-privesc"
    "windows-privesc"
    "network"
    "c2"
    "pivot"
    "wireless"
    "re"
    "forensics"
    "crypto"
    "wordlists"
    "utils"
)

# ─── alias -> category map ────────────────────────────────────────────────────
# maps short CLI aliases to full category names for --category flag

category_map["recon-passive"]="Reconnaissance - Passive"
category_map["recon-active"]="Reconnaissance - Active"
category_map["web"]="Web Application"
category_map["passwords"]="Password & Hash Attacks"
category_map["exploit"]="Exploitation"
category_map["ad"]="Active Directory & Windows"
category_map["linux-privesc"]="Linux Privilege Escalation"
category_map["windows-privesc"]="Windows Privilege Escalation"
category_map["network"]="Network & Traffic"
category_map["c2"]="Post Exploitation & C2"
category_map["pivot"]="Pivoting & Tunneling"
category_map["wireless"]="Wireless"
category_map["re"]="Reverse Engineering"
category_map["forensics"]="Forensics & Steganography"
category_map["crypto"]="Encoding & Crypto"
category_map["wordlists"]="Wordlists & Payloads"
category_map["utils"]="Utility & Workflow"

# ─── tool list ────────────────────────────────────────────────────────────────
# naming convention:
#   plain name   -> binary/cli tool  (detected via command -v + whereis)
#   name.ext     -> script or file   (detected via find by filename)
#   name/        -> directory        (detected via find by dirname)

tools["Reconnaissance - Passive"]="whois dig host nslookup theHarvester maltego recon-ng spiderfoot amass dnsx subfinder shodan censys"
tools["Reconnaissance - Active"]="nmap masscan rustscan netdiscover nuclei nikto whatweb wafw00f sslscan testssl.sh"
tools["Web Application"]="burpsuite ffuf gobuster feroxbuster dirsearch sqlmap xsstrike arjun wfuzz caido jwt_tool dalfox"
tools["Password & Hash Attacks"]="hashcat john hydra medusa cewl crunch cupp mentalist hash-identifier hashid"
tools["Exploitation"]="msfconsole msfvenom searchsploit"
tools["Active Directory & Windows"]="psexec.py secretsdump.py GetUserSPNs.py GetNPUsers.py wmiexec.py smbclient.py mimikatz.py bloodhound sharphound bloodhound-python crackmapexec netexec evil-winrm kerbrute kerberoast ldapdomaindump enum4linux enum4linux-ng smbmap rpcclient powerview rubeus"
tools["Linux Privilege Escalation"]="peass-ng/ lse.sh pspy-binaries/"
tools["Windows Privilege Escalation"]="peass-ng/ wesng powersploit/"
tools["Network & Traffic"]="wireshark tshark tcpdump responder mitm6 bettercap netcat ncat"
tools["Post Exploitation & C2"]="sliver havoc empire cobalt-strike"
tools["Pivoting & Tunneling"]="chisel ligolo-ng sshuttle proxychains socat plink"
tools["Wireless"]="aircrack-ng airodump-ng aireplay-ng hcxdumptool hcxtools wifite kismet"
tools["Reverse Engineering"]="ghidra radare2 cutter gdb pwndbg peda binwalk strings file exiftool ltrace strace"
tools["Forensics & Steganography"]="volatility3 autopsy foremost scalpel steghide zsteg exiftool"
tools["Encoding & Crypto"]="openssl base64 xxd od"
tools["Wordlists & Payloads"]="wordlists/ seclists/ rockyou.txt"
tools["Utility & Workflow"]="tmux codium curl wget jq python3 php ruby base64 xxd scp rsync ssh"

# ─── colors ───────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── display & help ───────────────────────────────────────────────────────────
# show_banner -> ASCII art logo with bold version tag right-aligned beneath it
# show_help  -> usage, flags, aliases, legend
# show_tools -> category-wise tool list without installation check

show_banner() {
    echo "__________.__                 __   _________                __          ";
    echo "\\______   \\  | _____    ____ |  | _\\_   ___ \\____________ _/  |_  ____  ";
    echo " |    |  _/  | \\__  \\ _/ ___\\|  |/ /    \\  \\/\\_  __ \\__  \\\\   __\\/ __ \\ ";
    echo " |    |   \\  |__/ __ \\\\  \\___|    <\\     \\____|  | \\// __ \\|  | \\  ___/ ";
    echo " |______  /____(____  /\\___  >__|_ \\\\______  /|__|  (____  /__|  \\___  >";
    echo "        \\/          \\/     \\/     \\/       \\/            \\/          \\/ ";
    printf -v padded "%71s" "$VERSION"
    echo -e "${BOLD}${padded}${RESET}"
}

show_help() {
    show_banner
    echo -e "
    ${BOLD}BlackCrate${RESET} - Offensive Security Tool Checker

    ${BOLD}USAGE${RESET}
    blackcrate [OPTION] [ARGUMENT]

    ${BOLD}OPTIONS${RESET}
    --init                     Install blackcrate to system PATH
    --upgrade                  Upgrade to the latest version from GitHub
    --purge                    Remove blackcrate from system
    --list-all                 Show all tools (installed + missing)
    --installed                Show only installed tools
    --missing                  Show only missing tools
    --category <alias>         Check a specific category by alias
    --tools                    Show category-wise tools list
    --help, -h                 Display this help message
    --version, -v              Show installed version

    ${BOLD}EXAMPLES${RESET}
    blackcrate.sh
    blackcrate.sh --list-all
    blackcrate.sh --installed
    blackcrate.sh --missing
    blackcrate.sh --category web
    blackcrate.sh --category ad
    blackcrate --init
    blackcrate --upgrade
    blackcrate --purge

    ${BOLD}CATEGORY ALIASES${RESET}
    recon-passive              Reconnaissance - Passive
    recon-active               Reconnaissance - Active
    web                        Web Application
    passwords                  Password & Hash Attacks
    exploit                    Exploitation
    ad                         Active Directory & Windows
    linux-privesc              Linux Privilege Escalation
    windows-privesc            Windows Privilege Escalation
    network                    Network & Traffic
    c2                         Post Exploitation & C2
    pivot                      Pivoting & Tunneling
    wireless                   Wireless
    re                         Reverse Engineering
    forensics                  Forensics & Steganography
    crypto                     Encoding & Crypto
    wordlists                  Wordlists & Payloads
    utils                      Utility & Workflow

    ${BOLD}LEGEND${RESET}
    ${GREEN}[✔]${RESET} installed / exists
    ${RED}[✘]${RESET} not installed
    "
}

show_tools() {
    show_banner
    echo -e "
    Reconnaissance - Passive        whois, dig, host, nslookup, theHarvester,
                                    maltego, recon-ng, spiderfoot, amass, dnsx,
                                    subfinder, shodan, censys

    Reconnaissance - Active         nmap, masscan, rustscan, netdiscover, nuclei,
                                    nikto, whatweb, wafw00f, sslscan, testssl.sh

    Web Application                 burpsuite, ffuf, gobuster, feroxbuster,
                                    dirsearch, sqlmap, xsstrike, arjun, wfuzz,
                                    caido, jwt_tool, dalfox

    Password & Hash Attacks         hashcat, john, hydra, medusa, cewl, crunch,
                                    cupp, mentalist, hash-identifier, hashid

    Exploitation                    msfconsole, msfvenom, searchsploit

    Active Directory & Windows      psexec.py, secretsdump.py, GetUserSPNs.py,
                                    GetNPUsers.py, wmiexec.py, smbclient.py,
                                    mimikatz.py, bloodhound, sharphound,
                                    bloodhound-python, crackmapexec, netexec,
                                    evil-winrm, kerbrute, kerberoast,
                                    ldapdomaindump, enum4linux, enum4linux-ng,
                                    smbmap, rpcclient, powerview, rubeus

    Linux Privilege Escalation      peass-ng/, lse.sh, pspy

    Windows Privilege Escalation    peass-ng/, powerup, wesng

    Network & Traffic               wireshark, tshark, tcpdump, responder,
                                    mitm6, bettercap, netcat, ncat

    Post Exploitation & C2          sliver, havoc, powershell-empire, cobalt-strike

    Pivoting & Tunneling            chisel, ligolo-ng, sshuttle, proxychains,
                                    socat, plink

    Wireless                        aircrack-ng, airodump-ng, aireplay-ng,
                                    hcxdumptool, hcxtools, wifite, kismet

    Reverse Engineering             ghidra, radare2, cutter, gdb, pwndbg, peda,
                                    binwalk, strings, file, exiftool, ltrace, strace

    Forensics & Steganography       volatility3, autopsy, foremost, scalpel,
                                    steghide, zsteg, exiftool

    Encoding & Crypto               openssl, base64, xxd, od

    Wordlists & Payloads            wordlists/, seclists/, rockyou.txt

    Utility & Workflow              tmux, curl, wget, jq, python3, php, ruby,
                                    base64, xxd, scp, rsync, ssh
    "
}

# ─── self-management ──────────────────────────────────────────────────────────
# _init_self     -> installs blackcrate to a writable system bin dir in PATH
# _purge_self    -> removes the installed blackcrate binary
# _upgrade_self  -> fetches latest version from GitHub, replaces if newer

_fetch() {
    local url="$1" dest="$2"
    if command -v curl &>/dev/null; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget &>/dev/null; then
        wget -q "$url" -O "$dest"
    else
        echo "Error: Neither curl nor wget is available."
        echo ""
        return 1
    fi
}

_check_sudo() {
    if ! command -v sudo &>/dev/null; then
        echo "Error: sudo is required but not available on this system."
        echo ""
        exit 1
    fi
}

_init_self(){
    show_banner
    _check_sudo
    PREFERRED=("/usr/local/bin" "/usr/bin" "/bin" "/usr/local/sbin")
    INSTALL_DIR=""

    for dir in "${PREFERRED[@]}"; do
        if [[ ":$PATH:" == *":$dir:"* ]]; then
            INSTALL_DIR="$dir"
            break
        fi
    done

    if [[ -z "$INSTALL_DIR" ]]; then
        echo "Error: None of the standard bin directories found in PATH"
        echo ""
        exit 1
    fi

    DEST="$INSTALL_DIR/blackcrate"

    if [[ -f "$DEST" ]]; then
        echo "Already installed at $DEST. Use --upgrade to update."
        echo ""
        exit 0
    fi

    sudo cp "$0" "$DEST"
    sudo chmod +x "$DEST"
    sudo chown "$USER:$USER" "$DEST"
    echo "BlackCrate Installed Successfully → $DEST"
    echo ""
    rm -f "$0"
    exit 0
}

_purge_self() {
    show_banner
    _check_sudo
    PREFERRED=("/usr/local/bin" "/usr/bin" "/bin" "/usr/local/sbin")

    rm -f "/tmp/blackcrate.tmp"
    for dir in "${PREFERRED[@]}"; do
        if [[ -f "$dir/blackcrate" ]]; then
            sudo rm "$dir/blackcrate"
            echo "Blackcrate Removed → $dir/blackcrate"
            echo ""
            exit 0
        fi
    done

    echo "Blackcrate is not installed."
    echo ""
    exit 1
}

_upgrade_self() {
    show_banner
    _check_sudo
    PREFERRED=("/usr/local/bin" "/usr/bin" "/bin" "/usr/local/sbin")
    DEST=""

    for dir in "${PREFERRED[@]}"; do
        if [[ -f "$dir/blackcrate" ]]; then
            DEST="$dir/blackcrate"
            break
        fi
    done

    if [[ -z "$DEST" ]]; then
        echo "Blackcrate is not installed. Run --init first."
        echo ""
        exit 1
    fi

    TMP="/tmp/blackcrate.tmp"
    REMOTE_URL="https://raw.githubusercontent.com/3rr0r-505/BlackCrate/refs/heads/main/blackcrate.sh"

    echo "Checking for updates..."
    if ! _fetch "$REMOTE_URL" "$TMP"; then
        echo "Error: Failed to fetch latest version."
        echo ""
        rm -f "$TMP"
        exit 1
    fi

    if [[ ! -s "$TMP" ]] || ! bash -n "$TMP" &>/dev/null; then
        echo "Error: Downloaded file is invalid or corrupted."
        echo ""
        rm -f "$TMP"
        exit 1
    fi

    REMOTE_VERSION=$(grep "^VERSION=" "$TMP" | cut -d'=' -f2 | tr -d '"')

    if [[ -z "$REMOTE_VERSION" ]]; then
        echo "Error: Could not determine remote version."
        echo ""
        rm -f "$TMP"
        exit 1
    fi

    if diff -q "$DEST" "$TMP" &>/dev/null; then
        echo "Already up to date."
        echo ""
        rm -f "$TMP"
        exit 0
    fi

    sudo cp "$TMP" "$DEST"
    sudo chmod +x "$DEST"
    sudo chown "$USER:$USER" "$DEST"
    rm -f "$TMP"
    echo "BlackCrate Upgraded → $REMOTE_VERSION"
    echo ""
    exit 0
}

# ─── detection ────────────────────────────────────────────────────────────────
# is_installed  -> checks binaries via command -v and whereis -b
# file_exists   -> checks scripts/files via find by exact filename
# dir_exists    -> checks directories via find by dirname (strips trailing /)
# find_alias    -> resolves short alias to full category name

is_installed() {
    command -v "$1" &>/dev/null || whereis -b "$1" | grep -q "/$1"
}

file_exists() {
    find / -type f -name "$1" 2>/dev/null | grep -q .
}

dir_exists() {
    find / -type d -name "${1%/}" 2>/dev/null | grep -q .
}

find_alias() {
    local alias=$1
    if [[ -n "${category_map[$alias]}" ]]; then
        echo "${category_map[$alias]}"
    else
        echo ""
    fi
}

# ─── output functions ─────────────────────────────────────────────────────────
# check_all       -> show installed + missing (default)
# check_installed -> show only installed
# check_missing   -> show only missing
# check_category  -> show single category by alias
# show_tools      -> list all tools category-wise without checking
# show_help       -> usage, flags, aliases, legend

check_installed() {
    show_banner
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
    show_banner
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
    show_banner
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

check_category() {
    show_banner
    local category
    category=$(find_alias "$1")

    if [[ -z "$category" ]]; then
        echo "Unknown category: $1"
        echo "Valid aliases:"
        for alias in "${alias_order[@]}"; do
            printf "  %-20s %s\n" "$alias" "${category_map[$alias]}"
        done
        echo ""
        exit 1
    fi

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

    echo ""
}

# ─── entry point ──────────────────────────────────────────────────────────────
# no args defaults to check_all

main() {
    case "${1:-}" in
        --init)
            _init_self
            ;;
        --purge)
            _purge_self
            ;;
        --upgrade)
            _upgrade_self
            ;;
        --installed)
            check_installed
            ;;
        --missing)
            check_missing
            ;;
        --list-all)
            check_all
            ;;
        --tools)
            show_tools
            ;;
        --help|-h)
            show_help
            ;;
        --version|-v)
            show_banner
            ;;
        --category)
            if [[ -z "$2" ]]; then
                echo "Usage: blackcrate.sh --category <alias>"
                echo "Use --help for valid aliases."
                exit 1
            fi
            check_category "$2"
            ;;
        "")
            check_all
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
}

main "$@"
