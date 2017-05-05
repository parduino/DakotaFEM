import sys

#
# inputs
#

dirName=sys.argv[1]
scriptName=sys.argv[2]

#
# variables
#

st = """{
  "name":"dakota-fem test-1493789600",
  "appId": "dakota-fem-2.5.0",
  "batchQueue": "normal",
  "executionSystem": "designsafe.community.exec.stampede",
  "maxRunTime": "01:00:00",
  "memoryPerNode": "1GB",
  "nodeCount": 1,
  "processorsPerNode": 1,
  "archive": true,
  "archiveSystem": "designsafe.storage.default",
  "archivePath": null,
  "inputs": {
    "inputDirectory": "agave://designsafe.storage.default/tg457427/DIRNAME"
  },
  "parameters": {
    "inputScript": "SCRIPTNAME"
  },
  "notifications": [
    {
      "url":"https://requestbin.agaveapi.co/10zyduo1?job_id=${JOB_ID}&status=${JOB_STATUS}",
      "event":"*",
      "persistent":true
    },
    {
      "url":"fmckenna@ce.berkeley.edu",
      "event":"FINISHED",
          "persistent":false
    },
    {
      "url":"fmckenna@ce.berkeley.edu",
      "event":"FAILED",
      "persistent":false
    }
  ]
}
"""

#
# replace defaults with input and write
#

st=st.replace("DIRNAME",dirName)
st=st.replace("SCRIPTNAME",scriptName)

f = open('submitDakotaFEM.json', 'w')
f.write(st)
f.close()
