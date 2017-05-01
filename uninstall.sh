#!/usr/bin/env bash
set -eu

# Uninstall syncworkd

echo -n "Are you sure you want to uninstall? [y/n]: "
read ANSWER

if [ ! "$ANSWER" = "y" ]; then
  "Uninstallation was canceled."
  exit 1
fi

if launchctl list | grep syncworkd >/dev/null 2>&1; then
  launchctl stop syncworkd
  launchctl unload $HOME/Library/LaunchAgents/syncworkd.plist
fi

SCRIPT_PATH=`sed -ne '/syncwork.sh/p' $HOME/Library/LaunchAgents/syncworkd.plist`
SCRIPT_PATH=`echo $SCRIPT_PATH | sed -e "s/\t*<string>\(.*\)<\/string>/\1/g"`

rm $SCRIPT_PATH

if [ -f $HOME/Library/LaunchAgents/syncworkd.plist ]; then
  rm $HOME/Library/LaunchAgents/syncworkd.plist
fi

echo "Uninstallation done."
echo "If you want, you will need to clean up the Workspace and the Cloud Drives."
