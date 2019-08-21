# sgminer-api-stats-script
A Shell script for pulling stats from the SGMiner API

In case you want to monitor your rigs, which are running a SGMiner miner variant, from a Linux machine with a simple shell script.

Requires package `nmap` if you do not know your rigs addresses on the LAN.

Usage:

`chmod +x sgminer-api-stats-pull.sh`

`watch -n30 ./sgminer-api-stats-pull.sh` or `./sgminer-api-stats-pull.sh`

By default, the script searches for either a `hosts.txt` file, or the IP range `192.168.0.0/24`. If your mining rigs are on a different network, simply open the script, and change on line 6 the `API_PORT` and on line 7 the IP range to your desired one, or edit the `hosts.txt`.

Note, the `hosts.txt` IP addresses, must be separated by newline. 

Different SGMiner forks may have different API implementation, and may not work as expected.

Supported miners so far are:

`TeamRedMiner`

`sgminer-gm`

Forks, based on the `sgminer-5.4`, with `API 4.0` support.


This script is intended for small networks.
There are better solutions, which employ better statistics tracking, logging, miner fork support and so on.
