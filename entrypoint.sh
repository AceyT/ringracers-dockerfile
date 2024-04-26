#!/bin/bash

cd /home/ringracers/

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

case $1 in 
    "monitor")
        monitor
        ;;
    *)
    current_date
    start_server
    sleep 5
    tail -f /home/ringracers/.ringracers/latest-log.txt
    ;;
esac
