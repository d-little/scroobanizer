#!/usr/bin/ksh93
#-------------------------------------------------------------------------------
# Script:  scroobanizer.sh
# Created: 2014/11/12
# Author:  David Little - david.n.little@gmail.com
#  (C) 2015 by David Little The MIT License (MIT)
#-------------------------------------------------------------------------------

typeset -r LICENSE="The MIT License (MIT)"
typeset -r SCRIPT=$(basename "$0" .sh)
typeset -r AUTHOR="David Little"
#-------------------------------------------------------------------------------
# Purpose:
#  Display information about where packets are headed on your AIX LPAR
#	
# Use:
# usage: # Details in <script> --man
#
# Comments:
#	Pretty much everything in here is my own work. Feel free to steal any of the
#    code or modify as you want.
#   Usual disclaimers apply, use at your own risk.
#   Please send all bug reports or requests to david.n.little@gmail.com
#
# Features to Add:
#	Check MTU and make sure that packets size is accounted for when calculating 
#   traffic
#	
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# This script uses https://github.com/koalaman/shellcheck for linting purposes.
# As it's ksh93, a few checks do not apply.  These are disabled throughout the
#  script.
#-------------------------------------------------------------------------------

#=Fancy Fonts===================================================================
MAKE_FONT_ARRAYS()
{
	#===========================================================================
    if [[ "${BOXES}" == "ENABLED" ]]; then
        typeset -A FONT=( 
            [UNDERLINE]='\033[4m'
            [NORMAL]='\033[0m'
            [BOLD]='\033[37;1m'
            [BLACK_F]='\033[0;30m'
            [RED_F]='\033[0;31m'
            [GREEN_F]='\033[0;32m'
            [BROWN_F]='\033[0;33m'
            [BLUE_F]='\033[0;34m'
            [PURPLE_F]='\033[0;35m'
            [CYAN_F]='\033[0;36m'
            [LIGHTGRAY_F]='\033[0;37m'
            [DARKGRAY_F]='\033[1;30m'
            [LIGHTRED_F]='\033[1;31m'
            [LIGHTGREEN_F]='\033[1;32m'
            [YELLOW_F]='\033[1;33m'
            [LIGHTBLUE_F]='\033[1;34m'
            [PINK_F]='\033[1;35m'
            [LIGHTCYAN_F]='\033[1;36m'
            [WHITE_F]='\033[1\;37m'
            [BLACK_B]='\033[40m'
            [RED_B]='\033[41m'
            [GREEN_B]='\033[42m'
            [YELLOW_B]='\033[43m'
            [BLUE_B]='\033[44m'
            [MAGENTA_B]='\033[45m'
            [CYAN_B]='\033[46m'
            [WHITE_B]='\033[47m'
        )
    fi

	# typeset -A FONT_FB1=( 
	# 	[0]="${FONT[WHITE_F]}${FONT[BLUE_B]}" [1]="${FONT[BLACK_F]}${FONT[GREEN_B]}" [2]="${FONT[WHITE_F]}${FONT[MAGENTA_B]}" 
	# 	[3]="${FONT[WHITE_F]}${FONT[CYAN_B]}" [4]="${FONT[BLACK_F]}${FONT[YELLOW_B]}" [5]="${FONT[WHITE_F]}${FONT[RED_B]}" 
	# 	[6]="${FONT[BLACK_F]}${FONT[WHITE_B]}" [7]="${FONT[WHITE_F]}${FONT[BLACK_B]}"
	# )
	# FONT_FB1_COUNT=8
	# typeset -A FONT_FB2=( 
	# 	[0]="${FONT[BLACK_F]}${FONT[CYAN_B]}" [1]="${FONT[BLACK_F]}${FONT[RED_B]}" [2]="${FONT[WHITE_F]}${FONT[YELLOW_B]}" 
	# 	[3]="${FONT[WHITE_F]}${FONT[MAGENTA_B]}" [4]="${FONT[WHITE_F]}${FONT[BLUE_B]}" [5]="${FONT[MAGENTA_F]}${FONT[GREEN_B]}" 
	# 	[6]="${FONT[BLACK_F]}${FONT[WHITE_B]}" [7]="${FONT[WHITE_F]}${FONT[BLACK_B]}"
	# )
	# FONT_FB2_COUNT=8
	#===========================================================================

	#===========================================================================
	# Set up the boxes!
	typeset -A BOX
    if [[ "${BOXES}" != "DISABLED" ]]; then
        # Lower right hand corner
        [[ "${BOXES}" == "SIMPLE" ]] && _box='+' || _box='\033(0j\033(B\033[0m'
        BOX["CLR"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Upper right hand corner
        [[ "${BOXES}" == "SIMPLE" ]] && _box='+' || _box='\033(0k\033(B\033[0m'
        BOX["CUR"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Upper left hand corner
        [[ "${BOXES}" == "SIMPLE" ]] && _box='+' || _box='\033(0l\033(B\033[0m'
        BOX["CUL"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Lower left hand corner
        [[ "${BOXES}" == "SIMPLE" ]] && _box='+' || _box='\033(0m\033(B\033[0m'
        BOX["CLL"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Midpoint X
        [[ "${BOXES}" == "SIMPLE" ]] && _box='+' || _box='\033(0n\033(B\033[0m'
        BOX["CMX"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # High bar
        [[ "${BOXES}" == "SIMPLE" ]] && _box='-' || _box='\033(0o\033(B\033[0m'
        BOX["BHH"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Middle-high bar
        [[ "${BOXES}" == "SIMPLE" ]] && _box='-' || _box='\033(0p\033(B\033[0m'
        BOX["BHM"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Midbar
        [[ "${BOXES}" == "SIMPLE" ]] && _box='-' || _box='\033(0q\033(B\033[0m'
        BOX["BMM"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Mid-Low bar
        [[ "${BOXES}" == "SIMPLE" ]] && _box='-' || _box='\033(0r\033(B\033[0m'
        BOX["BML"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Lowbar
        [[ "${BOXES}" == "SIMPLE" ]] && _box='-' || _box='\033(0s\033(B\033[0m'
        BOX["BLL"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Corner Vertical Midpoint Right
        [[ "${BOXES}" == "SIMPLE" ]] && _box='+' || _box='\033(0t\033(B\033[0m'
        BOX["CVR"]=(  
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Corner Vertical Midpoint Left
        [[ "${BOXES}" == "SIMPLE" ]] && _box='+' || _box='\033(0u\033(B\033[0m'
        BOX["CVL"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Corner Horizontal Midpoint Up
        [[ "${BOXES}" == "SIMPLE" ]] && _box='+' || _box='\033(0v\033(B\033[0m'
        BOX["CHU"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Corner Horizontal Midpoint Down
        [[ "${BOXES}" == "SIMPLE" ]] && _box='+' || _box='\033(0w\033(B\033[0m'
        BOX["CHD"]=(  
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )
        # Vertical Bar
        [[ "${BOXES}" == "SIMPLE" ]] && _box='|' || _box='\033(0x\033(B\033[0m'
        BOX["BVV"]=( 
            NORM="${_box}"
            BOLD="${FONT[BOLD]}${_box}${FONT[NORMAL]}"
            DULL="${FONT[DARKGRAY_F]}${_box}${FONT[NORMAL]}"
        )

        # shellcheck disable=SC2034  # We just need to iterate across a list of PAGEWITH length
        for x in $(seq -s ' ' 1 "$((PAGEWIDTH + 2 ))"); do
            printf "%s" "${BOX[BMM].BOLD}"
        done | read -r BAR_HR
    fi
}
#-------------------------------------------------------------------------------

#=Cleanup=======================================================================
# We set up traps to ensure that the trace is correctly stopped
trap 'CLEANUP SIGINT;exit' SIGINT
trap 'CLEANUP; exit' SIGQUIT
CLEANUP()
{
	################################
	MSG BOX_MIDDLE
	################################
	if [[ "$1" == SIGINT ]]; then
		MSG "Entered Cleanup with SIGINT"
	fi
	IPTRACESTATUS=$(lssrc -s iptrace|awk '/iptrace/{print $3}')
	if [[ "${IPTRACESTATUS}" != inoperative ]]; then
		MSG "Stopping IPTrace"
		stopsrc -s iptrace|while read -r LINE; do
			MSG "${LINE}"
		done
	fi
	if [[ -w "${TRACEFILE}" && -e "${TRACEFILE}" ]]; then
		MSG "Removing ${TRACEFILE}"
		rm "${TRACEFILE}"
	fi
	################################
	MSG BOX_BOTTOM
	################################
	[[ "$1" == SIGINT ]] && exit 1
	exit 0
}
#-------------------------------------------------------------------------------

#=MSG===========================================================================
MSG() {
	MESSAGE="$*"
    if [[ "${MESSAGE}" == BOX_TOP ]]; then
		MESSAGE="${BOX[CUL].BOLD}${BAR_HR}${BOX[CUR].BOLD}"
	elif [[ "${MESSAGE}" == BOX_MIDDLE ]]; then
		MESSAGE="${BOX[CVR].BOLD}${BAR_HR}${BOX[CVL].BOLD}"
	elif [[ "${MESSAGE}" == BOX_BOTTOM ]]; then
		MESSAGE="${BOX[CLL].BOLD}${BAR_HR}${BOX[CLR].BOLD}"
	else
        (
            printf "%s" "${BOX[BVV].BOLD}"
            printf " %-${PAGEWIDTH}s " "${MESSAGE}"
            printf "%s" "${BOX[BVV].BOLD}"
        ) | read -r MESSAGE
    fi

	if [[ "${OUTPUTFILE}" ]]; then
		echo "${MESSAGE}" >> "${OUTPUTFILE}"
	else
		echo "${MESSAGE}"
	fi
}
#-------------------------------------------------------------------------------

#=Globals=======================================================================
typeset -i PAGEWIDTH="108"
typeset -r SCRIPTNAME=$(basename "$0")
typeset TRACEFILE=/tmp/trace.${SCRIPTNAME}.$(date +%Y%m%d-%H%M%S).out
typeset MYIP=$(ifconfig -a|awk '/inet / {print $2;exit}')
typeset -i SLEEP=10
typeset -i BUSYTHRESHOLD=20
# Default to use the pretty boxes.
typeset -u BOXES="ENABLED"
# We'll actually dynamically change the 'busy' threshold later by looking at the
#  average/median percentage used of all of our processes, we can get a better 
#  idea of whats busy and what is 'normal'.
# Hopefully we'll find the top 5% as 'busy'
typeset -i BUSYONLY=0
#-------------------------------------------------------------------------------

#=Usage=========================================================================
USAGE="[+NAME?${SCRIPTNAME} --- Show AIX LPAR Network Traffic Information]"
USAGE+="[+DESCRIPTION? This script will show the network activity of an LPAR.]"
USAGE+="[-author?David Little <david.n.little@gmail.com>]"
USAGE+="[-copyright?Free to use and modify - Use at own risk.]"
USAGE+="[-license?${LICENSE}]"

USAGE+="[b:busy-only?Display only busy IP addresses.]"
USAGE+="[B:no-boxes?Do not display 'box' grid in output.]"
USAGE+="[t:trace?Location to store tcpdump file]:[TRACEFILE:=${TRACEFILE}]"
USAGE+="[o:outputdir?Directory to redirect the report itself.]:[OUTPUTFILE:=${OUTPUTFILE}]"
USAGE+="[s:sleep?Length in seconds to measure network traffic.]#[SLEEP:=${SLEEP}]"
USAGE+="[S:simple-boxes?Use simple box ASCII.]"
USAGE+=$'\n\n'

while getopts "$USAGE" optchar ; do
    case $optchar in
		b)  BUSYONLY=1 ;;
		B)  BOXES="DISABLED" ;;
        S)  BOXES="SIMPLE" ;;
		f)  TRACEFILE=$OPTARG ;;
        o)  OUTPUTDIR=$OPTARG ;;
		s)  SLEEP=$OPTARG ;;
    esac
done
shift "$((OPTIND - 1))"
#-------------------------------------------------------------------------------

# At the start of this script is the function MAKE_FONT_ARRAYS, which will 
#  handle fancy fonts and the like.
MAKE_FONT_ARRAYS 

#=Sanity========================================================================
if [[ "${OUTPUTDIR}" != "" ]]; then
	if [[ ! -d "${OUTPUTDIR}" ]]; then
		echo "Output directory doesnt exist. (${OUTPUTDIR})"
        echo "See \`--man\` for more details."
        exit 2
	fi
	OUTPUTFILE="${OUTPUTDIR}/scroobanizer_$(date +%Y%m%d-%H%M%S).out"
else
	if (( $(tput cols) < 112 )); then
		# Column width needs to be at least 112
		MSG "There must be at least 112 columns in your terminal (Currently: $(tput cols)"
		exit 2
	fi
fi

_tmp_dirname=$(dirname /"${TRACEFILE}")
_tmp_df=$(df -m "${_tmp_dirname}"|awk '/^\// {print $3}')
if (( _tmp_df < 100 )); then
	# Free space is less than 100 in targeted system, this is not enough for
	#  very busy systems.
	MSG "There must be at least 100MB free space in the target filesystem."
	exit 2
fi

which startsrc >/dev/null 2>&1
status=$?
if (( status == 1 )); then
	MSG "Unable to find required command, 'startsrc'.  Are you sure you have the correct privileges?"
	exit 2
fi
#-------------------------------------------------------------------------------



################################
MSG BOX_TOP
################################
MSG "${SCRIPT}: v${VERSION}: By ${AUTHOR} on ${UPDATED} ${LICENSE}"
MSG "Starting Trace, outputting to ${TRACEFILE}"
startsrc -s iptrace -a "${TRACEFILE}"|while read -r LINE; do
	MSG "${LINE}"
done
MSG  "Sleeping for ${SLEEP} seconds"
sleep "${SLEEP}"
MSG  "Stopping Trace"
stopsrc -s iptrace|while read -r LINE; do
	MSG "${LINE}"
done
################################
MSG BOX_MIDDLE
################################
MSG "Generating IP Report and gathering information"
typeset -A ARRAY_INCOMINGTRAFFIC
typeset -A ARRAY_OUTGOINGTRAFFIC
typeset -A BUSYIP
typeset -i COUNTINCOMING=0
typeset -i COUNTOUTGOING=0
typeset -i DISCARD=0

#===============================================================================
# The report comes through looking something like this
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

ipreport -N "${TRACEFILE}" | grep -E '(< (SRC|DST) =|<source port)|ip_[a-b]+='|grep -E -v "${MYIP}|127.0.0.1|::1"|awk '{printf $2" "$4;getline;printf " "$2" "$4"\n"}'|sed 's/,//g;s/(.*)//;s/port=//g'|while read -r -A LINE; do
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
done|sort|uniq -c| while read -r -A LINE; do
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
MSG "Report completed."
MSG "Sample Length (seconds): ${SLEEP}"
MSG "Total Packets In: $COUNTINCOMING"
MSG "Total Packets Out: $COUNTOUTGOING"
MSG "Discarded Results: ${DISCARD}"
(( "${BUSYONLY}" == 1 )) && MSG  "Displaying only busy processes."
################################
MSG BOX_MIDDLE
################################

#Direction  :LPort        Remote IP:RPort     IN#     IN%    OUT#    OUT%
{
    printf " %-10s ${BOX[BVV].NORM}" "Direction"
    printf " :%5s ${BOX[BVV].NORM}"  "LPort"
    printf " %15s:%-5s ${BOX[BVV].NORM}"  "Remote IP" "RPort"
    printf " %7s ${BOX[BVV].NORM}"  "IN#"
    printf " %6s ${BOX[BVV].NORM}"  "IN%"
    printf " %7s ${BOX[BVV].NORM}"  "OUT#"
    printf " %6s ${BOX[BVV].NORM}"  'OUT%'
    printf "%-10s%10s${BOX[BVV].NORM}" "> IN%" " %OUT <"
    printf "----"
}|read -r _msg
MSG "${_msg}"

typeset -i OUT_COUNT
typeset -i IN_COUNT
typeset DIRECTION

for INDEX in ${!ARRAY_OUTGOINGTRAFFIC[*]} ${!ARRAY_INCOMINGTRAFFIC[*]}; do
	# INCOMING LOCALPORT REMOTEIP:REMOTEPORT COUNT
	echo "${INDEX//,/ }"|read -r -A TMPARR
	#DIRECTION=${TMPARR[0]}
	LOCALPORT=${TMPARR[1]}
	REMOTEIP=${TMPARR[2]}
	REMOTEPORT=${TMPARR[3]}
	OUT_COUNT="${ARRAY_OUTGOINGTRAFFIC[OUTGOING,${LOCALPORT},${REMOTEIP},${REMOTEPORT}]}"
	IN_COUNT="${ARRAY_INCOMINGTRAFFIC[INCOMING,${LOCALPORT},${REMOTEIP},${REMOTEPORT}]}"
	# Check the values of x_COUNT to see what direction the data was going
	# Unset DIRECTION, we can check this after the if statement to see if the 
	#   data was BOTH and has been removed from the arrays
	unset ARRAY_OUTGOINGTRAFFIC[OUTGOING,"${LOCALPORT}","${REMOTEIP}","${REMOTEPORT}"]
	unset ARRAY_INCOMINGTRAFFIC[INCOMING,"${LOCALPORT}","${REMOTEIP}","${REMOTEPORT}"]
	if (( OUT_COUNT != 0 && IN_COUNT != 0 )); then
		DIRECTION=BOTH
	elif (( OUT_COUNT != 0 )); then
		DIRECTION=OUTGOING
		IN_COUNT="0"
	elif (( IN_COUNT != 0 )); then
		DIRECTION=INCOMING
		OUT_COUNT="0"
	else
		# This is likely an INCOMING request which was matched as a 'BOTH', 
		#  the data for it was removed when it was foudn in both OUTGOING 
		#  and INCOMING
		DIRECTION=""
	fi
	
	if [[ "${DIRECTION}" != "" ]]; then
		IN_COUNTPERC=$((${IN_COUNT}.0/${COUNTINCOMING}.0*100))
		OUT_COUNTPERC=$((${OUT_COUNT}.0/${COUNTOUTGOING}.0*100))
		if ((IN_COUNTPERC + OUT_COUNTPERC>BUSYTHRESHOLD)); then
			#Mark this one as Busy
			BUSYIP[${REMOTEIP}:${REMOTEPORT}]=${IN_COUNTPERC},${OUT_COUNTPERC}
			BUSY=1 # Set busy flag
		else
			BUSY=0
		fi
		if (( BUSY==1 || BUSYONLY==0 )); then
			{
                printf " %-10s ${BOX[BVV].NORM}"	  "${DIRECTION}"
                printf " :%-5s ${BOX[BVV].NORM}"	  "${LOCALPORT}"
                printf " %15s:%-5s ${BOX[BVV].NORM}"  "${REMOTEIP}" "${REMOTEPORT}"
                printf " %7i ${BOX[BVV].NORM}"		  "${IN_COUNT}"
                printf " %6.2f ${BOX[BVV].NORM}" 	  "${IN_COUNTPERC}"
                printf " %7i ${BOX[BVV].NORM}"		  "${OUT_COUNT}"
                printf " %6.2f ${BOX[BVV].NORM}" 	  "${OUT_COUNTPERC}"
                OUTBARLEN=$((OUT_COUNTPERC/10))
                INBARLEN=$((IN_COUNTPERC/10))
                OUTBAR=$(printf %${OUTBARLEN}s|sed 's/ /</g')
                INBAR=$(printf %${INBARLEN}s|sed 's/ />/g')
                printf "%-10s%10s${BOX[BVV].NORM}" "${INBAR}" "${OUTBAR}"
                if (( BUSY == 1 )); then
                    printf "Busy"
                else
                    printf "----"
                fi
                # printf "%4s" "$( (( BUSY == 1 )) && echo "Busy" || echo " " )" # (( BUSY ? "BUSY" : "" )) might work ?
            } | read -r _msg
            MSG "${_msg}"
		fi
	fi
done
################################
MSG BOX_MIDDLE
################################

if [[ "${!BUSYIP[*]}" != "" ]]; then
	MSG "Busy IP Analysis"
	for IP in ${!BUSYIP[*]}; do
        MSG BOX_MIDDLE
		MSG "  IP: ${IP}"
		typeset -F2 TRAFFICIN=${BUSYIP[${IP}]%,*}
		typeset -F2 TRAFFICOUT=${BUSYIP[${IP}]#*,}
		MSG "   Network Traffic In: ${TRAFFICIN}% Out: ${TRAFFICOUT}%"
		lsof -Pni @${IP} 2>/dev/null|grep -E -v '^COMMAND'|while read -r -A LINE; do
			MSG "    Process Found:"
            MSG "      PID ${LINE[1]}:"
			MSG "$(printf "%12s: %s" CMD "${LINE[0]}")"
			MSG "$(printf "%12s: %s" USER "${LINE[2]}")"
			MSG "$(printf "%12s: %s" NAME "${LINE[8]}")"
			BPSARGS="$(ps -efo pid,args|grep -E "^ *${LINE[1]} "|sed 's/^ *[0-9]* //')"
			MSG "$(printf "%12s: %s" ARGS "${BPSARGS}")"
		done
	done
fi

CLEANUP
