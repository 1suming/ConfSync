#!/bin/sh

rm -f Log*

config_db_sync -h 192.168.100.154 -p 4800 -l 1 -s 1 -d
