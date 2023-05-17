#!/bin/sh

cd /home/container || exit 1

printf "\033[1m\033[33mcontainer~ \033[0m%s\n" "$STARTUP"
eval ${STARTUP}
