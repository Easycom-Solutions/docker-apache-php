#!/bin/bash

trap 'echo "Reload signal (SIGHUP) received, processes are reloading"; service apache2 reload; service php5-fpm reload' SIGHUP HUP
trap 'echo "Ctrl-C pressed, processes are stopping"; service apache2 stop; service php5-fpm stop; exit 0' SIGINT INT
trap 'echo "Stop signal (SIGTERM) received, processes are stopping"; service apache2 stop; service php5-fpm stop; exit 0' SIGTERM TERM
trap 'echo "Ctrl-\\ pressed, processes are stopping"; service apache2 stop; service php5-fpm stop; exit 0' SIGQUIT QUIT

while :
do
    read -t 300
done

exit 1
