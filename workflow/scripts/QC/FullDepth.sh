#!/bin/bash
Bam=$1
Bed=$2
File4Depth=$3
NumOfThreads=$4

if [[ ! ${Bam} || ! ${Bed} || ! ${File4Depth} || ! ${NumOfThreads} ]];then
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
		if [[ ${SoftName} == "samtools1" ]];then
			Soft="~/softs/samtools-1.14/bin/samtools"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Samtools=$(SoftLocate samtools1)


${Bin4Samtools} depth -a -b ${Bed} -q 7 -Q 20 --threads ${NumOfThreads} ${Bam} | gzip -c > ${File4Depth}
