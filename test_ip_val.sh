#!/bin/bash


# Funktioner som kollar om en ip-adress är en ip-adress
bra_IP () {
    local ip=$1
    local stat=1

    if [[ $ip =~ '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' ]]; then
	OIFS=$IFS
	IFS='.'
	ip=($ip)
	IFS=$OIFS
	[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
	stat=$?
    else
	echo "Var inget korrekt IP"
    fi
    return $stat
}

# Denna är den bästa funktion jag har hittat för IP-adresser
is_ip () {
    case "$*" in ""|*[!0-9.]*|*[!0-9]) return 1 ;;
    esac
    local IFS=.
    set -- $*
    [ $# -eq 4 ] && [[ $1 -le 255 ]] && [[ $2 -le 255 ]] && [[ $3 -le 255 ]] && [[ $4 -le 255 ]]
}

# kontroll via en en while loop
echo "Start while loop!"
echo ""
while true
do
    echo -n "IP nummer tack: "
    read nummer
    if is_ip $nummer;
    then
	echo "OK"
	break
    else
	echo "Ingen IP adress!"
    fi
done
echo "Done med while loop"
echo $nummer
echo

# Kontroll via en until loop
echo "until loppen start"
echo
echo -n "Ett IP nummer tack: "
read nums
until is_ip $nums; do
    echo -n "Det var inget korrekt IP-nummer, försök igen: "
    read nums
done
echo $nums
echo

echo ""
echo -n " klart "
read 
