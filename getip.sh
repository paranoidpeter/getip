#!/bin/bash
#
#      Name    : getip
#      Version : 0.1.0
#      License : GNU General Public License v3.0 (https://www.gnu.org/licenses/gpl-3.0)
#      GitHub  : https://github.com/paranoidpeter/getip
#      Author  : paranoidpeter
#      Mail    : peterparanoid@proton.me
#
#      Copyright (c) 2024 paranoidpeter
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

# Versioninfos
readonly current_version="0.1.0"
readonly script_name="getip"

# Echo helpers
function error {
    echo "[ ${script_name} ] error: ${1}"
    exit 1
}

# Dependency check
dependencies=( curl jq )
for dependency in "${dependencies[@]}"; do
    [[ -z $(command -v "$dependency") ]] && error "${dependency} is not installed"
done

# Parameter handling
for parameter in "$@"; do
    case "$parameter" in
        -v|--version)
            echo "${script_name}-${current_version}" && exit 0
            ;;
        *)
            error "illegal parameter ${parameter}"
            ;;
    esac
done

# Get IP and IP infos
if ! ip_address=$(curl -s --connect-timeout 5 --max-time 8 https://ifconfig.me/ip) && readonly ip_adress; then
    error "could not receive ip address"
fi

if ! response=$(curl -s --connect-timeout 5 --max-time 8 -H "Accept: application/json" "https://ipinfo.io/${ip_address}") && readonly response; then
    error "could not receive ip infos"
fi

# Extract Infos from response
hostname=$(echo "${response}" | jq -r '.hostname')
anycast=$(echo "${response}" | jq -r '.anycast')
city=$(echo "${response}" | jq -r '.city')
region=$(echo "${response}" | jq -r '.region')
country=$(echo "${response}" | jq -r '.country')
loc=$(echo "${response}" | jq -r '.loc')
org=$(echo "${response}" | jq -r '.org')
postal=$(echo "${response}" | jq -r '.postal')
timezone=$(echo "${response}" | jq -r '.timezone')

# Print results
[[ -n "${ip_address}" && "${ip_address}" != "null" ]] && echo "IP: ${ip_address}"
[[ "${hostname}" != "null" ]] && echo "Hostname: ${hostname}"
[[ "${anycast}" != "null" ]] && echo "Anycast: ${anycast}"
[[ "${city}" != "null" ]] && echo "City: ${city}"
[[ "${region}" != "null" ]] && echo "Region: ${region}"
[[ "${country}" != "null" ]] && echo "Country: ${country}"
[[ "${loc}" != "null" ]] && echo "Location: ${loc}"
[[ "${org}" != "null" ]] && echo "Organization: ${org}"
[[ "${postal}" != "null" ]] && echo "Postalcode: ${postal}"
[[ "${timezone}" != "null" ]] && echo "Timezone: ${timezone}"
exit 0
