import json
from pprint import pprint

with open('dakota.json') as data_file:    
    data = json.load(data_file)

#with open('data.txt', 'w') as outfile:  
#    json.dump(data, outfile)
#print data["method"]

# 
# parse the data
#

mainInput = data["mainInput"];

numNormalUncertain = 0;
normalUncertainName=[];
normalUncertainMean =[];
normalUncertainStdDev =[];

for k in data["randomVariables"]:
    if (k["type"] == "normal "):
        normalUncertainName.append(k["name"])
        normalUncertainMean.append(k["mean"])
        normalUncertainStdDev.append(k["stdDev"])
        numNormalUncertain += 1


responseDescriptors =[]
numResponses = 0
for k in data["edp"]:
        responseDescriptors.append(k["name"])
        numResponses += 1

#
# Write the input file: dakota.in 
#

# write out the method data
f = open('dakota.in', 'w')

f.write("environment\n")
f.write("tabular_data\n")
f.write("tabular_data_file = \'dakotaTab.out\'\n\n")

f.write(data["method"])
f.write('\n\n\n')

# write out the variable data
f.write('variables,\n')
f.write('normal_uncertain = ' '{}'.format(numNormalUncertain))
f.write('\n')
f.write('means = ')
for i in xrange(numNormalUncertain):
    f.write('{}'.format(normalUncertainMean[i]))
    f.write(' ')
f.write('\n')

f.write('std_deviations = ')
for i in xrange(numNormalUncertain):
    f.write('{}'.format(normalUncertainStdDev[i]))
    f.write(' ')
f.write('\n')

f.write('descriptors = ')    
for i in xrange(numNormalUncertain):
    f.write('\'')
    f.write(normalUncertainName[i])
    f.write('\' ')
f.write('\n\n\n')

# write out the interface data
f.write('interface,\n')
f.write('system # asynch evaluation_concurrency = 4\n')
f.write('analysis_driver = \'opensees_driver\' \n')
f.write('parameters_file = \'params.in\' \n')
f.write('results_file = \'results.out\' \n')
f.write('work_directory directory_tag \n')
f.write('copy_files = \'templatedir/*\' \n')
f.write('named \'workdir\' file_save  directory_save \n')
f.write('aprepro \n')
f.write('\n')

# write out the responses
f.write('responses, \n')
f.write('response_functions = ' '{}'.format(numResponses))
f.write('\n')
f.write('response_descriptors = ')    
for i in xrange(numResponses):
    f.write('\'')
    f.write(responseDescriptors[i])
    f.write('\' ')
f.write('\n')
f.write('no_gradients\n')
f.write('no_hessians\n\n')
f.close()  # you can omit in most cases as the destructor will call it

#
# Write the OpenSees file for dprepo
#
print('params.in')

f = open('params.template', 'w')

f.write('pwd\n')

for i in xrange(numNormalUncertain):
    f.write('set ')
    f.write(normalUncertainName[i])
    f.write(' {')
    f.write(normalUncertainName[i])
    f.write('}\n')

f.close()


#
# Write the OpenSees file to create the output file, results.out
#

f = open('paramOUT.ops', 'w')

f.write('set outFile [open results.out w]\n')
for i in xrange(numResponses):
    f.write('puts $outFile $')
    f.write(responseDescriptors[i])
    f.write('\n')
f.write('close $outFile\n\n')
f.close()

#
# Write the OpenSees file to create the output file, results.out
#

f = open('main.ops', 'w')
f.write('source paramIN.ops \n')
f.write('source ')
f.write(mainInput)
f.write(' \n')
f.write('source paramOUT.ops \n')
f.close()

f = open('opensees_driver', 'w')
# Pre-processing
f.write('dprepro $1 params.template paramIN.ops\n')

# Run OpenSees
#f.write('rm -f *.com *.done *.dat *.log *.sta *.msg')
f.write('/home1/00477/tg457427/bin/OpenSees main.ops >> ops.out\n')
f.close()
