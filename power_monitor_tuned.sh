#!/bin/bash

BAT=$(echo /sys/class/power_supply/BAT*)
BAT_STATUS="$BAT/status"
BAT_CAP="$BAT/capacity"
LOW_BAT_PERCENT=20

AC_PROFILE="throughput-performance"
BAT_PROFILE="balanced"
LOW_BAT_PROFILE="powersave"
# tuned-adm list

# wait a while if needed
[[ -z $STARTUP_WAIT ]] || sleep "$STARTUP_WAIT"

# start the monitor loop
prev=0

while true; do
    # read the current state
    if [[ $(cat "$BAT_STATUS") == "Discharging" ]]; then
        if [[ $(cat "$BAT_CAP") -gt $LOW_BAT_PERCENT ]]; then
            profile=$BAT_PROFILE
        else
            profile=$LOW_BAT_PROFILE
        fi
    else
        profile=$AC_PROFILE
    fi  

    # set the new profile
    if [[ $prev != "$profile" ]]; then
        echo setting power profile to $profile
        # Fedora 41 uses tuned-adm, which is incompatible with power-profiles-daemon
        tuned-adm profile $profile # powerprofilesctl set $profile
        # Needed to update Gnome power-profiles dropdown window (tho it is slow)
        systemctl restart tuned
    fi  

    prev=$profile

    # wait for the next power change event
    inotifywait -qq "$BAT_STATUS" "$BAT_CAP"
done
