#!/usr/bin/ksh93
#------------------------------------------------------------------------------------
# Script:  scroobanizer.sh
# Created: 2014/11/12
# Author:  David Little - david.n.little@gmail.com
#  (C) 2015 by David Little The MIT License (MIT)
#------------------------------------------------------------------------------------
typeset -r VERSION="1.0.2"
typeset -r LICENSE="The MIT License (MIT)"
typeset -r SCRIPT="$(basename $0 .sh)"
typeset -r AUTHOR="David Little"
#------------------------------------------------------------------------------------
# Purpose:
#  Display information about where packets are headed on your AIX LPAR
#	
# Use:
# usage: # Details in <script> --man
#   <script> [ options ]
#     -f file, --file                  use custom file location, defaults /tmp/
#     -b, --busy-only                  show only busy processes, defaults off
#     -s time, --sleep time    		   length of time to sleep, defaults 10
#
# Comments:
#	Pretty much everything in here is my own work. Feel free to steal any of the code or modify as you want.
#   Usual disclaimers apply, use at your own risk.
#   Please send all bug reports or requests to david.n.little@gmail.com
#
# Features to Add:
#	Check MTU and make sure that packets size is accounted for when calculating traffic
#	
#------------------------------------------------------------------------------------

#=Fancy Fonts====================================================================================

MAKE_FONT_ARRAYS()
{
	#====================================================================================
	typeset -A FONT=( 
		[UNDERLINE]="\033[4m" 
		[NORMAL]="\033[0m"
		[BOLD]="\033[37;1m"
		[BLACK_F]="\033[0;30m"
		[RED_F]="\033[0;31m"
		[GREEN_F]="\033[0;32m"
		[BROWN_F]="\033[0;33m"
		[BLUE_F]="\033[0;34m"
		[PURPLE_F]="\033[0;35m"
		[CYAN_F]="\033[0;36m"
		[LIGHTGRAY_F]="\033[0;37m"
		[DARKGRAY_F]="\033[1;30m"
		[LIGHTRED_F]="\033[1;31m"
		[LIGHTGREEN_F]="\033[1;32m"
		[YELLOW_F]="\033[1;33m"
		[LIGHTBLUE_F]="\033[1;34m"
		[PINK_F]="\033[1;35m"
		[LIGHTCYAN_F]="\033[1;36m"
		[WHITE_F]="\033[1;37m"
		[BLACK_B]="\033[40m"
		[RED_B]="\033[41m"
		[GREEN_B]="\033[42m" 
		[YELLOW_B]="\033[43m"
		[BLUE_B]="\033[44m"
		[MAGENTA_B]="\033[45m"
		[CYAN_B]="\033[46m"
		[WHITE_B]="\033[47m"
	)

	typeset -A FONT_FB1=( 
		[0]="${FONT[WHITE_F]}${FONT[BLUE_B]}" [1]="${FONT[BLACK_F]}${FONT[GREEN_B]}" [2]="${FONT[WHITE_F]}${FONT[MAGENTA_B]}" 
		[3]="${FONT[WHITE_F]}${FONT[CYAN_B]}" [4]="${FONT[BLACK_F]}${FONT[YELLOW_B]}" [5]="${FONT[WHITE_F]}${FONT[RED_B]}" 
		[6]="${FONT[BLACK_F]}${FONT[WHITE_B]}" [7]="${FONT[WHITE_F]}${FONT[BLACK_B]}"
	)
	FONT_FB1_COUNT=8
	typeset -A FONT_FB2=( 
		[0]="${FONT[BLACK_F]}${FONT[CYAN_B]}" [1]="${FONT[BLACK_F]}${FONT[RED_B]}" [2]="${FONT[WHITE_F]}${FONT[YELLOW_B]}" 
		[3]="${FONT[WHITE_F]}${FONT[MAGENTA_B]}" [4]="${FONT[WHITE_F]}${FONT[BLUE_B]}" [5]="${FONT[MAGENTA_F]}${FONT[GREEN_B]}" 
		[6]="${FONT[BLACK_F]}${FONT[WHITE_B]}" [7]="${FONT[WHITE_F]}${FONT[BLACK_B]}"
	)
	FONT_FB2_COUNT=8
	#====================================================================================


	#====================================================================================
	# Set up the boxes!
	typeset -A BOX
	BOX["CLR"]=( # Lower right hand corner
		NORM=$(echo "\033(0j\033(B\033[0m}") #)) 
		BOLD=$(echo "${FONT[BOLD]}\033(0j\033(B\033[0m${FONT[NORMAL]}") #)) 
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0j\033(B\033[0m${FONT[NORMAL]}") #))
	)
	BOX["CUR"]=( # Upper right hand corner
		NORM=$(echo "\033(0k\033(B\033[0m") #))
		BOLD=$(echo "${FONT[BOLD]}\033(0k\033(B\033[0m${FONT[NORMAL]}") #)) 
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0k\033(B\033[0m${FONT[NORMAL]}") #))
	)
	BOX["CUL"]=( # Upper left hand corner
		NORM=$(echo "\033(0l\033(B\033[0m") #))
		BOLD=$(echo "${FONT[BOLD]}\033(0l\033(B\033[0m${FONT[NORMAL]}") #))
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0l\033(B\033[0m${FONT[NORMAL]}") #))
	)
	BOX["CLL"]=( # Lower left hand corner
		NORM=$(echo "\033(0m\033(B\033[0m") #)) 
		BOLD=$(echo "${FONT[BOLD]}\033(0m\033(B\033[0m${FONT[NORMAL]}") #)) 
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0m\033(B\033[0m${FONT[NORMAL]}") #)) 
	)
	BOX["CMX"]=( # Midpoint X
		NORM=$(echo "\033(0n\033(B\033[0m") #)) 
		BOLD=$(echo "${FONT[BOLD]}\033(0n\033(B\033[0m${FONT[NORMAL]}") #))
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0n\033(B\033[0m${FONT[NORMAL]}") #)) 
	)
	BOX["BHH"]=( # High bar
		NORM=$(echo "\033(0o\033(B\033[0m") #)) 
		BOLD=$(echo "${FONT[BOLD]}\033(0o\033(B\033[0m${FONT[NORMAL]}") #)) 
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0o\033(B\033[0m${FONT[NORMAL]}") #)) 
	)
	BOX["BHM"]=( # Middle-high bar
		NORM=$(echo "\033(0p\033(B\033[0m") #))
		BOLD=$(echo "${FONT[BOLD]}\033(0p\033(B\033[0m${FONT[NORMAL]}") #)) 
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0p\033(B\033[0m${FONT[NORMAL]}") #)) 
	)
	BOX["BMM"]=( # Midbar
		NORM=$(echo "\033(0q\033(B\033[0m") #))
		BOLD=$(echo "${FONT[BOLD]}\033(0q\033(B\033[0m${FONT[NORMAL]}") #))
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0q\033(B\033[0m${FONT[NORMAL]}") #)) 
	)
	BOX["BML"]=( # Mid-Low bar
		NORM=$(echo "\033(0r\033(B\033[0m") #))
		BOLD=$(echo "${FONT[BOLD]}\033(0r\033(B\033[0m${FONT[NORMAL]}") #))
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0r\033(B\033[0m${FONT[NORMAL]}") #)) 
	)
	BOX["BLL"]=( # Lowbar
		NORM=$(echo "\033(0s\033(B\033[0m") #)) 
		BOLD=$(echo "${FONT[BOLD]}\033(0s\033(B\033[0m${FONT[NORMAL]}") #)) 
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0s\033(B\033[0m${FONT[NORMAL]}") #)) 
	)
	BOX["CVR"]=(  # Corner Vertical Midpoint Right
		NORM=$(echo "\033(0t\033(B\033[0m") #))
		BOLD=$(echo "${FONT[BOLD]}\033(0t\033(B\033[0m${FONT[NORMAL]}") #)) 
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0t\033(B\033[0m${FONT[NORMAL]}") #)) 
	)
	BOX["CVL"]=( # Corner Vertical Midpoint Left
		NORM=$(echo "\033(0u\033(B\033[0m") #)) 
		BOLD=$(echo "${FONT[BOLD]}\033(0u\033(B\033[0m${FONT[NORMAL]}") #)) 
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0u\033(B\033[0m${FONT[NORMAL]}") #)) 
	)
	BOX["CHU"]=( # Corner Horizontal Midpoint Up
		NORM=$(echo "\033(0v\033(B\033[0m") #)) 
		BOLD=$(echo "${FONT[BOLD]}\033(0v\033(B\033[0m${FONT[NORMAL]}") #))
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0v\033(B\033[0m${FONT[NORMAL]}") #))
	)
	BOX["CHD"]=(  # Corner Horizontal Midpoint Down
		NORM=$(echo "\033(0w\033(B\033[0m") #))
		BOLD=$(echo "${FONT[BOLD]}\033(0w\033(B\033[0m${FONT[NORMAL]}") #)) 
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0w\033(B\033[0m${FONT[NORMAL]}") #))
	)
	BOX["BVV"]=( # Vertical Bar
		NORM=$(echo "\033(0x\033(B\033[0m") #)) 
		BOLD=$(echo "${FONT[BOLD]}\033(0x\033(B\033[0m${FONT[NORMAL]}") #))
		DULL=$(echo "${FONT[DARKGRAY_F]}\033(0x\033(B\033[0m${FONT[NORMAL]}") #))
	)
}
#------------------------------------------------------------------------------------

#=Cleanup====================================================================================
# We set up traps to ensure that the trace is correctly stopped
trap 'CLEANUP SIGINT;exit' SIGINT
trap 'CLEANUP; exit' SIGQUIT
CLEANUP()
{
	################################
	(
		printf "${BOX[CVR].BOLD}" 
		printf " %${PAGEWIDTH}s "
		printf "${BOX[CVL].BOLD}"
		printf "\n"
	)|sed "s/ /${BOX[BMM].BOLD}/g"
	################################
	if [[ "$1" == SIGINT ]]; then
		printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "Entered Cleanup with SIGINT"
	fi
	IPTRACESTATUS=$(lssrc -s iptrace|awk '/iptrace/{print $3}')
	if [[ "${IPTRACESTATUS}" != inoperative ]]; then
		printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "Stopping IPTrace"
		stopsrc -s iptrace|while read LINE; do
			printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "${LINE}"
		done
	fi
	if [[ -w "${TRACEFILE}" && -e "${TRACEFILE}" ]]; then
		printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "Removing ${TRACEFILE}"
		rm "${TRACEFILE}"
	fi
	################################
	(
		printf "${BOX[CLL].BOLD}" 
		printf " %${PAGEWIDTH}s "
		printf "${BOX[CLR].BOLD}"
		printf "\n"
	)|sed "s/ /${BOX[BMM].BOLD}/g"
	################################
	[[ "$1" == SIGINT ]] && exit 1
	exit 0
}
#------------------------------------------------------------------------------------

#=Globals====================================================================================
typeset -i PAGEWIDTH="108"
typeset -r SCRIPTNAME=$(basename $0)
typeset TRACEFILE=/tmp/trace.${SCRIPTNAME}.$(date +%Y%m%d-%H%M%S).out
typeset MYIP=$(ifconfig -a|awk '/inet / {print $2;exit}')
typeset -i SLEEP=10
typeset -i BUSYTHRESHOLD=20
# We'll actually dynamically change the 'busy' threshold later by looking at the average/median percentage used of all of our processes, we can get a better idea of whats busy and what is 'normal'
#   Hopefully we'll find the top 5% as 'busy'
typeset -i BUSYONLY=0
#------------------------------------------------------------------------------------




#=Usage====================================================================================
USAGE="[+NAME?${SCRIPTNAME} --- Show AIX LPAR Network Traffic Information]"
USAGE+="[+DESCRIPTION? This script will show the network activity of an LPAR .]"
USAGE+="[-author?David Little <david.n.little@gmail.com>]"
USAGE+="[-copyright?Free to use and modify - Use at own risk.]"
USAGE+="[-license?${LICENSE}]"

USAGE+="[b:busy-only?Display only busy IP addresses. Disabled by default.]"
USAGE+="[t:trace?Location to store tcpdump file]:[TRACEFILE:=${TRACEFILE}]"
USAGE+="[o:output?Location to redirect the report itself.]:[OUTPUTFILE:=${OUTPUTFILE}]"
USAGE+="[s:sleep?Length in seconds to measure network traffic.]#[SLEEP:=${SLEEP}]"
USAGE+=$'\n\n'
while getopts "$USAGE" optchar ; do
    case $optchar in
		b)  BUSYONLY=1 ;;
		f)  TRACEFILE=$OPTARG ;;
		s)  SLEEP=$OPTARG ;;
    esac
done
shift "$((OPTIND - 1))"
#------------------------------------------------------------------------------------

# At the start of this script is the function MAKE_FONT_ARRAYS, which will handle fancy fonts and the like.
MAKE_FONT_ARRAYS 

#=Sanity====================================================================================

if (( $(df -m $(dirname /${TRACEFILE})|awk '/^\// {print $3}') < 100 )); then
	# Free space is less than 100 in targeted system, this is not enough for very busy systems.
	echo "There must be at least 100MB free space in the target filesystem."
	exit 2
fi

which startsrc >/dev/null 2>&1
status=$?
if (( status == 1 )); then
	echo "Unable to find required command, 'startsrc'.  Are you sure you have the correct privileges?"
	exit 2
fi
#------------------------------------------------------------------------------------


################################
(
	printf "${BOX[CUL].BOLD}" 
	printf " %${PAGEWIDTH}s "
	printf "${BOX[CUR].BOLD}"
	printf "\n"
)|sed "s/ /${BOX[BMM].BOLD}/g"
################################
printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "${SCRIPT}: v${VERSION}: By ${AUTHOR} on ${UPDATED} ${LICENSE}"
printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "Starting Trace, outputting to ${TRACEFILE}"
startsrc -s iptrace -a "${TRACEFILE}"|while read LINE; do
	printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "${LINE}"
done
printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n"  "Sleeping for ${SLEEP} seconds"
sleep ${SLEEP}
printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n"  "Stopping Trace"
stopsrc -s iptrace|while read LINE; do
	printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "${LINE}"
done
################################
(
	printf "${BOX[CVR].BOLD}" 
	printf " %${PAGEWIDTH}s "
	printf "${BOX[CVL].BOLD}"
	printf "\n"
)|sed "s/ /${BOX[BMM].BOLD}/g"
################################
printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "Generating IP Report and gathering information"
typeset -A ARRAY_INCOMINGTRAFFIC
typeset -A ARRAY_OUTGOINGTRAFFIC
typeset -A BUSYIP
IPLIST=""
typeset -i COUNTINCOMING=0
typeset -i COUNTOUTGOING=0
typeset -i DISCARD=0

#========================================================================================================================
# The report comes through looking something like this, without the # # obviously:
#
# #====( 130 bytes received on interface en0 )==== 12:12:33.397003947
# #ETHERNET packet : [ b4:14:89:de:14:41 -> fa:09:6a:20:34:0a ]  type 800  (IP)
# #IP header breakdown:
# #        < SRC =    10.192.16.78 >
# #        < DST =   10.196.30.184 >
# #        ip_v=4, ip_hl=20, ip_tos=0, ip_len=116, ip_id=28382, ip_off=0 DF
# #        ip_ttl=125, ip_sum=4a1c, ip_p = 6 (TCP)
# #TCP header breakdown:
# #        <source port=49878, destination port=22(ssh) >
# #        th_seq=4291273262, th_ack=570980773
# #        th_off=5, flags<PUSH | ACK>
# #        th_win=512, th_sum=3ff7, th_urp=0
# #00000000     3387f1bb 1a998af0 fbaa6891 08f92fc8     |3.........h.../.|
# #00000010     fd541674 cd2fc4f9 243aa9e6 45340bc4     |.T.t./..$:..E4..|
#~~~~~~~~~~~~~~~~~~~~~
#  
# The information we want to keep is SRC IP, DST IP, source port, destination port, and the ip_xxx values.
# This regex will grab the information we want unformatted: '(< (SRC|DST) =|<source port|ip_[a-z]*=)':
# #        < SRC =    10.192.16.78 >
# #        < DST =   10.196.30.184 >
# #        ip_v=4, ip_hl=20, ip_tos=0, ip_len=116, ip_id=28382, ip_off=0 DF
# #        ip_ttl=125, ip_sum=4a1c, ip_p = 6 (TCP)
# #        <source port=49878, destination port=22(ssh) >
# Using awk, we can then format each line in order:
#	awk '{  printf $4" ";getline;
#			printf $4" ";getline;
#			printf
#

ipreport -N ${TRACEFILE} | egrep '(< (SRC|DST) =|<source port)|ip_[a-b]+='|egrep -v "${MYIP}|127.0.0.1|::1"|awk '{printf $2" "$4;getline;printf " "$2" "$4"\n"}'|sed 's/,//g;s/(.*)//;s/port=//g'|while read -A LINE; do
	SRCDST=${LINE[0]}
	IP=${LINE[1]}
	SRCPRT=${LINE[2]}
	DSTPRT=${LINE[3]}
	if [[ "${IP//[0-9]/}" != "..." ]]; then
		((DISCARD+=1))
	elif [[ "${SRCPRT}" == "" || "${SRCPRT//[0-9]/}" != "" ]]; then
		((DISCARD+=1))
	elif [[ "${DSTPRT}" == "" || "${DSTPRT//[0-9]/}" != "" ]]; then
		((DISCARD+=1))
	else
		if [[ "${SRCDST}" == DST ]]; then
			# Outgoing Packet
			# OUTGOING LOCALPORT REMOTEIP REMOTEPORT
			echo "OUTGOING ${SRCPRT} ${IP} ${DSTPRT}"
		elif [[ "${SRCDST}" == SRC ]]; then
			# Incoming Packet
			# INCOMING LOCALPORT REMOTEIP REMOTEPORT
			echo "INCOMING ${DSTPRT} ${IP} ${SRCPRT}"
		else
			#Discard the output
			((DISCARD+=1))
		fi
	fi
done|sort|uniq -c| while read -A LINE; do
	COUNT=${LINE[0]}
	DIRECTION=${LINE[1]}
	if [[ "${DIRECTION}" == INCOMING ]]; then
		ARRAY_INCOMINGTRAFFIC[${LINE[1]},${LINE[2]},${LINE[3]},${LINE[4]}]=${COUNT}
		((COUNTINCOMING+=COUNT))
	elif [[ "${DIRECTION}" == OUTGOING ]]; then
		ARRAY_OUTGOINGTRAFFIC[${LINE[1]},${LINE[2]},${LINE[3]},${LINE[4]}]=${COUNT}
		((COUNTOUTGOING+=COUNT))
	else
		# Impossible
		echo "Impossible condition. Exiting."
		CLEANUP 2
	fi
done
################################
printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n"  "Report completed."
printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n"  "Sample Length (seconds): ${SLEEP}"
printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n"  "Total Packets In: $COUNTINCOMING"
printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n"  "Total Packets Out: $COUNTOUTGOING"
printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n"  "Discarded Results: ${DISCARD}"
(( "${BUSYONLY}" == 1 )) && printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n"  "Displaying only busy processes."
################################
(
	printf "${BOX[CVR].BOLD}" 
	printf " %${PAGEWIDTH}s "
	printf "${BOX[CVL].BOLD}"
	printf "\n"
)|sed "s/ /${BOX[BMM].BOLD}/g"
################################

#Direction  :LPort        Remote IP:RPort     IN#     IN%    OUT#    OUT%
printf "${BOX[BVV].BOLD}"
printf " %-10s ${BOX[BVV].NORM}" "Direction"
printf " :%5s ${BOX[BVV].NORM}"  "LPort"
printf " %16s:%-5s ${BOX[BVV].NORM}"  "Remote IP" "RPort"
printf " %7s ${BOX[BVV].NORM}"  "IN#"
printf " %6s ${BOX[BVV].NORM}"  "IN%"
printf " %7s ${BOX[BVV].NORM}"  "OUT#"
printf " %6s ${BOX[BVV].NORM}"  'OUT%'
printf "%-10s%10s${BOX[BVV].NORM}" "> IN%" " %OUT <"
printf "%4s${BOX[BVV].BOLD}" ""
printf '\n'

typeset -i OUT_COUNT
typeset -i IN_COUNT
typeset DIRECTION

for INDEX in ${!ARRAY_OUTGOINGTRAFFIC[*]} ${!ARRAY_INCOMINGTRAFFIC[*]}; do
	# INCOMING LOCALPORT REMOTEIP:REMOTEPORT COUNT
	echo ${INDEX//,/ }|read -A TMPARR
	#DIRECTION=${TMPARR[0]}
	LOCALPORT=${TMPARR[1]}
	REMOTEIP=${TMPARR[2]}
	REMOTEPORT=${TMPARR[3]}
	OUT_COUNT="${ARRAY_OUTGOINGTRAFFIC[OUTGOING,${LOCALPORT},${REMOTEIP},${REMOTEPORT}]}"
	IN_COUNT="${ARRAY_INCOMINGTRAFFIC[INCOMING,${LOCALPORT},${REMOTEIP},${REMOTEPORT}]}"
	# Check the values of x_COUNT to see what direction the data was going
	# Unset DIRECTION, we can check this after the if statement to see if the data was BOTH and has been removed from the arrays
	unset ARRAY_OUTGOINGTRAFFIC[OUTGOING,${LOCALPORT},${REMOTEIP},${REMOTEPORT}]
	unset ARRAY_INCOMINGTRAFFIC[INCOMING,${LOCALPORT},${REMOTEIP},${REMOTEPORT}]
	if (( OUT_COUNT != 0 && IN_COUNT != 0 )); then
		DIRECTION=BOTH
	elif (( OUT_COUNT != 0 )); then
		DIRECTION=OUTGOING
		IN_COUNT="0"
	elif (( IN_COUNT != 0 )); then
		DIRECTION=INCOMING
		OUT_COUNT="0"
	else
		# This is likely an INCOMING request which was matched as a 'BOTH', the data for it was removed when it was foudn in both OUTGOING and INCOMING
		DIRECTION=""
	fi
	
	if [[ "${DIRECTION}" != "" ]]; then
		IN_COUNTPERC=$((${IN_COUNT}.0/${COUNTINCOMING}.0*100))
		OUT_COUNTPERC=$((${OUT_COUNT}.0/${COUNTOUTGOING}.0*100))
		if ((IN_COUNTPERC + OUT_COUNTPERC>BUSYTHRESHOLD)); then
			#Mark this one as Busy
			BUSYIP[${REMOTEIP}:${REMOTEPORT}]=${IN_COUNTPERC},${OUT_COUNTPERC}
			BUSY=1 # Set busy flag
		fi
		if (( BUSY==1 || BUSYONLY==0 )); then
			printf "${BOX[BVV].BOLD}"
			printf " %-10s ${BOX[BVV].NORM}"		"${DIRECTION}"
			printf " :%-5s ${BOX[BVV].NORM}"		"${LOCALPORT}"
			printf " %16s:%-5s ${BOX[BVV].NORM}"	"${REMOTEIP}" "${REMOTEPORT}"
			printf " %7i ${BOX[BVV].NORM}"			"${IN_COUNT}"
			printf " %6.2f ${BOX[BVV].NORM}" 		"${IN_COUNTPERC}"
			printf " %7i ${BOX[BVV].NORM}"			"${OUT_COUNT}"
			printf " %6.2f ${BOX[BVV].NORM}" 		"${OUT_COUNTPERC}"
			OUTBARLEN=$((OUT_COUNTPERC/10))
			INBARLEN=$((IN_COUNTPERC/10))
			OUTBAR=$(printf %${OUTBARLEN}s|sed 's/ /</g')
			INBAR=$(printf %${INBARLEN}s|sed 's/ />/g')
			printf "%-10s%10s${BOX[BVV].NORM}" "${INBAR}" "${OUTBAR}"
			printf "%4s${BOX[BVV].BOLD}" $( (( BUSY == 1 )) && echo "Busy" ) # (( BUSY ? "BUSY" : "" )) might work ?
			BUSY=0 # Unset busy flag
			printf '\n'
		fi
	fi
done
################################
(
	printf "${BOX[CVR].BOLD}" 
	printf " %${PAGEWIDTH}s "
	printf "${BOX[CVL].BOLD}"
	printf "\n"
)|sed "s/ /${BOX[BMM].BOLD}/g"
################################

if [[ "${!BUSYIP[*]}" != "" ]]; then
	printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "Busy IP Analysis"
	for IP in ${!BUSYIP[*]}; do
		(
			printf "${BOX[CVR].BOLD}" 
			printf " %${PAGEWIDTH}s "
			printf "${BOX[CVL].BOLD}"
			printf "\n"
		)|sed "s/ /${BOX[BMM].BOLD}/g"
		printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "  IP: ${IP}"
		typeset -F2 TRAFFICIN=${BUSYIP[${IP}]%,*}
		typeset -F2 TRAFFICOUT=${BUSYIP[${IP}]#*,}
		printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "   Network Traffic In: ${TRAFFICIN}% Out: ${TRAFFICOUT}%"
		lsof -Pni @${IP} 2>/dev/null|egrep -v '^COMMAND'|while read -A LINE; do
			printf "${BOX[BVV].BOLD} %-${PAGEWIDTH}s ${BOX[BVV].BOLD}\n" "    Process Found:"
			printf "${BOX[BVV].BOLD} %12s: %-$((PAGEWIDTH-13))s${BOX[BVV].BOLD}\n" PID ${LINE[1]}
			printf "${BOX[BVV].BOLD} %12s: %-$((PAGEWIDTH-13))s${BOX[BVV].BOLD}\n" CMD ${LINE[0]}
			printf "${BOX[BVV].BOLD} %12s: %-$((PAGEWIDTH-13))s${BOX[BVV].BOLD}\n" USER ${LINE[2]}
			printf "${BOX[BVV].BOLD} %12s: %-$((PAGEWIDTH-13))s${BOX[BVV].BOLD}\n" NAME ${LINE[8]}
			BPSARGS="$(ps -efo pid,args|egrep "^ *${LINE[1]} "|sed 's/^ *[0-9]* //')"
			printf "${BOX[BVV].BOLD} %12s: %-$((PAGEWIDTH-13))s${BOX[BVV].BOLD}\n" ARGS "${BPSARGS}"
		done
	done
fi

CLEANUP

