# SSH Grabber

Description:

This simple tool logs usernames and passwords from authentication attempts against an OpenSSH server you control. It demonstrates how easy it can be for an attacker to obtain credentials in cleartext after compromising a host that is running SSH and using password authentication instead of private keys. This can facilitate lateral movement within a network. It can also be very useful as part of a honeypot.

The script works by continuously monitoring the process list for child processes of sshd, attaching strace to those processes to capture strings going in and out, then parsing out the authentication credentials and logging them to a file. Props to Ventz for the idea: https://blog.vpetkov.net/2013/01/29/sniffing-ssh-password-from-the-server-side/ The beauty of this approach is that it doesn't require modifying sshd or installing any custom code on the system (as long as strace is installed).

Known limitations: root privileges are required to run the script. It will only log one connection at a time, so if multiple authentication sessions are open simultaneously, only the first one will be logged (multiple authentication attempts within the same session will be logged). Currently there is no built-in log rotation or de-duplication.

This tool was designed to demonstrate the simplicity of harvesting credentials from a live SSH server and to educate about host security. Using it for malicious purposes is against the author's intent and could lead to prosecution under various criminal statutes.

Required Package Dependencies:

- sshd
- strace

Usage: sudo ./ssh-grabber.sh
