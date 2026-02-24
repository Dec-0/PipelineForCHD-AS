#!/bin/bash
NumOfThreads=$1
File4FqList=$2
Dir4OutPut=$3
Flag4Trim=$4

if [[ ! ${NumOfThreads} || ! ${File4FqList} || ! ${Dir4OutPut} || ! ${Flag4Trim} ]];then
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
		if [[ ${SoftName} == "env4fq" ]];then
			Soft="~/softs/miniconda3/envs/sci"
		fi
	fi
	
	echo "${Soft}"
}


File4FinalList="${Dir4OutPut}/FqList.txt"
if [[ ${Flag4Trim} == "Yes" ]];then
	echo "[ Info ] Begin fq trim."
	source activate $(SoftLocate env4fq)
	if [[ -s ${File4FinalList} ]];then
		rm ${File4FinalList}
	fi
	for fq in $(cat ${File4FqList})
	do
		BaseName=`basename ${fq}`
		zcat ${fq} | chopper --minlength 200 --headcrop 50 --tailcrop 30 -t ${NumOfThreads} | NanoFilt --length 200 --quality 7 | gzip -c > ${Dir4OutPut}/${BaseName}
		echo "${Dir4OutPut}/${BaseName}" >> ${File4FinalList}
	done
	conda deactivate
else
	echo "[ Info ] No manipulation for ${File4FqList}"
	cp ${File4FqList} ${File4FinalList}
fi
