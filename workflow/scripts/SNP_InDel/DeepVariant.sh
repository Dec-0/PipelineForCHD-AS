#!/bin/bash

# need full path or postprocess_variants will report error 'Found multiple file patterns in input filename space: '
Bam=$1
Vcf=$2
#gVcf=$3
Dir4tmp=$3
Dir4Log=$4
Num4Threads=$5
Genome=$6
Bed=$7
Name=$8
# Root Dir like /public
Dir4Root=$9
if [[ ! ${Dir4Root} ]];then
	Dir4Root="/public"
fi
# only support ONT_R104
ModelArg=${10}
if [[ ! ${ModelArg} ]];then
	ModelArg="ONT_R104"
fi
echo "[ Model ] ${ModelArg}"

if [[ ! ${Bam} || ! ${Bed} || ! ${Name} || ! ${Vcf} || ! ${Dir4tmp} || ! ${Dir4Log} || ! ${Num4Threads} || ! ${Dir4Root} || ! ${ModelArg} ]];then
	echo "[ Warning ] Parameters for DeepVariants not complete."
	exit
else
	echo "[ Info ] DeepVariant begin."
fi
if [[ ! -d ${Dir4tmp} ]];then
	mkdir -p ${Dir4tmp}
fi
if [[ ! -d ${Dir4Log} ]];then
	mkdir -p ${Dir4Log}
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
		if [[ ${SoftName} == "Sif4DeepVariant" ]];then
			Soft="~/softs/DeepVariant-1.6.0/deepvariant_1.6.0.sif"
		fi
	fi
	
	echo "${Soft}"
}
Sif4Deep=$(SoftLocate Sif4DeepVariant)


# Variants calling with DeepVariants
# > Be carefull: postprocess_variants needs full path
if [[ -s ${Bed} ]];then
	singularity run -B ${Dir4Root}:${Dir4Root} \
		${Sif4Deep} \
		/opt/deepvariant/bin/run_deepvariant \
		--model_type=${ModelArg} \
		--vcf_stats_report=false \
		--ref=${Genome} \
		--reads=${Bam} \
		--regions=${Bed} \
		--output_vcf=${Vcf} \
		--intermediate_results_dir=${Dir4tmp} \
		--logging_dir=${Dir4Log} \
		--num_shards=${Num4Threads} \
		--postprocess_cpus="1" \
		--sample_name=${Name}
else
	echo "[ Info ] No bed specified."
	singularity run -B ${Dir4Root}:${Dir4Root} \
		${Sif4Deep} \
		/opt/deepvariant/bin/run_deepvariant \
		--model_type=${ModelArg} \
		--vcf_stats_report=false \
		--ref=${Genome} \
		--reads=${Bam} \
		--output_vcf=${Vcf} \
		--intermediate_results_dir=${Dir4tmp} \
		--logging_dir=${Dir4Log} \
		--num_shards=${Num4Threads} \
		--postprocess_cpus="1" \
		--sample_name=${Name}
fi

if [[ -d ${Dir4tmp} ]];then
	rm -r ${Dir4tmp}
fi
