set -x
scriptDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}
module load petsc
module load dakota

OPENSEES_BIN='/home1/00477/tg457427/bin/OpenSees'

# just grab the filename if they dropped in the entire agave url (works if they didn't as well)
#TCLSCRIPT=$(basename ${inputScript})
echo "inputScript is ${inputScript}"
INPUTSCRIPT='${inputScript}'
echo "INPUTSCRIPT is $INPUTSCRIPT"
TCLSCRIPT="${INPUTSCRIPT##*/}"

echo "TCLSCRIPT is $TCLSCRIPT"

echo "inputDirectory is ${inputDirectory}"

# Run the script with the runtime values passed in from the job request

#
# input parameters
#

dirNAME=${inputDirectory}
scriptNAME=${inputFile}

#
# default parameters
#

paramNAME=$dirNAME/dakota.json
SIMCENTER_DIR=".SimCenter"
TOOL_DIR="EE_UQ"
COUNTER_FILE="counter.txt"

count=0

#scriptDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

cd ${inputDirectory}
OUT=`dakota -input dakota.in -output dakota.out -error dakota.err`

# copy dakota.out up to word Kurtosis
cp dakota.out dakota.tmp
sed -i '1,/Kurtosis/d' dakota.tmp


cd ..

if [ ! $? ]; then
        echo "dakota exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi

cd ${inputDirectory}
cp dakota.out $dirNAME/
cp dakota.tmp $dirNAME/
cp dakotaTab.out $dirNAME/
