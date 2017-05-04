#!/bin/bash

DIR=$( cd "$( dirname "$0" )" && pwd )

echo $DIR

# set test variables
export inputFile="Example.tcl"
export AGAVE_JOB_MEMORY_PER_NODE=1
export AGAVE_JOB_NAME=some-simple-test-job
#export AGAVE_JOB_CALLBACK_FAILURE=

# stage file to root as it would be during a run
cp $DIR/$inputFile $DIR/../

# call wrapper script as if the values had been injected by the API
sh -c ../wrapper.sh

# clean up after the run completes
rm $DIR/../$inputFile
rm $DIR/../*.out
rm $DIR/../workdir*

