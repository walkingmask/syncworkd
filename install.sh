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

## WORKSPACE_NAME

echo "OK&OK. Then, what is your workspace's name? like a \"Workspace\"."

echo -n "> "; while read WORKSPACE_NAME; do
  if [ "$WORKSPACE" = "" ]; then
    echo "Oops, Please specify at least one character."
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

echo "CLOUD DRIVES (1.Google Drive, 2.Dropbox, 3.iCloud Drive): ${CLOUD_DRIVES[*]}"
echo "WORKSPACE: $WORKSPACE"
echo "WORKSPACE_NAME: $WORKSPACE_NAME"
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

CLOUD_DRIVE_PATHS=()

function not_found() {
  echo "Umm..., sorry I can't find $HOME/$CLOUD_DRIVE."
  echo "Please write the correct PATH to the script file directly."
}

for i in `seq 0 1 $((NUM_CLOUD_DRIVES-1))`; do
  case "${CLOUD_DRIVES[i]}" in
    "1" )
      [ ! -d "$HOME/Google Drive" ] && not_found
      sed -i '' -e "s|#Google Drive|$HOME/Google Drive|" $SCRIPT_PATH/syncwork.sh
      ;;
    "2" )
      [ ! -d "$HOME/Dropbox" ] && not_found
      sed -i '' -e "s|#Dropbox|$HOME/Dropbox|" $SCRIPT_PATH/syncwork.sh
      ;;
    "3" )
      [ ! -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ] && not_found
      sed -i '' -e "s|#iCloud Drive|$HOME/Library/Mobile Documents/com~apple~CloudDocs|" $SCRIPT_PATH/syncwork.sh
      ;;
  esac
done

IFS=$IFS_

sed -i '' -e "s|WORKSPACE_$|$WORKSPACE|" \
-e "s|WORKSPACE_NAME_$|$WORKSPACE_NAME|" \
-e "s/MAXSIZE_/$MAXSIZE/" $SCRIPT_PATH/syncwork.sh

if [ -f $HOME/Library/LaunchAgents/syncworkd.plist ]; then
  rm $HOME/Library/LaunchAgents/syncworkd.plist
fi
cp ./syncworkd.plist $HOME/Library/LaunchAgents/

sed -i '' -e "s|PATHTO|$SCRIPT_PATH|g" $HOME/Library/LaunchAgents/syncworkd.plist

if launchctl list | grep syncworkd >/dev/null 2>&1; then
  launchctl stop syncworkd
  launchctl unload $HOME/Library/LaunchAgents/syncworkd.plist
fi
launchctl load $HOME/Library/LaunchAgents/syncworkd.plist
launchctl start syncworkd

echo "Setup & installation done."
