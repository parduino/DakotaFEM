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

if [[ $platform == 'Darwin' ]]; then
    export DAKOTA_PATH=$HOME/dakota/bin
    export OPENSEES_PATH=$HOME/bin
    export PATH=$PATH:$OPENSEES_PATH:$DAKOTA_PATH    
    source $HOME/.profile
elif [[ $platform == 'Linux' ]]; then
    export DAKOTA_PATH=$HOME/dakota/dakota-6.5/bin
    export LD_LIBRARY_PATH=$HOME/dakota/dakota-6.5/lib
    export OPENSEES_PATH=$HOME/bin
    export PATH=$PATH:$OPENSEES_PATH:$DAKOTA_PATH
    source $HOME/.bashrc

else
    echo "PLATFORM NOT RECOGNIZED"
fi




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
# default parameters
#

paramNAME=$dirNAME/dakota.json
SIMCENTER_DIR=".SimCenter"
TOOL_DIR="EE_UQ"
COUNTER_FILE="counter.txt"

count=0

scriptDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
lastDirNAME=$(basename $dirNAME)
lastDirNAME=templatedir

#
# create a dir to place all data associated with the app
#  - this dir will contain a counter file and a dir foreach run
#

mkdir -p $HOME/$SIMCENTER_DIR/$TOOL_DIR

if [ -e $HOME/$SIMCENTER_DIR/$TOOL_DIR/$COUNTER_FILE ];
then
    echo "File Exists"
    count=`cat $HOME/$SIMCENTER_DIR/$TOOL_DIR/$COUNTER_FILE`
    ((count++))
    echo "$count" > $HOME/$SIMCENTER_DIR/$TOOL_DIR/$COUNTER_FILE
else
    echo "Counter File doesn't exist. Creating now"
    echo "0" > $HOME/$SIMCENTER_DIR/$TOOL_DIR/$COUNTER_FILE
    count=0
fi

echo "Created directory: $count"

#
# mkdir for current run
#

mkdir -p $HOME/$SIMCENTER_DIR/$TOOL_DIR/$count

#
# set up template directory, copy all files from current to template
#

mkdir -p $HOME/$SIMCENTER_DIR/$TOOL_DIR/$count/$lastDirNAME
cp -R $dirNAME/* $HOME/$SIMCENTER_DIR/$TOOL_DIR/$count/$lastDirNAME/
cp $paramNAME $HOME/$SIMCENTER_DIR/$TOOL_DIR/$count/
cp $scriptDIR/parseJson.py $HOME/$SIMCENTER_DIR/$TOOL_DIR/$count
cd $HOME/$SIMCENTER_DIR/$TOOL_DIR/$count

#
# parse json file, creating dakota input and other files
#  note: done in python
#

python parseJson.py dakota.json
mv params.template $HOME/$SIMCENTER_DIR/$TOOL_DIR/$count/$lastDirNAME
mv paramOUT.ops $HOME/$SIMCENTER_DIR/$TOOL_DIR/$count/$lastDirNAME/
chmod 'u+x' opensees_driver
cp opensees_driver $HOME/$SIMCENTER_DIR/$TOOL_DIR/$count/$lastDirNAME/
mv main.ops $HOME/$SIMCENTER_DIR/$TOOL_DIR/$count/$lastDirNAME/

#
# run dakota
#
dakota -input dakota.in -output dakota.out -error dakota.err

# copy dakota.out up to word Kurtosis
cp dakota.out dakota.tmp

if [[ $platform == 'Darwin' ]]; then
    sed -i '' '1,/Kurtosis/d' dakota.tmp
else
    sed -i '1,/Kurtosis/d' dakota.tmp
fi

cp dakota.out $dirNAME/
cp dakota.tmp $dirNAME/
cp dakotaTab.out $dirNAME/

exit
