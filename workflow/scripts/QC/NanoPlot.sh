#!/bin/bash
NumOfThreads=$1
File4FqList=$2
Dir4OutPut=$3

if [[ ! ${NumOfThreads} || ! ${File4FqList} || ! ${Dir4OutPut} ]];then
	echo "[ Warning ] Not enough arguments"
	exit
fi

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
		if [[ ${SoftName} == "nanoplot" ]];then
			Soft="~/softs/Python-3.7.7/bin/NanoPlot"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Nanoplot=$(SoftLocate nanoplot)


List4Fastq=`cat ${File4FqList} | sed ':a;N;s/\n/ /g;ba'`
${Bin4Nanoplot} -t ${NumOfThreads} --fastq ${List4Fastq} --plots kde --outdir ${Dir4OutPut}
