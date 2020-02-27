#!/bin/sh

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
LGREEN='\033[1;32m'
LRED='\033[1;31m'
NC='\033[0m' # No Color
 
export LOGDATE=$(date +"[%F %H:%M:%S]")

# Start extracting plugins process
/usr/local/bin/extract_plugins.sh
status=$?
pid=$!

if [ $status -ne 0 ]; then
  printf "$LOGDATE: ERROR: Failed to start ${YELLOW}extract_plugin.sh${NC}: ${RED}exit $status\n"
  exit $status
else
  printf "$LOGDATE:  INFO: ${YELLOW}extract_plugin.sh${NC} started with ${LRED}PID $pid\n"
fi



# Start cadvisor process
/usr/local/bin/cadvisor -logtostderr --port=${CADVISOR_PORT:-9090} &
status=$?
pid=$!

if [ $status -ne 0 ]; then
  printf "$LOGDATE: ERROR: Failed to start ${YELLOW}cadvisor process${NC}: ${RED}exit $status\n"
  exit $status
else
  printf "$LOGDATE:  INFO: ${YELLOW}cadvisor process${NC} started with ${LRED}PID $pid\n"
fi




# Start the second process
/opt/grafana/bin/grafana-server --config=/etc/grafana/grafana.ini --homepath /opt/grafana &
status=$?
pid=$!

if [ $status -ne 0 ]; then
  printf "$LOGDATE: ERROR: Failed to start ${YELLOW}grafana${NC}: ${RED}exit $status\n"
  exit $status
else
  printf "$LOGDATE:  INFO: ${YELLOW}grafana${NC} started with ${LRED}PID $pid\n"
fi

# Naive check runs checks once a minute to see if either of the processes exited.
# This illustrates part of the heavy lifting you need to do if you want to run
# more than one service in a container. The container exits with an error
# if it detects that either of the processes has exited.
# Otherwise it loops forever, waking up every 60 seconds

while sleep 60; do
  ps aux |grep cadvisor |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep grafana |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    printf "$LOGDATE: ERROR: One of the processes has stopped.\n"
    printf "$LOGDATE:  INFO: cadvisor: $PROCESS_1_STATUS\n"
    printf "$LOGDATE:  INFO:  grafana: $PROCESS_2_STATUS\n"
    exit 1
  fi
done