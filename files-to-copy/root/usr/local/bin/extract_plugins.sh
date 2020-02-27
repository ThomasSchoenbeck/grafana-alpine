#!/bin/sh

export LOGDATE=$(date +"[%F %H:%M:%S]")

FILES=/tmp/grafana/plugins/*
for f in $FILES
do
  echo "$LOGDATE: Processing $f file..."
  # take action on each file. $f store current file name
 
  DIRECTORY=`unzip -qql $f | head -n1 | tr -s ' ' | cut -d' ' -f5-`
 
  echo "$LOGDATE: dir: $DIRECTORY"
 
  if [ ! -d "/var/lib/grafana/plugins/$DIRECTORY" ]; then
    echo "$LOGDATE: /var/lib/grafana/plugins/$DIRECTORY not found"
    echo "$LOGDATE: directory $f does not exist. extracting plugin archive"
    unzip -q $f -d /var/lib/grafana/plugins
    # Control will enter here if $DIRECTORY doesn't exist.
  else
    echo "$LOGDATE: plugin directory does exist. Doing nothing."
  fi
done

echo "$LOGDATE: check content of /tmp"
ls -la /tmp

echo "$LOGDATE: clean /tmp"

rm -rf /tmp/*

ls -la /tmp