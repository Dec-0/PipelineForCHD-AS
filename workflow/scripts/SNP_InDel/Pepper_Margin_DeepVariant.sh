#!/bin/bash

# need full path or postprocess_variants will report error 'Found multiple file patterns in input filename space: '
Bam=$1
Dir4Log=$2
Prefix=$3
Num4Threads=$4
Genome=$5
Name=$6
Bed=$7
# Root Dir like /public
Dir4Root=$8
if [[ ! ${Dir4Root} ]];then
	Dir4Root="/public"
fi
# --ont_r9_guppy5_sup or --ont_r10_q20
ModelArg=$9
if [[ ! ${ModelArg} ]];then
	ModelArg="--ont_r10_q20"
fi
echo "[ Model ] ${ModelArg}"

if [[ ! ${Bam} || ! ${Dir4Log} || ! ${Bed} || ! ${Prefix} || ! ${Num4Threads} || ! ${Genome} || ! ${Name} || ! ${Dir4Root} || ! ${ModelArg} ]];then
	echo "[ Warning ] Parameters for Pepper Margin DeepVariants not complete."
	exit
else
	echo "[ Info ] Pepper Margin DeepVariant begin."
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
		if [[ ${SoftName} == "Sif4PepperDeepVariant" ]];then
			Soft="~/softs/pepper_deepvariant/pepper_deepvariant_r0.8.sif"
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		elif [[ ${SoftName} == "bedtools" ]];then
			Soft="~/softs/bedtools-2.26.0/bin/bedtools"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Sif4Pepper=$(SoftLocate Sif4PepperDeepVariant)
Bin4Bedtools=$(SoftLocate bedtools)
Bin4Tabix=$(SoftLocate tabix)
Bin4bgzip=$(SoftLocate bgzip)


# Variants calling with DeepVariants
# > Be carefull: postprocess_variants needs full path
# do not support bed temporarily
# --ont_r9_guppy5_sup or --ont_r10_q20
# --region only support format in contig_name:start-end, not bed
if [[ -s ${Bed} ]];then
	# Change prefix;
	singularity exec --cleanenv --no-home -B ${Dir4Root}:${Dir4Root} \
		${Sif4Pepper} \
		run_pepper_margin_deepvariant call_variant \
		-b "${Bam}" \
		-f "${Genome}" \
		-o "${Dir4Log}" \
		-p "${Prefix}.BeforeBedFlt" \
		-t "${Num4Threads}" \
		-s "${Name}" \
		${ModelArg}
	
	# filter by bed
	echo "[ Info ] Begin bed filter"
	cat ${Bed} | ${Bin4Bedtools} merge -d 1000 -i - | gzip -c > ${Dir4Log}/${Prefix}.extend1k.bed.gz
	${Bin4Tabix} -h -R ${Dir4Log}/${Prefix}.extend1k.bed.gz -T ${Bed} ${Dir4Log}/${Prefix}.BeforeBedFlt.vcf.gz | ${Bin4bgzip} -c > ${Dir4Log}/${Prefix}.vcf.gz
	${Bin4Tabix} -p vcf ${Dir4Log}/${Prefix}.vcf.gz
	rm ${Dir4Log}/${Prefix}.extend1k.bed.gz
	rm ${Dir4Log}/${Prefix}.BeforeBedFlt.vcf.gz ${Dir4Log}/${Prefix}.BeforeBedFlt.vcf.gz.tbi
else
	singularity exec --cleanenv --no-home -B ${Dir4Root}:${Dir4Root} \
		${Sif4Pepper} \
		run_pepper_margin_deepvariant call_variant \
		-b "${Bam}" \
		-f "${Genome}" \
		-o "${Dir4Log}" \
		-p "${Prefix}" \
		-t "${Num4Threads}" \
		-s "${Name}" \
		${ModelArg}
fi

# clean
if [[ -d ${Dir4Log}/intermediate_files ]];then
	rm -r ${Dir4Log}/intermediate_files
fi
