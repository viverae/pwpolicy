#!/bin/sh

# to deploy pwpolicy to the currently logged in user, not all users or global 'cause that screws up other stuff

maxFailedLoginAttempts='5'
requiresAlpha='1'
requiresNumeric='1'
minChars='8'
usingHistory='4'
exemptAccount='admin'
pwpolicyDir='/Library/OneHealth/Partners/Library'

#get list of users who are logged in
currentLoggedInUsers=`w -h | grep console| sort -u -t' ' -k1,1|awk '{print $1}'`

currentLoggedInUsersCR="$currentLoggedInUsers
" #to add CR

#loop through each user who is logged in
printf %s "$currentLoggedInUsersCR" | while IFS=$'\n' read -r currentLoggedInUser
#for currentLoggedInUser in $currentLoggedInUsersCR
do

    echo "begining run on $currentLoggedInUser user"
    if [ "$currentLoggedInUser" == "root" ] ||  [ "$currentLoggedInUser" == "$exemptAccount" ] ||  [ "$currentLoggedInUser" == "daemon" ]; then
	exit 0
    fi

#create user storage dir if not exists
    if [[ ! -d $pwpolicyDir/passwordPolicyPerUser ]]; then
        mkdir -p $pwpolicyDir
	mkdir -p $pwpolicyDir/passwordPolicyPerUser
	echo "pwpolicyPerUser.sh will create one file per user so pwpolicy is set only once for each user" > $pwpolicyDir/passwordPolicyPerUser/readme.txt
	`pwpolicy -setglobalpolicy "usingHistory=$usingHistory"`
    fi

#run only once per user
    if [[ -f $pwpolicyDir/passwordPolicyPerUser/$currentLoggedInUser ]]; then
	echo "policy exists for $currentLoggedInUser"
    else
	echo "setting $currentLoggedInUser policy"
        `pwpolicy -u $currentLoggedInUser -setpolicy "maxFailedLoginAttempts=$maxFailedLoginAttempts requiresAlpha=$requiresAlpha requiresNumeric=$requiresNumeric minChars=$minChars usingHistory=$usingHistory"`
        `touch /Library/OneHealth/Partners/Library/passwordPolicyPerUser/$currentLoggedInUser`
    fi
done
