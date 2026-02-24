#!/bin/bash

# cuteSV
Bam=$1
Vcf=$2
NumOfThreads=$3
Genome=$4
SP=$5
Version=$6

if [[ ! ${Bam} || ! ${Vcf} || ! ${NumOfThreads} || ! ${Genome} || ! ${SP} ]];then
	echo "[ Warning ] Not enough argument"
	exit
else
	echo "[ Info ] cuteSV begin."
fi

Dir=`dirname ${Vcf}`
if [[ -d ${Dir} ]];then
	rm -r ${Dir}
fi
if [[ ! -d ${Dir} ]];then
	mkdir -p ${Dir}
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
		if [[ ${SoftName} == "env4cuteSV1" ]];then
			Soft="~/softs/miniconda3/envs/cuteSV_1.0.11"
		elif [[ ${SoftName} == "python3" ]];then
			Soft="~/softs/Python-3.7.7/bin/python3"
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Python3=$(SoftLocate python3)
Bin4Tabix=$(SoftLocate tabix)
Bin4bgzip=$(SoftLocate bgzip)
Dir4SH=$(dirname $0)


## sv calling
NoZipVcf=`echo "${Vcf}" | sed 's/\.gz$//'`
if [[ ${Version} && ${Version} == "v1.0.11" ]];then
	echo "[ Info ] cuteSV version v1.0.11"
	source activate $(SoftLocate env4cuteSV1)
	Bin4CuteSV="cuteSV"
else
	Bin4CuteSV=$(SoftLocate cuteSV)
fi
${Bin4CuteSV} \
	--max_cluster_bias_INS 100 \
	--diff_ratio_merging_INS 0.3 \
	--max_cluster_bias_DEL 100 \
	--diff_ratio_merging_DEL 0.3 \
	--max_split_parts -1 \
	--max_size -1 \
	-md 0 \
	-mi 100 \
	-s 5 \
	-l 50 \
	-L -1 \
	-q 20 \
	-t ${NumOfThreads} \
	-S ${SP} \
	${Bam} ${Genome} ${NoZipVcf} ${Dir}
if [[ ${Version} && ${Version} == "v1.0.11" ]];then
	conda deactivate
fi
${Bin4bgzip} ${NoZipVcf}
if [[ -s ${Vcf} ]];then
	${Bin4Tabix} -p vcf -f ${Vcf}
fi
# add DR
VcfAddDR=`echo "${Vcf}" | sed 's/.vcf.gz$/.AddDR.vcf/'`
${Bin4Python3} ${Dir4SH}/cuteSV.addDR.py \
	${Vcf} ${Bam} ${VcfAddDR}
${Bin4bgzip} -f ${VcfAddDR}
${Bin4Tabix} -p vcf -f ${VcfAddDR}.gz
