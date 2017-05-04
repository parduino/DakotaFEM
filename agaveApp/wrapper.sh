#!/bin/bash          
#
# usage: wrapper dirName mainScript.tcl 
#   dirName: directory containing the mainScript
#   mainScript: the main input file to run
#
# written: fmk

# need to ensure OpenSees and dakota can be called

platform='unknown'

platform=$(uname)
     
#
# input parameters
#

dirNAME=$1
scriptNAME=$2


if [ "$#" -ne 2 ] || ! [ -d "$1" ]; then
  echo "Usage: $0 dirName scriptName" >&2
  exit 1
fi

paramNAME=$dirNAME/dakota.json

#
# agave cli commands
#

auth-tokens-refresh -S -v
files-upload -F $dirNAME /tg457427/
jobs-submit


exit
