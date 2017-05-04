set -x
WRAPPERDIR=$( cd "$( dirname "$0" )" && pwd )

${AGAVE_JOB_CALLBACK_RUNNING}

#
# inputs
#

INPUTSCRIPT='${inputScript}'
TCLSCRIPT="${INPUTSCRIPT##*/}"

INPUTDIRECTORY='${inputDirectory}'
DIRNAME="${INPUTDIRECTORY##*/}"

# from Peter (not used yet)
# Run the script with the runtime values passed in from the job request
# PREFIX="/corral-repl/tacc/NHERI/shared/"
# AGAVEPREFIX='agave://designsafe.storage.default/'
# DIRNAME=${INPUTDIRECTORY#${AGAVEPREFIX}}
# FULLPATH=$PREFIX$DIRNAME

#
# other parameters:
#   workdir is were dakota will work
#   scriptDIR is where original files are
#   TEMPLATEDIR is the dakota template for dakota
#

workDIR=$(pwd)/SimCenter
scriptDIR=$(pwd)/$INPUTDIRECTORY

scriptNAME=$TCLSCRIPT
dirNAME=$scriptDIR
TEMPLATEDIR=$workDIR/templatedir

paramNAME=$dirNAME/dakota.json
lastDirNAME=templatedir

#echo $(ls $(pwd))

#
# load some modules needed, Dakota and OpenSees
#

module load petsc
module load dakota

#
# create new directory in which dakota will work
# create template dir (this will create workdir if below it)
# & copy all data from script dir to template dir
#

mkdir -p $TEMPLATEDIR
cp -R $scriptDIR/* $TEMPLATEDIR/

#
# copy the parameter file and python scripyt to parse it to work
# and run the script in the parameter file
#

cp $paramNAME $workDIR
cp parseJson.py $workDIR
cd $workDIR
python parseJson.py dakota.json

# used if script needs to be in a string
# python -c "$pyScript" dakota.json

#echo $(ls $workDIR)
#echo $(ls $TEMPLATEDIR)

#
# move all files script created to the template dir except dakota.in file
#

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

#
# copy dakota.out & remove up to word Kurtosis
#   .tmp file is file application uses
# copy dakota output files to scriptDir as these only ones to be saved
#

cp dakota.out dakota.tmp
sed -i '1,/Kurtosis/d' dakota.tmp

cp $workDIR/dakota.out $scriptDIR/dakota.out
cp $workDIR/dakota.tmp $scriptDIR/dakota.tmp
cp $workDIR/dakotaTab.out $scriptDIR/dakotaTab.out
cp $workDIR/dakota.err $scriptDIR/dakota.err

#
# clean up
#

rm -fr $workDIR/

if [ ! $? ]; then
        echo "dakota exited with an error status. $?" >&2
        ${AGAVE_JOB_CALLBACK_FAILURE}
        exit
fi


