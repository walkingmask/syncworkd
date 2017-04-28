#!/usr/bin/env bash
set -eu

# Synchronize the Workspace Daemon

# The list of cloud drives
CLOUD_DRIVES=$(cat <<EO_CLOUD_DRIVES
EO_CLOUD_DRIVES
)

# Path to local workspace
WORKSPACE=WORKSPACE_

# Max file size (KB)
MAXSIZE=$((MAXSIZE_*1000)) # 500MB

# Check existance of workspace
if [ ! -d $WORKSPACE ]; then
  errorlog="[`date`] syncwork: Error. There is no $WORKSPACE." >>$errorlogfile
  exit 1
fi

# Error log
errorlogfile="$HOME/Desktop/syncwork_error`date +%Y%m%d%H%M`.log"

# File size filter
for size in `du -k $WORKSPACE/* | cut -f 1`; do
  if [ $size -ge $MAXSIZE ]; then
    echo "[`date`] syncworkd: Filtered the large object $MAXSIZE, limited size is $MAXSIZE." >>$errorlogfile
  fi
done

# Synchronize to Cloud

_IFS=$IFS
IFS=$'\n'

if [ "$CLOUD_DRIVES" = "" ]; then
  echo "[`date`] syncworkd: Error. There is no cloud drives." >>$errorlogfile
  exit 1
fi

for CLOUD_DRIVE in $CLOUD_DRIVES; do
  if [ -d $CLOUD_DRIVE ]; then
    CLOUD_WORKSPACE=$CLOUD_DRIVE/Workspace
    if [ ! -d $CLOUD_WORKSPACE ]; then
      mkdir $CLOUD_WORKSPACE
    fi
    if [ "`diff -qr $WORKSPACE $CLOUD_WORKSPACE`" != "" ]; then
      rsync -a --delete $WORKSPACE/ $CLOUD_WORKSPACE
    fi
  else
    echo "[`date`] syncworkd: Error. There is no $CLOUD_DRIVE." >>$errorlogfile
  fi
done

IFS=$_IFS
exit 0
