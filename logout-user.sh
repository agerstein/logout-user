#!/bin/sh
################
# Logout User script
# this script will:
# see how long the machine has been idle (at the console)
# if under XX minutes (time to log out
#	then sleep for YY min - time idle / half maybe?
# wakeup
#	still idle?
#		still under XX minutes?
#			yes: sleep again
#			no: force logout
# wakeup again
#	still idle?
#		repeat above
#	timeout passed?
#		log out user
#
# Adam Gerstein gersteina1@southernct.edu
# 2015-09-21
# initial build after lots of trial and error

# status codes used for functions
# 0 = time to log out
# fifteen = sleep for 15 min
# ten = sleep for 10 min
# five = sleep for 5 min
# two = sleep for 2 min
# one = sleep for 1 min
# warning = 1 min left, warn user
# almost = less than 60 seconds left
# logout = time to log out
# 404 = something got messed up

# Variables - edit as needed
timeOut="120"
#timeOut="1800"	# how long the machine should be idle in seconds
trackFile="/Library/acc/logout-user/status.txt"	# logging things, why not
scsulogo="/Library/acc/logout-user/header-logo_bw.png"
count="0"
date=`date`
#### Read in the parameters from the JSS as passed?
#./jamfhelper.sh  "/" "oitajg06748" "gersteina1" "title" "heading" "description" "/Users/gersteina1/Desktop/idlelogout/header-logo_bw.png" "OK" "Cancel"

#jamfHelper -windowType utility -icon $scsulogo -title "Logout warning" -heading "You will be logged out in $logoutTimeleft seconds" -description "this is a test" -countdown -timeout $logoutTimeleft -button1 "Cancel" -cancelButton1 -button2 "OK" -defaultButton2

#logoutTimeleft="8" # how many seconds to count down before we kick the user out


mountPoint=$1			# "/"
computerName=$2			# "hostname"
username=$3				# "username"
title="Logout Warning"	# "string" Sets the window's title
#$heading="You will be logged out in $timeLeft seconds"			# "string" Sets the heading of the window
description="To make sure others can use this computer, you will be logged off. Any unsaved work will be lost."		# "string" Sets main contents of window 
icon=$scsulogo			# path Sets windows image filed to image located at specified path
button1="Cancel"		# "string" Creates button with label (default button)
button2="OK"			# "string" Creates button with label

#### Preconfigured Settings
dButton="1"				# Sets default button to button1. Responds to "return"
windowType="utility"	# [hud | utility | fs]

# Check to see how long it's idle for: (returns time in seconds)
function how_long_idle	# check idleTime
{
	idleTime=$(expr $(ioreg -c IOHIDSystem | awk '/HIDIdleTime/{ rec=$NF } END{ print rec }') / 1000000000)

#	idleTime="34"
#	idleTimer -i
#	idleTime= $idleTimer + 1200
#	echo idleTimer: $idleTimer
	#	idleTime=$(((expr $(ioreg -c IOHIDSystem | awk '/HIDIdleTime/{ rec=$NF } END{ print rec }') / 1000000000) + 1200)
	
	if [ $idleTime -lt $timeOut ] # idle less than 30 minutes
		then
			timeLeft=$((timeOut - $idleTime))
			echo "Time Idle: $idleTime" >> $trackFile
			echo "Time Left: $timeLeft" >> $trackFile
			#do the math - how much time is a good amount to sleep?
			if [ $timeLeft -gt 900 ] ; then	#1800 - XXX > 900? sleep 15 min
				status=(fifteen)
			elif [ $timeLeft -gt 600 ] ; then	#1800 - XXX > 600? sleep 10 min
				status=(ten)
			elif [ $timeLeft -gt 300 ] ; then	#1800 - XXX > 300? sleep 5 min
				status=(five)
			elif [ $timeLeft -gt 120 ] ; then	#1800 - XXX > 120? sleep 2 min
				status=(two)
			elif [ $timeLeft -gt 70 ] ; then	#1800 - XXX > 120? sleep 2 min
				status=(one)
			elif [ $timeLeft -gt 61 ] ; then	#1800 - XXX > 60? sleep 1 min
				status=(one)
			elif [ $timeLeft -ge 60 ] ; then	#1800 - XXX = at 60 seconds, warn user
				status=(warning)
			elif [ $timeLeft -gt 30 ] ; then	#1800 - XXX = more than 30 seconds left
				status=(almost)
			elif [ $timeLeft -ge 6 ] ; then	#1800 - XXX > 6? final countdown
				status=(countdown)
			elif [ $timeLeft -ge 1 ] ; then		#1800 - XXX > 1? logout time!
				status=(logout)
			else
				status="404"
				echo "need something to do - no exit code" >> $trackFile
			fi
		else
			#rm $trackFile
#			say "b" # do something else - maybe log out?
			echo "nothing else to do, so exit" >> $trackFile
			exit
	fi
}


function status_check
{
	echo "evaluating" >> $trackFile
	# ==== while loop start
		while [ $status == "fifteen" ]
		do
			echo "	Sleep for 15 minutes" >> $trackFile
			sleep 900	# seconds
			how_long_idle
		done

		while [ $status == "ten" ]
		do
			echo "	Sleep for 10 minutes" >> $trackFile
			sleep 600	# seconds
			how_long_idle
		done

		while [ $status == "five" ]
		do
			echo "	Sleep for 5 minutes" >> $trackFile
			sleep 300	# seconds
			how_long_idle
		done

		while [ $status == "two" ]
		do
			echo "	Sleep for 2 minutes" >> $trackFile
			sleep 120	# seconds
			how_long_idle
		done

		while [ $status == "one" ]
		do
			echo "	Sleep for 1 minutes" >> $trackFile
			sleep 60	# seconds
			how_long_idle
		done

		while [ $status == "warning" ]
		do
			echo "	Sleep for 15 seconds" >> $trackFile
			echo "	Status: $status" >> $trackFile
			display_warning		# uses a JSS tool to display a dialog warning the user about logout
			sleep 15	# seconds
			how_long_idle
		done

		while [ $status == "almost" ]
		do
			echo "	Sleep for 5 seconds" >> $trackFile
			echo "	Status: $status" >> $trackFile
			sleep 5	# seconds
			how_long_idle
		done

		while [ $status == "countdown" ]
		do
			echo "	Sleep for 1 seconds" >> $trackFile
			echo "	Status: $status" >> $trackFile
			sleep 1	# seconds
			how_long_idle
		done

		while [ $status == "logout" ]
		do
			echo "	Time to force logout" >> $trackFile
			echo "	do logout" >> $trackFile
#			force_logout_test
			force_logout_now
			exit
		done

	echo "status: $status" >> $trackFile
}


# display warning countdown
function display_warning	# uses jamfHelper.app to display a warning to the user that logout is coming
{
	/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType "$windowType" -windowPosition "$windowPosition" -title "$title" -heading "You will be logged out in $timeLeft seconds" -description "$description" -icon "$icon" -button1 "$button1" -button2 "$button2" -defaultButton "$dButton" -windowType "$windowType" -countdown -timeout $timeLeft &
	#-startlaunchd
}

function force_logout_now
{
	# one way
	#osascript -e 'tell application "System Events" to keystroke "q" using {command down, shift down, option down}'

	# another way
#	osascript -e 'tell application "loginwindow" to  «event aevtrlgo»'
		osascript -e 'ignoring application responses' -e 'tell application "loginwindow" to «event aevtrlgo»' -e end
	echo "hi" >> $trackFile
#	shutdown -r now
}

function force_logout_test
{
	echo "Timeout reached, forcing user logout....." >> $trackFile
}

# Execute the various functions as needed 
echo $date >> $trackFile
echo "Program start" >> $trackFile
echo "=======================" >> $trackFile
echo "how-long-idle:" >> $trackFile
how_long_idle		# checks to see how long we've been idle
echo "Status: $status" >> $trackFile
echo "status-check:" >> $trackFile
status_check		# checks status - go to sleep or logout?
echo "Status: $status" >> $trackFile
echo "Program end" >> $trackFile
#display_warning
#display_warning	# displays the logout warning
#force_logout_now	# forces user logout if all has gone correctly




### OLD, UNNEEDED (?) STUFF BELOW

function status_check_old
{
	echo Status: $status
	if [ $status = "fifteen" ] ; then
		echo "sleep for 15 min"
		sleep 90
		how_long_idle
	elif [ $status = "ten" ] ; then
		echo "sleep for 10 min"
		sleep 60
	elif [ $status = "five" ] ; then
		echo "sleep for 5 min"
		sleep 30
	elif [ $status = "two" ] ; then
		echo "sleep for 2 min"
		sleep 12
	elif [ $status = "one" ] ; then
		echo "sleep for 1 min"
		sleep 6
	elif [ $status = "logout" ] ; then
		echo "time to logout"
	else
		echo "need something else to do - no exit code"
	fi
}

