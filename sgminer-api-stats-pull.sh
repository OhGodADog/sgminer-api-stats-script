#!/bin/bash

rm -rf log*.txt


SGMINER_HOSTS=($(nmap -p4028 192.168.0.0/24 -oG - | grep 4028/open | egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"))

if [ ${#SGMINER_HOSTS[@]} -eq 0 ];
then
	echo "No sgminer ports found, are settings correct?"
	exit 1
fi


GPU_COUNT=()
VERSION_CHECK=()

i=0

while [[ $i -lt ${#SGMINER_HOSTS[@]} ]]
do
	GPU_COUNT+=($(echo -n "gpucount" | nc ${SGMINER_HOSTS[i]} 4028 | grep -a -oP '(?<=Count=)\w+'))
	VERSION_CHECK+=($(echo -n "version" | nc ${SGMINER_HOSTS[i]} 4028 | grep -a -o "TeamRedMiner\|sgminer" | sort --unique))
	true $(( i++ ))
done


if [ ${#VERSION_CHECK[@]} -eq 0 ];
	then
	echo "Miner is not sgminer fork. Exiting."
	exit 1

fi


z=0

while [[ $z -lt ${#SGMINER_HOSTS[@]} ]]
do
	x=0
	while [[ $x -lt ${GPU_COUNT[z]} ]]
	do
		echo -n "gpu|$x" | nc ${SGMINER_HOSTS[z]} 4028 >> log"$z".txt
		true $(( x++ ))
		done

	true $(( z++ ))
done

w=0

while [ $w -lt ${#SGMINER_HOSTS[@]} ] | [ $w -lt ${#VERSION_CHECK[@]} ]
do

	if [[ ${VERSION_CHECK[w]} = "TeamRedMiner" ]]
		then
		sed -i 's/STATUS/\n&/g' log"$w".txt
		sed -i '1d' log"$w".txt
		sed -i 's/^.*GPU=/GPU=/' log"$w".txt
		sed -i 's/Temperature=0.00.*Powertune=[0-9],//' log"$w".txt
		sed -i -r 's/Utility=[0-9].*Rejected%=[0-9]\.[0-9]//' log"$w".txt
		echo -e "\nHost identity: ${SGMINER_HOSTS[w]}" >> log"$w".txt
		echo -e "\nDetected miner: ${VERSION_CHECK[w]}" >> log"$w".txt
		echo -e "\nAMD ADL is not used by ${VERSION_CHECK[w]}, GPU monitoring is off, output cleaned." >> log"$w".txt
	elif [[ ${VERSION_CHECK[w]} = "sgminer" ]]
		then
		sed -i 's/STATUS/\n&/g' log"$w".txt
		sed -i '1d' log"$w".txt
		sed -i 's/^.*GPU=/GPU=/' log"$w".txt
		echo -e "\nHost identity: ${SGMINER_HOSTS[w]}" >> log"$w".txt
		echo -e "\nDetected miner: ${VERSION_CHECK[w]}" >> log"$w".txt
		echo -e "\nOutput cleaned" >> log"$w".txt
	else
		if [ ${#SGMINER_HOSTS[@]} -lt 2 ]
			then
			echo "Unknown miner version. Exiting."
			exit 1
		else
			echo "One of the detected miners is not supported version."
		fi
	fi

	true $(( w++ ))
done


cat log*.txt
