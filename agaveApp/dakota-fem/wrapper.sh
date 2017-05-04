set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}

# Run the script with the runtime values passed in from the job request
PREFIX="/corral-repl/tacc/NHERI/shared/"
AGAVEPREFIX='agave://designsafe.storage.default/'

echo "arg0 is $0"
echo "inputScript is ${inputScript}"

INPUTSCRIPT='${inputScript}'
echo "INPUTSCRIPT is $INPUTSCRIPT"
TCLSCRIPT="${INPUTSCRIPT##*/}"

echo "TCLSCRIPT is $TCLSCRIPT"
INPUTDIRECTORY='${inputDirectory}'
echo "INPUTDIR is $INPUTDIRECTORY"
DIRNAME="${INPUTDIRECTORY##*/}"

#DIRNAME=${INPUTDIRECTORY#${AGAVEPREFIX}}
#FULLPATH=$PREFIX$DIRNAME


workDIR=$(pwd)/SimCenter
scriptDIR=$(pwd)/$INPUTDIRECTORY


#echo $(ls $(pwd))

module load petsc
module load dakota

#
# input parameters
#

scriptNAME=$TCLSCRIPT
dirNAME=$scriptDIR
TEMPLATEDIR=$workDIR/templatedir

paramNAME=$dirNAME/dakota.json
lastDirNAME=templatedir


#
# create a dir to place all data associated with the app
#  - this dir will contain a counter file and a dir foreach run
#


#
# set up template directory, copy all files from current to template
#

mkdir -p $TEMPLATEDIR
cp -R $scriptDIR/* $TEMPLATEDIR/

cp $paramNAME $workDIR
cp parseJson.py $workDIR

cd $workDIR

python parseJson.py dakota.json

#python -c "$pyScript" dakota.json


echo $(ls $workDIR)
echo $(ls $TEMPLATEDIR)

cp params.template $TEMPLATEDIR
cp paramOUT.ops $TEMPLATEDIR
chmod 'u+x' opensees_driver
cp opensees_driver $TEMPLATEDIR
cp main.ops $TEMPLATEDIR

#
# run dakota
#

cd $workDIR

echo $(ls)

OUT=`dakota -input dakota.in -output dakota.out -error dakota.err`

# copy dakota.out up to word Kurtosis
cp dakota.out dakota.tmp
sed -i '1,/Kurtosis/d' dakota.tmp

cp $workDIR/dakota.out $scriptDIR/dakota.out
cp $workDIR/dakota.tmp $scriptDIR/dakota.tmp
cp $workDIR/dakotaTab.out $scriptDIR/dakotaTab.out
cp $workDIR/dakota.err $scriptDIR/dakota.err

if [ ! $? ]; then
        echo "dakota exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi


