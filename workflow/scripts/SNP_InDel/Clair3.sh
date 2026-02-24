#!/bin/bash

# clair3
ODir=$1
Bam=$2
# Bed file or any other string
Bed=$3
Genome=$4
NumOfThreads=$5
Model=$6
Vcf=$7
Name=$8

if [[ ! ${ODir} || ! ${Bam} || ! ${Bed} || ! ${Genome} || ! ${NumOfThreads} || ! ${Model} || ! ${Vcf} || ! ${Name} ]];then
	echo "[ Warning ] Not enough argument"
	exit
else
	echo "[ Info ] Clair3 begin."
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
		if [[ ${SoftName} == "env4clair3" ]];then
			Soft="~/softs/miniconda3/envs/clair3"
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Tabix=$(SoftLocate tabix)


set +eu
source activate $(SoftLocate env4clair3)
if [[ -s ${Bed} ]];then
	echo "[ Bed File ] ${Bed}"
	run_clair3.sh \
		--bam_fn=${Bam} \
		--ref_fn=${Genome} \
		--bed_fn=${Bed} \
		--output="${ODir}" \
		--threads=${NumOfThreads} \
		--platform="ont" \
		--remove_intermediate_dir \
		--model_path="${Model}" \
		--sample_name="${Name}"
else
	echo "[ Info ] No bed specified"
	run_clair3.sh \
		--bam_fn=${Bam} \
		--ref_fn=${Genome} \
		--output="${ODir}" \
		--threads=${NumOfThreads} \
		--platform="ont" \
		--remove_intermediate_dir \
		--model_path="${Model}" \
		--sample_name="${Name}"
fi
conda deactivate
cp ${ODir}/merge_output.vcf.gz ${Vcf}
${Bin4Tabix} -p vcf ${Vcf}
if [[ -s ${ODir}/merge_output.vcf.gz ]];then
	rm ${ODir}/merge_output.vcf.gz*
fi
