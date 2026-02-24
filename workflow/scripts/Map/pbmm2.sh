#!/bin/bash
SP=$1
NumOfThreads=$2
Input=$3
Output=$4
Genome=$5

if [[ ! ${SP} || ! ${NumOfThreads} || ! ${Input} || ! ${Output} || ! ${Genome} ]];then
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
		if [[ ${SoftName} == "pbmm2" ]];then
			Soft="~/softs/miniconda3/bin/pbmm2"
		elif [[ ${SoftName} == "samtools1" ]];then
			Soft="~/softs/samtools-1.14/bin/samtools"
		fi
	fi
	
	echo "${Soft}"
}
Bin4pbmm2=$(SoftLocate pbmm2)
Bin4Samtools=$(SoftLocate samtools1)


Dir=`dirname ${Output}`
if [[ ! -d ${Dir} ]];then
	mkdir -p ${Dir}
fi
cp ${Input} ${Dir}/FqList.fofn
${Bin4pbmm2} align \
	${Genome} ${Dir}/FqList.fofn ${Output} \
	-j ${NumOfThreads} --sort --preset CCS --sample ${SP} --rg "@RG\tID:${SP}" --log-level DEBUG
${Bin4Samtools} index ${Output}
