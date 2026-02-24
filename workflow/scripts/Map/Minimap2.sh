#!/bin/bash
ODir=$1
NumOfThreads=$2
Input=$3
Output=$4
Genome=$5

if [[ ! ${ODir} || ! ${NumOfThreads} || ! ${Input} || ! ${Output} || ! ${Genome} ]];then
	echo "[ Warning ] Not enough arguments"
	exit
fi

if [[ ! -d ${ODir} ]];then
	mkdir -p ${ODir}
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
		if [[ ${SoftName} == "env4minimap" ]];then
			Soft="~/softs/miniconda3/envs/minimap"
		elif [[ ${SoftName} == "samtools1" ]];then
			Soft="~/softs/samtools-1.14/bin/samtools"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Samtools=$(SoftLocate samtools1)


date
FqInfo=`cat ${Input} | sed ':a;N;s/\n/ /g;ba'`
source activate $(SoftLocate env4minimap)
# the --MD and --cs tags are mutually exclusive, meaning that if you enable --MD, the cs tag will not be included in the output.
# --MD is an older format primarily used by samtools mpileup
#minimap2 -ax map-ont --cs --MD -k 10 -t ${NumOfThreads} ${Genome} ${FqInfo} | samtools sort -T ${ODir} -@ ${NumOfThreads} -m 2g -o ${Output} -
minimap2 -ax map-ont --cs -t ${NumOfThreads} ${Genome} ${FqInfo} | ${Bin4Samtools} sort -T ${ODir} -@ ${NumOfThreads} -m 2g -o ${Output} -
# samtools calmd -b ${Output} ${Genome} > ${Output}.AddMD.bam 2>${Output}.AddMD.log
conda deactivate
sleep 30
${Bin4Samtools} index ${Output}
rm -r ${ODir}
date
