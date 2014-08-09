#!/bin/sh

# This script looks at the age of a password and warns if older than $warnAge
# Once it gets older than $maxAge, a system preferences is opened automatically for the user to do the reset.
# It calculates this based on seconds
warnAge="15552000" # This is about 6 months
#warnAge="20000" #for testing
maxAge="18144000" #about 7 months
termNotifierPath='/Library/OneHealth/terminal-notifier.app/Contents/MacOS/terminal-notifier'
companyName='OneHealth'
exemptAccount='admin'
expirationTime='2592000' # Seconds past maxAge to expiration
sleep 5

currentUser=`whoami | xargs echo -n`   #remove newline char from currentUser

if [ "$currentUser" = "root" ] || [ "$currentUser" = "$exemptAccount" ]; then
  echo "This tool cannot run as root or your exempt user."
  exit 0
fi

OSVers=`sysctl -n kern.osrelease | cut -d . -f 1`
if [ $OSVers -eq 11 ]; then     # For os 10.7
  lastChangePW=`dscl . -read "/Users/$currentUser" PasswordPolicyOptions |grep passwordTimestamp -A1 |tail -1|awk -F T '{print $1}'|awk -F \> '{print $2}'`
elif [[ $OSVers -eq 12 || $OSVers -eq 13 ]]; then   # For os 10.8 - 10.9
  lastChangePW=`dscl . -read "/Users/$currentUser" PasswordPolicyOptions |grep passwordLastSetTime -A1 |tail -1|awk -F T '{print $1}'|awk -F \> '{print $2}'`
elif [ $OSVers -eq 14 ]; then   # For os 10.10
  lastChangePW=`dscl . -read "/Users/$currentUser" accountPolicyData |grep passwordLastSetTime -A1 |tail -1| cut -d '>' -f 2 | cut -d '<' -f 1 | cut -d . -f 1`
else
  echo "Unsupported OS Version"
  exit 1
fi

echo "Password last set on $lastChangePW"

DateNow=`date +%Y-%m-%d`
DateNowSecs=`date -j -f "%Y-%m-%d" $DateNow "+%s"`

userID=`id -u "$currentUser"`  #for local accounts only
if [ "$userID" -lt "500" ] || [ "$userID" -gt 1000 ] ;then
    echo "This tool is for local accounts only."
    exit 0
fi

# If Terminal Notifier is installed, then use it
if [ -f $termNotifierPath ]; then
    termNotifierExists="true"
fi

if [ -z "$lastChangePW" ];then
  echo "$currentUser has no lastChangePW date"
  /usr/bin/osascript <<-EOF3
            tell application "System Events"
            activate
            display dialog "$companyName Warning: The password for account $currentUser needs to be changed. You must change it immediately using System Preferences, 'Users & Groups' button." buttons "OK" default button 1 with icon 2
            end tell
            tell application "System Preferences"
              activate
              set the current pane to pane id "com.apple.preferences.users"
            end tell
EOF3
else
  if [ $OSVers -lt 14 ];then
    lastChangePWSeconds=`date -j -f "%Y-%m-%d" $lastChangePW "+%s"`
  elif [ $OSVers -eq 14 ]; then
    lastChangePWSeconds=$lastChangePW
  fi
    secondsSinceChanged=$(( $DateNowSecs - $lastChangePWSeconds))
    daysSinceChanged=$(( $secondsSinceChanged/60/60/24 ))
    lockoutDate=$(( $maxAge+$expirationTime ))
    daysTillLockout=$(( $lockoutDate/60/60/24 ))

    echo "$currentUser has a password that is $daysSinceChanged days old."
    if [ $secondsSinceChanged -gt $warnAge ] && [ $secondsSinceChanged -lt $maxAge ] ;then
      secsTillExpire=$(( $maxAge - secondsSinceChanged ))
      daysTillExpire=$(( $secsTillExpire/60/60/24 ))
      echo "WARNING: $currentUser HAS AN OLD PASSWORD of $daysSinceChanged Days."
      if [ "$termNotifierExists" != "true" ]; then
        /usr/bin/osascript <<-EOF
              tell application "System Events"
                activate
                set doTask to button returned of (display dialog "$companyName Warning: The password for account $currentUser will expire in $daysTillExpire days. Please change it immediately using System Preferences, 'Users & Groups' button." buttons {"Change Now","OK"} default button 2 with icon 2)
              end tell
              if doTask is "Change Now" then
                tell application "System Preferences"
                  activate
                  set the current pane to pane id "com.apple.preferences.users"
                  end tell
              end if
EOF
      else
        `"$termNotifierPath"  -title "$companyName Message" -activate "com.apple.systempreferences" -message "The password for this computer will expire in $daysTillExpire days. Please change it immediately."`
      fi
  elif [ $secondsSinceChanged -gt $maxAge ] ;then
    echo "WARNING: $currentUser HAS AN OLD PASSWORD. It's been $daysSinceChanged days since changed. You will be locked out in $daysTillLockout days."
    /usr/bin/osascript <<-EOF2
              tell application "System Events"
              activate
              display dialog "$companyName Warning: The password for account $currentUser is $daysSinceChanged days old and has expired. You must change it immediately using System Preferences, 'Users & Groups' button." buttons "OK" default button 1 with icon 2
              end tell
              tell application "System Preferences"
                      activate
                      set the current pane to pane id "com.apple.preferences.users"
                 end tell
EOF2
            /usr/bin/osascript <<-EOF4
              tell application "System Preferences"
                      activate
                      set the current pane to pane id "com.apple.preferences.users"
                 end tell
EOF4
  fi
fi

if [ $secondsSinceChanged -gt $lockoutDate ]; then
  pwpolicy setpolicy newPasswordRequired=1
fi
