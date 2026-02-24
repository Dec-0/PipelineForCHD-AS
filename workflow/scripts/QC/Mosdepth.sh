#!/bin/bash

NumOfThreads=$1
Bed=$2
Prefix=$3
Input=$4

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
		if [[ ${SoftName} == "mosdepth" ]];then
			Soft="~/softs/mosdepth-v0.3.6/bin/mosdepth"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Mosdepth=$(SoftLocate mosdepth)


${Bin4Mosdepth} -t ${NumOfThreads} -b ${Bed} -T 1,5,10,15,20,25,30 -n ${Prefix} ${Input}
