#!/bin/sh
#written by Todd Houle
#modified for OneHealth by Taylor Price
#7May2014

#This script looks at the age of a password and warns if older than ~6 months
#It calculates this based on seconds
#warnage="6048000" #is about 70 days
warnage="15552000" # This is about 6 months
#warnage="20000" #for testing
maxage=18144000 #about 7 months

sleep 5

currentUser=`whoami | xargs echo -n`   #remove newline char from currentUser

if [ "$currentUser" = "root" ]; then
    echo "This tool cannot run as root.  Execute as admin or standard user."
    exit
fi

OSVers=`sysctl -n kern.osrelease | cut -d . -f 1`
if [ $OSVers -gt 11 ]; then   #for os 10.8+
    lastChangePW=`dscl . -read "/Users/$currentUser" PasswordPolicyOptions |grep passwordLastSetTime -A1 |tail -1|awk -F T '{print $1}'|awk -F \> '{print $2}'`
elif [ $OSVers -eq 11 ]; then     #for os 10.7
    lastChangePW=`dscl . -read "/Users/$currentUser" PasswordPolicyOptions |grep passwordTimestamp -A1 |tail -1|awk -F T '{print $1}'|awk -F \> '{print $2}'`
else
    echo "Unsupported OS Version"
    exit
fi

echo "Password last set on $lastChangePW"

#if Terminal Notifier is isntalled, then use it
if [ -f /Library/OneHealth/terminal-notifier.app/Contents/MacOS/terminal-notifier ] && [ $OSVers -gt 11 ]; then
    termNotifierExists="true"
    termNotifierPath="/Library/OneHealth/terminal-notifier.app/Contents/MacOS/terminal-notifier"
fi

DateNow=`date +%Y-%m-%d`
DateNowSecs=`date -j -f "%Y-%m-%d" $DateNow "+%s"`


userID=`id -u "$currentUser"`  #for local accounts only
if [ "$userID" -lt "500" ] || [ "$userID" -gt 1000 ] ;then
    echo "This tool is for local accounts only."
    exit
fi


if [ -z "$lastChangePW" ];then
    echo "$currentUser has no lastChangePW date"

# Carla wants hard notice if no PW change date
#    if [ "$termNotifierExists" != "true" ]; then
	/usr/bin/osascript <<-EOF3
           tell application "System Events"
           activate
           display dialog "OneHealth Warning: The password for account $currentUser needs to be changed. You must change it immediately using System Preferences, 'Users & Groups' button." buttons "OK" default button 1 with icon 2
           end tell
           tell application "System Preferences"
             activate
             set the current pane to pane id "com.apple.preferences.users"
           end tell
EOF3
#    else
#	`"$termNotifierPath" -title "OneHealth Healthcare Message" -activate "com.apple.systempreferences" -message "The password for your account needs to be changed immediately."`
#    fi
else
    lastChangePWSeconds=`date -j -f "%Y-%m-%d" $lastChangePW "+%s"`
    secondsSinceChanged=$(( $DateNowSecs - $lastChangePWSeconds))
    daysSinceChanged=$(( $secondsSinceChanged/60/60/24 ))
    echo "$currentUser has a password that is $daysSinceChanged days old."
    if [ $secondsSinceChanged -gt $warnage ] && [ $secondsSinceChanged -lt $maxage ] ;then
        secsTillExpire=$(( $maxage - secondsSinceChanged ))
	daysTillExpire=$(( $secsTillExpire/60/60/24 ))
	echo "WARNING: $currentUser HAS AN OLD PASSWORD of $daysSinceChanged Days."
	   if [ "$termNotifierExists" != "true" ]; then
	    /usr/bin/osascript <<-EOF
              tell application "System Events"
                 activate
                 set doTask to button returned of (display dialog "OneHealth Warning: The password for account $currentUser will expire in $daysTillExpire days. Please change it immediately using System Preferences, 'Users & Groups' button." buttons {"Change Now","OK"} default button 2 with icon 2)
              end tell
              if doTask is "Change Now" then
                 tell application "System Preferences"
                      activate
                     set the current pane to pane id "com.apple.preferences.users"
                 end tell
              end if
EOF
	else
	    `"$termNotifierPath"  -title "OneHealth Message" -activate "com.apple.systempreferences" -message "The password for this computer will expire in $daysTillExpire days. Please change it immediately."`
	fi
    elif [ $secondsSinceChanged -gt $maxage ] ;then
        echo "WARNING: $currentUser HAS AN OLD PASSWORD. It's been $daysSinceChanged days since changed."
# commenting out because Carla wants hard notice if password is over 88 days
#           if [ "$termNotifierExists" != "true" ]; then
	    /usr/bin/osascript <<-EOF2
              tell application "System Events"
              activate
              display dialog "OneHealth Warning: The password for account $currentUser is $daysSinceChanged days old and has expired. You must change it immediately using System Preferences, 'Users & Groups' button." buttons "OK" default button 1 with icon 2
              end tell
              tell application "System Preferences"
                      activate
                      set the current pane to pane id "com.apple.preferences.users"
                 end tell
EOF2
#	else
#	    `"$termNotifierPath"  -title "OneHealth Message" -activate "com.apple.systempreferences" -message "The password for account $currentUser is $daysSinceChanged days old and has expired."`
            /usr/bin/osascript <<-EOF4
              tell application "System Preferences"
                      activate
                      set the current pane to pane id "com.apple.preferences.users"
                 end tell
EOF4
#	fi
    fi
fi
