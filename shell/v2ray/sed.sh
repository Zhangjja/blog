#!/bin/bash
key="API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA"
curl -H 'key="API-Key: R336LW2OYPBDWOAYEPYUKD6EX4ZS37RHFQBA"' https://api.vultr.com/v1/server/bandwidth?SUBID=$MONITOR_SUBID | python -m json.tool > log1
all_count=`cat log1 |wc -l`
half_count=`expr $all_count / 2`
log=`cat  log1 | grep -A $half_count "outgoing_bytes"  | sed -i '$d'`
