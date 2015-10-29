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
