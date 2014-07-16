#!/bin/bash
#
# To gather information to all variables.
adapt=$(ip route | awk '/default/ { print $5 }')
dator=$(ip addr list dev $adapt | grep 'inet ' | awk '{ print $2 }' | cut -d '.' -f 1,2,3)
net=$(ip addr list dev $adapt | grep 'inet ' | awk '{ print $2 }' | cut -d '.' -f 4 | cut -d '/' -f 2)

# subnet=10
anet=8
bnet=16
cnet=24
samlingH=samling_hosts.txt
samlingA=samling_allt.txt

# Construct a meny so I don't have to make one everytime.
showMenu () { 
     echo "########################################"
     echo " Tell me what you are looking for? : "
     echo "########################################"
     echo " [1] - Everything! (Warning wall of text)"
     echo " [2] - Machine description"
     echo " [3] - Where the machine is?"
     echo " [4] - Sammanfattning av maskin"
     echo " [5] - Disk information på maskin"
     echo " [6] - Processer igång på maskin"
     echo 
     echo " [q] - Avsluta!"
     echo "########################################"
     echo -n "Gör ditt val! : "
}

# Meny för att få välja ip-adress
menyIP () {
    echo
    echo "Vilket ip-nummer vill du använda?"
    echo " - - - - - - - - - - - - -"
    echo " [A] - Hela subnätet"
    echo " [E] - Egen vald ip-adress"
    echo " [L] - Lista aktiva maskiner"
    echo " [Q] - Tillbaka"
    echo " - - - - - - - - - - - - -"
    echo -n " Ditt Val: "
}

menySubnet () {
    echo 
    echo
    echo "Alla vakna datorer i ditt subnät kommer att kollas!";
    echo "Vill du använda nmap eller vanlig ping?";
    echo " [N] - nmap, du måste ha de installerat.";
    echo " [P] - ping, kommer att ta lång tid att gå igenom alla.";
    echo " [Q] - Gå tillbaka";
    echo -n " Ditt val: ";
}

fil_koll () {
    if [ -f "$plats$namnet" ]; then
	echo "Finns redan en fil med det namnet!"
	ls -l "$plats$namnet"
	echo -n "Tryck <ENTER> för att avsluta detta: "
    else
	echo "Namnet ledigt! Vi kör på"
	touch "$plats$namnet"
	cat $samlingH > "$plats$namnet"
    fi
}

# Funktion som kollar om input är en korrekt IP-adress
bra_ip () {
    case "$*" in ""|*[!0-9.]*|*[!0-9]) return 1 ;;
    esac
    local IFS=.
    set -- $*
    [ $# -eq 4 ] && [[ $1 -le 255 ]] && [[ $2 -le 255 ]] && [[ $3 -le 255 ]] && [[ $4 -le 255 ]]
}

# På kalla att man vill ha ut ett subnät
ta_subnet () {
    if [ $net -ge $cnet ]; then
	subnet='1-255'
	echo "Subnätet blir, "$cnet
    elif [ $net -le $cent ] && [ $net >= $bnet ]; then
	subnet=$bnet
	echo "Subnätet blir, "$bnet
    elif [ $net -lt $bnet ]; then
	subnet=$anet
	echo "Subnätet blir, "$anet
    fi
}
# Pinga varje maskin och se om den är uppe, i subnätet
ping_koll () {
    ta_subnet 
    for comp in `seq 1 $subnet`;
    do
	echo $comp" / "$subnet
	svar=`ping -c 1 $dator.$comp | tr -d "\-\-\-\n" | grep '1 received' | cut -d ' ' -f 2`
	if [ -n '$svar' ]; then
	    echo $dator'.'$comp >> $samlingH
	fi
    done
}
# Med hjälp av nmap kolla vilka datorer som är uppe och svarar, snabbt sätt
nmap_koll () {
    ta_subnet
    if [ -n ""@"" ];
    then
	nmap -sP $dator.1-255 | grep 'report' | awk '{ print $5$6 }' > $samlingH
    else
	echo "något blev fel!"
    fi
}

# Själva koden. En huvudmeny som sedan går till en submeny för val av IP-nummer.
# Kvar att göra, är att ha en for loop som går igenom alla vakna datorer.
while true
do
    clear
    showMenu
    read titta
    echo
    case $titta in 
    # Vill ha en siffra eller ordet för siffran.
	"1"|"ett"|"one") # Allt om allt
	    while true
	    do
		clear
		echo "- Allt! - "
		menyIP
		read valet
	        case $valet in
		# Tänkt att man ska kunna skriva stor eller liten bokstav.
		    "A"|"a") # Ett helt subnät ska kollas
			while true
			do
			    menySubnet;
			    read vald;
			    case $vald in
				"N"|"n")
				    nmap_koll;
				    while read lina;
				    do
					snmpwalk -v 2c -c rlnd $lina:5160 | tee -a $samlingA
				    done < $samlingH
				    echo "Sammanställning finns nu i filen "$samlingA;
				    echo;
				    echo -n "Tryck <ENTER> för att komma tillbaka.";
				    read ;
				    break ;;
				"P"|"p")
				    ping_koll;
				    while read lina;
				    do
					snmpwalk -v 2c -c rlnd $lina:5160 | tee -a $samlingA
				    done < $samlingH
				    echo "Sammanställning finns nu i filen "$samlingA;
				    echo;
				    echo -n "Tryck <ENTER> för att komma tillbaka.";
				    read ;
				    break ;;
				"Q"|"q")
				    break ;;
			    esac
			done
			;;
		    "E"|"e") # Enskild ip-adress ska kollas
			echo -n "Vilket IP-nummer?: ";
			read nummer;
			until bra_ip $nummer;
			do
			    echo -n "Inget IP-nummer, försök igen: "
			    read nummer
			done
			echo;
			snmpwalk -v 2c $nummer:5160 -c rlnd | tee samling_allt.txt;
			echo "Tryck <ENTER> för att komma tillbaka.";
			read ;;
		    "L"|"l") # Lista ska göras
			nmap_koll;
			antal=`cat $samlingH | wc -l`;
			echo; 
			echo "Antal maskiner som är uppe: "$antal;
			echo "Vad vill du göra med denna information";
			select vad in visa spara avsluta
			do
			    case $vad in
				"visa")
				    echo;
				    cat $samlingH;;
				"spara")
				    echo;
				    echo -n "Vad vill du kalla filen: ";
				    read namnet;
				    echo -n "Vart vill du lägga filen, avsluta med ett /: ";
				    read plats;
				    echo;
				    fil_koll;
				    ls -l "$plats$namnet";
				    echo -n "Då var det klart! tryck <ENTER>";
				    read;
				    break ;;
				"avsluta")
				    break ;;
			    esac
			done 
			;;
		    "Q"|"q")
			break ;;
		esac
	    done
            ;;

	"2"|"två"|"two") # Vad som körs
	    while true
	    do
		clear
		echo "- Beskrivning av maskin -"
		menyIP
		read valet
		case $valet in
		    "A"|"a") 
			while true
			do
			    menySubnet;
			    read vald;
			    case $vald in
				"N"|"n")
				    nmap_koll;
				    while read lina;
				    do
					snmpwalk -v 2c -c rlnd $lina:5160 sysDescr | tee -a $samlingA
				    done < $samlingH
				    echo "Sammanställning finns nu i filen "$samlingA;
				    echo;
				    echo -n "Tryck <ENTER> för att komma tillbaka.";
				    read ;
				    break ;;
				"P"|"p")
				    ping_koll;
				    while read lina;
				    do
					snmpwalk -v 2c -c rlnd $lina:5160 sysDescr | tee -a $samlingA
				    done < $samlingH
				    echo "Sammanställning finns nu i filen "$samlingA;
				    echo;
				    echo -n "Tryck <ENTER> för att komma tillbaka.";
				    read ;
				    break ;;
				"Q"|"q")
				    break ;;
			    esac
			done 
			;;
		    "E"|"e") 
		        echo -n "Vilket IP?: "; 
		        read nummer;
			until bra_ip $nummer;
			do
			    echo -n "Inget IP-nummer, försök igen: "
			    read nummer
			done
			snmpwalk -v 2c $nummer:5160 -c rlnd sysDescr | tee samling_addr.txt ;
		        echo;
			echo -n "Tryck <ENTER> för att komma tillbaka.";
			read ;
			break;;
		    "L"|"l") # Lista maskiner
			nmap_koll;
			antal=`cat $samlingH | wc -l`;
			echo; 
			echo "Antal maskiner som är uppe: "$antal;
			echo "Vad vill du göra med denna information";
			select vad in visa spara avsluta
			do
			    case $vad in
				"visa")
				    echo;
				    cat $samlingH;;
				"spara")
				    echo;
				    echo -n "Vad vill du kalla filen: ";
				    read namnet;
				    echo -n "Vart vill du lägga filen, avsluta med ett /: ";
				    read plats;
				    echo;
				    fil_koll;				    				    
				    ls -l $plats$namnet;
				    echo -n "Då var det klart! tryck <ENTER> ";
				    read;
				    break ;;
				"avsluta")
				    break ;;
			    esac
			done 
			;;
		    "Q"|"q") 
			break;;
		esac
	    done
            ;;

	"3"|"tre"|"three") # Vart står maskinen
	    echo -n "Vilken maskin letar du efter? (IPnr): ";
	    read nummer;
	    until bra_ip $nummer;
	    do
		echo -n "Inget IP-nummer, försök igen: "
		read nummer
	    done
	    snmpwalk -v 2c $nummer:5160 -c rlnd location | awk '{print $4, $5, $6, $7, $8}' ;
	    echo;
	    echo -n "Tryck <ENTER> för att komma tillbaka.";
	    read ;;

	"4"|"fyra"|"four") # En sammanställning görs
	    echo -n "Vilken maskin gäller det? (IPnr): ";
	    read nummer;
	    until bra_ip $nummer;
	    do
		echo -n "Ej korrekt IP-nummer, försök igen: "
		read nummer
	    done
	    echo "* * * * * * * * * * * * * * * * * * * * *" >> samling.txt ;
	    snmpwalk -v 2c $nummer:5160 -c rlnd sysName.0 | tee -a samling.txt ;
	    snmpwalk -v 2c $nummer:5160 -c rlnd sysLocation.0 | tee -a samling.txt ;
	    snmpwalk -v 2c $nummer:5160 -c rlnd UpTime | tee -a samling.txt ;
	    snmpwalk -v 2c $nummer:5160 -c rlnd ipAddressIfIndex.ipv4 | tee -a samling.txt ;
	    echo;
	    echo -n "Tryck <ENTER> för att komma tillbaka.";
	    read ;;

	"5"|"fem"|"five") 
	    echo -n "Vilken maskin gäller det? (IPnr): ";
	    read nummer;
	    until bra_ip $nummer;
	    do
		echo -n "Ej korrekt IP-nummer, försök igen: "
		read nummer
	    done
	    echo "* * * * * * * * * * * * * * * * * * * * *" >> disk.txt ;
	    snmpwalk -v 2c -c rlnd $nummer:5160 hrStorage | tee -a disk.txt ;
	    snmpwalk -v 2c -c rlnd $nummer:5160 hrFSMountPoint | tee -a disk.txt ;
	    echo ;
	    echo -n "Tryck <ENTER> för att komma tillbaka.";
	    read ;;

	"6"|"sex"|"six") 
	    echo -n "Vilken maskin gäller det? (IPnr): ";
	    read nummer;
	    until bra_ip $nummer;
	    do
		echo -n "Ej ett korrekt IP-nummer, försök igen: "
		read nummer
	    done
	    snmpwalk -v 2c -c rlnd $nummer:5160 hrSWRunName ;
	    echo;
	    echo -n "Tryck <ENTER> för att komma tillbaka.";
	    read ;;
	
	"9"|"nio")
	    echo "Test centralen här, vad ska testas?"
	    echo
	    select vad in braip nmap ping subnet quit
	    do
		case $vad in
		    "braip")
			echo -n "Ge mig ett IP: ";
			read ipnum;
			bra_ip $ipnum;
			sleep 5;
			;;
		    "nmap")
			echo "Testar om nmap genererar något!";
			echo;
			nmap_koll;
			cat $samlingH;
			sleep 5;
			;;
		    "ping")
			echo "Testar om ping generarar något!";
			echo;
			ping_koll;
			cat $samlingH;
			;;
		    "subnet")
			echo "Kollar vad output på subnet funktion blir";
			echo;
			ta_subnet;
			echo "subnät är "$net" och valör blir då " $subnet;
			;;
		    "quit")
			break ;;
		esac
	    done		
	    ;;

	"q"|"Q") 
	    exit 0 ;
	    echo;
	    echo -n "Tryck <ENTER> för att komma tillbaka.";
	    read ;;
	*)   
	    echo "Nu har du gjort ett felaktigt val!" ;
	    echo;
	    echo -n "Tryck <ENTER> för att komma tillbaka.";
	    read ;;
    esac
done
