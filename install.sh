#!/usr/bin/env bash
set -eu

# Interactive Installer

echo "Hi. This is interactive installer of syncworkd. Please answer the settings you need."

## CLOUD DRIVES

echo "Which Cloud Drive do you want to use? choose the numbers (e.g. 1,3)."
echo "  1. Google Drive"
echo "  2. Dropbox"
echo "  3. iCloud Drive"

echo -n "> "; while read CLOUD_DRIVES; do
  CLOUD_DRIVES=(`echo $CLOUD_DRIVES | tr -s ',' ' '`)
  NUM_CLOUD_DRIVES=${#CLOUD_DRIVES[*]} 
  if [ $NUM_CLOUD_DRIVES -lt 1 ] || [ $NUM_CLOUD_DRIVES -gt 3 ]; then
    echo "Oops, please specify the numbers 1 ~ 3, at least one of them (e.g. 2)."
    echo -n "> "
  else
    break
  fi
done

## WORKSPACE

echo "OK. Then, where is your workspace? like a \"~/Workspace\"."

echo -n "> "; while read WORKSPACE; do
  WORKSPACE=`eval echo $WORKSPACE`
  if [ "$WORKSPACE" = "" ] || [ ! -d $WORKSPACE ]; then
    echo "Oops, I could not find that place. Please specify it correctly."
    echo -n "> "
  else
    break
  fi
done

## MAXSIZE

echo "Nice. So, What the maximum file size do you want in MB? (e.g. 500)."

echo -n "> "; while read MAXSIZE; do
  if [ "$MAXSIZE" = "" ]; then
    echo "Oops, please specify correctly file size."
    echo -n "> "
  else
    break
  fi
done

## SCRIPT_PATH

echo "Good. Finally, where should I put the syncwork script file? (default is ~/)."

echo -n "> "; while read SCRIPT_PATH; do
  SCRIPT_PATH=${SCRIPT_PATH/\~/$HOME}
  if [ "$SCRIPT_PATH" = "" ] || [ ! -d $SCRIPT_PATH ]; then
    echo "Oops, I could not find that place. Please specify it correctly."
    echo -n "> "
  else
    break
  fi
done

## Confirmation

echo "Great. Here is your settings. If it is OK, type \"y\" to continue the installation."

echo "CLOUD DRIVES (1.Google Drive, 2.Dropbox, 3.iCloud Drive): $CLOUD_DRIVES"
echo "WORKSPACE: $WORKSPACE"
echo "MAXSIZE: $MAXSIZE"
echo "SCRIPT PATH: $SCRIPT_PATH"

echo -n "> "; while read ANSWER1; do
  if [ "$ANSWER1" = "y" ]; then
    break
  else
    echo "Do you want to cancel the installation or change the settings? [y/n]"
    echo -n "> "; read ANSWER2
    if [ "$ANSWER2" = "y" ]; then
      echo "OK. If you want to install, please run me from the beginning. Bye."
      exit 1
    else
      echo "Do you want to continue the installation? [y/n]"
      echo -n "> "
    fi
  fi
done

## Setup

echo "OK. Setup syncworkd."

if [ -f $SCRIPT_PATH/syncwork.sh ]; then
  rm $SCRIPT_PATH/syncwork.sh
fi
cp ./syncwork.sh $SCRIPT_PATH

IFS_=$IFS
IFS=$'\n'

for i in `seq $NUM_CLOUD_DRIVES`; do
  case "$CLOUD_DRIVES[i]" in
    "1" ) CLOUD_DRIVES[i]="Google Drive";;
    "2" ) CLOUD_DRIVES[i]="Dropbox";;
    "3" ) CLOUD_DRIVES[i]="iCloud Drive";;
  esac
done

for CLOUD_DRIVE in $CLOUD_DRIVES; do
  if [ ! -d "$HOME/CLOUD_DRIVE" ]; then
    echo "Umm..., sorry I can't find $HOME/CLOUD_DRIVE."
    echo "Please write the correct PATH to the script file directly."
    continue
  fi
  sed -i '' -e "8i $HOME/CLOUD_DRIVE" $SCRIPT_PATH/syncwork.sh
done

IFS=$IFS_

sed -i '' -e "s/WORKSPACE_/$WORKSPACE/" \
-e "s/MAXSIZE_/$MAXSIZE/" $SCRIPT_PATH/syncwork.sh

if [ -f $HOME/Library/LaunchAgents/syncworkd.plist ]; then
  rm $HOME/Library/LaunchAgents/syncworkd.plist
fi
cp ./syncworkd.plist $HOME/Library/LaunchAgents/

sed -i '' -e "s/PATHTO/SCRIPT_PATH/g" $HOME/Library/LaunchAgents/syncworkd.plist

if launchctl list | grep syncworkd >/dev/null 2>&1; then
  launchctl stop syncworkd
  launchctl unload $HOME/Library/LaunchAgents/syncworkd.plist
fi
launchctl load $HOME/Library/LaunchAgents/syncworkd.plist
launchctl start syncworkd

echo "Setup & installation done."
