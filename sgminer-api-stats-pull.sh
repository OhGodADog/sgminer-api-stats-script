#!/bin/bash

## Remove old log files, keeps folder clean when using the script with "watch"
rm -rf log*.txt

## Miner API port and Nmap targeted network
PORT=4028
LOCAL_NETWORK="192.168.0.0/24"

## Check for host file or check local network

if [[ -s hosts.txt ]];
then
	echo "Host file found, loading hosts..."
	IFS=$'\n' SGMINER_HOSTS=($(cat hosts.txt))
else
	echo "No host file found, using nmap to find all hosts in the network"
	nmap -V

	if [[ $? -ne 0 ]]
	then
		echo -e "Nmap is not installed, exiting."
		exit 1
	else
		SGMINER_HOSTS=($(nmap -p$PORT $LOCAL_NETWORK -oG - | grep $PORT/open | egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"))
	fi
fi


if [ ${#SGMINER_HOSTS[@]} -eq 0 ];
then
	echo "No hosts detected, are settings correct?"
	exit 1
fi

## Check host availability

p=0

AVAILABLE_HOSTS=()
UNAVAILABLE_HOSTS=()

while [[ $p -lt ${#SGMINER_HOSTS[@]} ]]
do
	nc -w 1 ${SGMINER_HOSTS[p]} $PORT

	if [[ $? -eq 0 ]]
	then
		AVAILABLE_HOSTS+=(${SGMINER_HOSTS[p]})
	else
		UNAVAILABLE_HOSTS+=(${SGMINER_HOSTS[p]})
	fi

	true $(( p++ ))
done

## Get each host miner and GPU information

GPU_COUNT=()
VERSION_CHECK=()

i=0

while [[ $i -lt ${#AVAILABLE_HOSTS[@]} ]]
do
	GPU_COUNT+=($(echo -n "gpucount" | nc ${AVAILABLE_HOSTS[i]} $PORT | grep -a -oP '(?<=Count=)\w+'))
	VERSION_CHECK+=($(echo -n "version" | nc ${AVAILABLE_HOSTS[i]} $PORT | grep -a -o "TeamRedMiner [0-9].[0-9].[0-9]\|sgminer" | sort --unique))
	true $(( i++ ))
done


if [[ ${#VERSION_CHECK[@]} -eq 0 ]];
then
	echo "Miner is not sgminer fork. Exiting."
	exit 1
fi

## Get miner uptime, chosen algorithm and GPU stats for each host

z=0

UPTIME_SECONDS=()
while [[ $z -lt ${#AVAILABLE_HOSTS[@]} ]]
do
	x=0
	while [[ $x -lt ${GPU_COUNT[z]} ]]
	do
		echo -n "gpu|$x" | nc ${AVAILABLE_HOSTS[z]} $PORT >> log"$z".txt
		true $(( x++ ))
		done

	UPTIME_SECONDS=$(echo -n "summary" | nc ${AVAILABLE_HOSTS[z]} $PORT | grep -o 'Elapsed=[0-9]*' | sed 's\Elapsed=\\g')
	ALGORITHM=$(echo -n "devdetails" | nc ${AVAILABLE_HOSTS[z]} $PORT | grep -o "Kernel=.*" | cut -f1 -d ",")

	true $(( z++ ))
done

UPTIME_HOURS=$(echo "scale=2; $UPTIME_SECONDS/3600" | bc -l)

## Write everything to a log file for each host and clean the output for readibility

w=0

while [[ $w -lt ${#AVAILABLE_HOSTS[@]} ]] | [[ $w -lt ${#VERSION_CHECK[@]} ]]
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
		echo -e "Rig uptime: $UPTIME_HOURS hours" >> log"$w".txt
	else
		if [[ ${#AVAILABLE_HOSTS[@]} -lt 2 ]]
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

if [[ ${#UNAVAILABLE_HOSTS[@]} -ne 0 ]]
then
	echo -e "\nThe following pre-defined hosts were unavailable: ${UNAVAILABLE_HOSTS[@]}"
fi
