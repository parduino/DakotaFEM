#!/bin/bash          
#
# usage: wrapper dirName mainScript.tcl 
#   dirName: directory containing the mainScript
#   mainScript: the main input file to run
#
# written: fmk

# need to ensure OpenSees and dakota can be called

#
# os specific setup
#

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

#
# other parameters
#

lastDIR=$(basename $dirNAME)

#
# agave cli commands
#

# refresh token in case not fresh
auth-tokens-refresh -S -v

# upload directory
files-upload -F $dirNAME /tg457427/

# create submit description
python submitDakota.py $lastDIR $scriptNAME

#
# submit job & check every 5 seconds till done
#   maybe should update with upper walltime in case never going to finish
#

jobText=$(jobs-submit -F submitDakotaFEM.json)
jobID=$(echo $jobText | awk '{printf $NF}')
finishedTEXT="$jobID FINISHED"

jList=$(jobs-list $jobID)
echo $jList
while [[ $jList != *$finishedTEXT* ]]; do
    jList=$(jobs-list $jobID)
    echo $jList;
    sleep 5; 
done
echo $jList

#
# get results files
#

jobs-output --download --path $lastDIR/dakota.out $jobID
jobs-output --download --path $lastDIR/dakotaTab.out $jobID
jobs-output --download --path $lastDIR/dakota.tmp $jobID

mv dakota.out $dirNAME/
mv dakotaTab.out $dirNAME/
mv dakota.tmp $dirNAME/

#
# delete the job
#

jobs-delete $jobID