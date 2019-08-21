#!/bin/bash

rm -rf log*.txt


PORT=4028

if [[ -s hosts.txt ]];
then
	echo "Host file found, loading hosts..."
	IFS=$'\n' SGMINER_HOSTS=($(cat hosts.txt))
else
	echo "No host file found, using nmap to find all hosts in the network"
	SGMINER_HOSTS=($(nmap -p4028 192.168.0.0/24 -oG - | grep $PORT/open | egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"))
fi


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
	GPU_COUNT+=($(echo -n "gpucount" | nc ${SGMINER_HOSTS[i]} $PORT | grep -a -oP '(?<=Count=)\w+'))
	VERSION_CHECK+=($(echo -n "version" | nc ${SGMINER_HOSTS[i]} $PORT | grep -a -o "TeamRedMiner [0-9].[0-9].[0-9]\|sgminer" | sort --unique))
	true $(( i++ ))
done


if [ ${#VERSION_CHECK[@]} -eq 0 ];
then
	echo "Miner is not sgminer fork. Exiting."
	exit 1

fi


z=0

UPTIME_SECONDS=()

while [[ $z -lt ${#SGMINER_HOSTS[@]} ]]
do
	x=0
	while [[ $x -lt ${GPU_COUNT[z]} ]]
	do
		echo -n "gpu|$x" | nc ${SGMINER_HOSTS[z]} $PORT >> log"$z".txt
		true $(( x++ ))
		done
	UPTIME_SECONDS=$(echo -n "summary" | nc ${SGMINER_HOSTS[z]} $PORT | grep -o 'Elapsed=[0-9]*' | sed 's\Elapsed=\\g')
	ALGORITHM=$(echo -n "devdetails" | nc ${SGMINER_HOSTS[z]} $PORT | grep -o "Kernel=.*" | cut -f1 -d ",")

	true $(( z++ ))
done

UPTIME_HOURS=$(echo "scale=2; $UPTIME_SECONDS/3600" | bc -l)

w=0

while [ $w -lt ${#SGMINER_HOSTS[@]} ] | [ $w -lt ${#VERSION_CHECK[@]} ]
do

	if [[ ${VERSION_CHECK[w]} = "sgminer" || "TeamRedMiner" ]]
		then
		sed -i 's/STATUS/\n&/g' log"$w".txt
		sed -i '1d' log"$w".txt
		sed -i 's/^.*GPU=/GPU=/' log"$w".txt
		sed -i 's/\<GPU Activity\>.*\Powertune=[0-9]\>//g' log"$w".txt
		sed -i 's/\<\Utility\>.*//g' log"$w".txt
		echo -e "\nHost identity: ${SGMINER_HOSTS[w]}" >> log"$w".txt
		echo -e "\nDetected miner: ${VERSION_CHECK[w]}" >> log"$w".txt
		echo -e "Algorithm: $ALGORITHM" >> log"$w".txt
		echo -e "Rig uptime: $UPTIME_HOURS hours" >> log"$W".txt
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
