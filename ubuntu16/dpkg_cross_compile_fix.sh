#!/bin/bash

cd /usr/bin
ls -lt1 x86_64-* | awk '{print $9}' | cut -c 7- | awk '{print "ln -s x86_64" $1 " i686" $1}' | source /dev/stdin