#!/bin/bash

trap 'echo "Reload signal (SIGHUP) received, processes are reloading"; service apache2 reload; service php5-fpm reload' SIGHUP HUP
trap 'echo "Ctrl-C pressed, processes are stopping"; service apache2 stop; service php5-fpm stop; exit 0' SIGINT INT
trap 'echo "Stop signal (SIGTERM) received, processes are stopping"; service apache2 stop; service php5-fpm stop; exit 0' SIGTERM TERM
trap 'echo "Ctrl-\\ pressed, processes are stopping"; service apache2 stop; service php5-fpm stop; exit 0' SIGQUIT QUIT

while :
do
    # Read wait for interactions for 300 seconds
    read -t 300

    # In some case, read could never run so we need a sleep
    # We do not use it instead of read because it blocks entire shell script, so the traps too.
    sleep 1
done

exit 1
