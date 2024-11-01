#!/bin/bash
#
#      Name    : getip
#      Version : 0.1.0
#      License : GNU General Public License v3.0 (https://www.gnu.org/licenses/gpl-3.0)
#      GitHub  : https://github.com/parapeter/getip
#      Author  : parapeter
#      Mail    : parapeter-git@proton.me
#
#      Copyright (c) 2024 parapeter
#
#      This program is free software: you can redistribute it and/or modify
#      it under the terms of the GNU General Public License as published by
#      the Free Software Foundation, either version 3 of the License, or
#      (at your option) any later version.
#
#      This program is distributed in the hope that it will be useful,
#      but WITHOUT ANY WARRANTY; without even the implied warranty of
#      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#      GNU General Public License for more details.
#
#      You should have received a copy of the GNU General Public License
#      along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Error handling
set -o errexit   # abort on nonzero exitstatus
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes

# Colors
readonly BLUE="\e[34m"
readonly LIGHT_BLUE="\e[94m"
readonly LIGHT_GREEN="\e[92m"
readonly RESET="\e[0m"

# Check if NOT root
[[ ${EUID} == 0 ]] && error "you should not use ${SCRIPT_NAME} as root" && exit 1

# Versioninfos
readonly CURRENT_VERSION="0.1.0"
readonly SCRIPT_NAME="getip"

# Echo helpers
function error {
    echo "[ ${SCRIPT_NAME} ] error: ${1}"
    exit 1
}

# Dependency check
dependencies=( curl jq ipcalc )
for dependency in "${dependencies[@]}"; do
    [[ -z $(command -v "$dependency") ]] && error "${dependency} is not installed"
done

# Parameter handling
for parameter in "$@"; do
    case "$parameter" in
        -v|--version)
            echo "${SCRIPT_NAME}-${CURRENT_VERSION}" && exit 0
            ;;
        *)
            error "illegal parameter ${parameter}"
            ;;
    esac
done

# Get local ip and interface
readonly interfaces=("wlan0" "wlp42s0" "eth0" "enp42s0")
for iface in "${interfaces[@]}"; do
    # Check if interface is up
    if ip link show "$iface" > /dev/null 2>&1; then
        # Extract local ip address
        local_ip_address=$(ip addr show "$iface" | grep 'inet ' | awk '{print $2}') && readonly local_ip_address
        readonly interface=${iface}
    fi
done

# Use ipcalc to get network-, netmask and broadcast-address
ip_calc_output=$(ipcalc "$local_ip_address") && readonly ip_calc_output
local_network=$(echo "$ip_calc_output" | grep -oP 'Network:\s+\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]{1,2})?') && readonly local_network
local_netmask=$(echo "$ip_calc_output" | grep -oP 'Netmask:\s+\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+') && readonly local_netmask
broad_local_ip_address=$(echo "$ip_calc_output" | grep -oP 'Broadcast:\s+\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+') && readonly broad_local_ip_address

# Get global ip from https://ifconfig.me/
if ! public_ip_address=$(curl -s --connect-timeout 5 --max-time 8 https://ifconfig.me/ip) && readonly public_ip_address; then
    error "could not receive ip address"
fi

# Get infos about global ip from https://ipinfo.io/
if ! ipinfo_io_response=$(curl -s --connect-timeout 5 --max-time 8 -H "Accept: application/json" "https://ipinfo.io/${public_ip_address}") && readonly ipinfo_io_response; then
    error "could not receive ip infos"
fi

# Extract Infos from ipinfo_io_response
public_hostname=$(echo "$ipinfo_io_response" | jq -r '.hostname') && readonly public_hostname
public_anycast=$(echo "$ipinfo_io_response" | jq -r '.anycast') && readonly public_anycast
public_city=$(echo "$ipinfo_io_response" | jq -r '.city') && readonly public_city
public_region=$(echo "$ipinfo_io_response" | jq -r '.region') && readonly public_region
public_country=$(echo "$ipinfo_io_response" | jq -r '.country') && readonly public_country
public_loc=$(echo "$ipinfo_io_response" | jq -r '.loc') && readonly public_loc
public_org=$(echo "$ipinfo_io_response" | jq -r '.org') && readonly public_org
public_postal=$(echo "$ipinfo_io_response" | jq -r '.postal') && readonly public_postal
public_timezone=$(echo "$ipinfo_io_response" | jq -r '.timezone') && readonly public_timezone

# Print results after validation
[[ -n "$public_ip_address" && "$public_ip_address" != "null" ]] && echo -e "${BLUE}GLOBAL:${LIGHT_GREEN} ${public_ip_address}${RESET}"
[[ "$local_ip_address" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]] && echo -e "${LIGHT_BLUE}  LOCAL: ${local_ip_address}${RESET}"
[[ -n "$interface" ]] && echo -e "${LIGHT_BLUE}  INTERFACE: ${interface}${RESET}"
[[ "$local_network" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]] && echo -e "${LIGHT_BLUE}  NETWORK: ${local_network}${RESET}"
[[ "$local_netmask" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && echo -e "${LIGHT_BLUE}  NETMASK: ${local_netmask}${RESET}"
[[ "$broad_local_ip_address" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && echo -e "${LIGHT_BLUE}  BROADCAST: ${broad_local_ip_address}${RESET}"
[[ "$public_hostname" != "null" ]] && echo -e "${BLUE}HOSTNAME:${LIGHT_GREEN} ${public_hostname}${RESET}"
[[ "$public_anycast" != "null" ]] && echo -e "${BLUE}ANYCAST:${LIGHT_GREEN} ${public_anycast}${RESET}"
[[ "$public_city" != "null" ]] && echo -e "${BLUE}CITY:${LIGHT_GREEN} ${public_city}${RESET}"
[[ "$public_region" != "null" ]] && echo -e "${BLUE}REGION:${LIGHT_GREEN} ${public_region}${RESET}"
[[ "$public_country" != "null" ]] && echo -e "${BLUE}COUNTRY:${LIGHT_GREEN} ${public_country}${RESET}"
[[ "$public_loc" != "null" ]] && echo -e "${BLUE}LOCATION:${LIGHT_GREEN} ${public_loc}${RESET}"
[[ "$public_org" != "null" ]] && echo -e "${BLUE}AS:${LIGHT_GREEN} ${public_org}${RESET}"
[[ "$public_postal" != "null" ]] && echo -e "${BLUE}POSTAL:${LIGHT_GREEN} ${public_postal}${RESET}"
[[ "$public_timezone" != "null" ]] && echo -e "${BLUE}TIMEZONE:${LIGHT_GREEN} ${public_timezone}${RESET}"
exit 0