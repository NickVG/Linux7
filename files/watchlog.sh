#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
   logger "$DATE: I found word, Master!"
   echo "I found it. /n" >> /tmp/log.txt
else
   exit 0
fi
