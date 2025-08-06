#!/bin/bash

cd /home/ringracers/

current_id() {
	CURRENT_ID=`id -u`
	echo $CURRENT_ID
}

start_server_unpriviledged() {
	if [ "$(current_id)" = "0" ]; then
		echo "changing to ringracers user - server_start"
		su ringracers -c '/home/ringracers/entrypoint.sh "serverstart"'
	else
		echo "already non root - server_start"
		exit
	fi
}

monitor_unpriviledged() {
	if [ "$(current_id)" = "0" ]; then
		echo "changing to ringracers user - monitor"
		su ringracers -c '/home/ringracers/entrypoint.sh "servermonitor"'
	else
		echo "already non root - monitor"
		exit
	fi
}

current_date() {
    echo "$(date "+%Y-%m-%d %H:%M:%S")"
}

start_server() {
    echo "--- Starting Server"
    tmux new-session -d -s rr
    tmux send-keys "$HOME/ringracers -dedicated -port $RR_PORT -advertise $ADVERTISE; exit" C-m
}

monitor() {
    tmux ls > /dev/null 2>&1
    if [ $? -eq 1]; then
        echo "$(current_date) - Server crashed ! - Restarting ..."
		start_server
    fi
}

check_mount_path() {
	PERMS=`stat -c "%u:%g" /home/ringracers/.ringracers`
	if [ "$PERMS" != "$CHOOSEN_UID:$CHOOSEN_GID" ]; then
		chown -R $CHOOSEN_UID:$CHOOSEN_GID /home/ringracers/.ringracers
		echo 'Info: changed permissions on mounted folder'
	fi
}

case $1 in 
    "servermonitor")
        monitor
        ;;
	"serverstart")
		current_date
		start_server
		;;
	"monitor")
		monitor_unpriviledged
		;;
    *)
	check_mount_path
    current_date
    start_server_unpriviledged
    sleep 5
    tail -f --retry /home/ringracers/.ringracers/latest-log.txt
    ;;
esac
