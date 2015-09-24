#!/bin/sh
################

idleTime=$(expr $(ioreg -c IOHIDSystem | awk '/HIDIdleTime/{ rec=$NF } END{ print rec }') / 1000000000)

echo $idleTime
