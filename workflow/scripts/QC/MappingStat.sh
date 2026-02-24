#!/bin/bash

Sample=$1
File4Summary=$2
File4Threshold=$3
File4Stat=$4

##################
# function
SoftYaml() {
	tDir=`dirname $0`
	File4Yaml=`ls ${tDir}/config/soft.yaml 2>/dev/null`
	MaxTry=5
	while [[ ! ${File4Yaml} ]]
	do
		tDir=`echo "${tDir}" | xargs dirname`
		File4Yaml=`ls ${tDir}/config/soft.yaml 2>/dev/null`
		
		MaxTry=$((${MaxTry} - 1))
		if [[ ${MaxTry} == 0 ]];then
			break
		fi
	done
	
	echo "${File4Yaml}"
}
SoftLocate() {
	local SoftName=$1
	
	Soft=""
	File4Yaml=$(SoftYaml)
	if [[ ${File4Yaml} ]];then
		#echo "[ Info ] Yaml for soft: ${File4Yaml}"
		Soft=`cat ${File4Yaml} | grep -v ^# | awk -F '\t' -v NName="${SoftName}" '{if($1 == NName){print $2;exit;}}'`
	else
		if [[ ${SoftName} == "python2" ]];then
			Soft="~/softs/Python-2.7.16/bin/python"
		elif [[ ${SoftName} == "csvtk" ]];then
			Soft="~/softs/cstvk-0.29.0/bin/csvtk"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Python=$(SoftLocate python2)
Bin4csvtk=$(SoftLocate csvtk)


Dir4SH=$(dirname $0)
${Bin4Python} ${Dir4SH}/MappingStat.py ${Sample} ${File4Summary} ${File4Threshold} ${File4Stat} ${Bin4csvtk}
