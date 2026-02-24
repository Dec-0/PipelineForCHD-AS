#!/bin/bash

# debreak
Bam=$1
Vcf=$2
Genome=$3
MinSize=$4
NumOfThreads=$5

if [[ ! ${Bam} || ! ${Vcf} || ! ${Genome} || ! ${MinSize} || ! ${NumOfThreads} ]];then
	echo "[ Warning ] Not enough argument"
	exit
else
	echo "[ Info ] debreak begin."
fi

if [[ ${Vcf} != *.gz ]];then
	echo "[ Info ] Vcf not in gz format."
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
		if [[ ${SoftName} == "env4debreak" ]];then
			Soft="~/softs/miniconda3/envs/debreak"
		elif [[ ${SoftName} == "perl" ]];then
			Soft="~/softs/perl-5.26.3/bin/perl"
		elif [[ ${SoftName} == "python3" ]];then
			Soft="~/softs/Python-3.7.7/bin/python3"
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		elif [[ ${SoftName} == "vcfsort" ]];then
			Soft="~/softs/vcftools_0.1.13/bin/vcf-sort"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Perl=$(SoftLocate perl)
Bin4Python=$(SoftLocate python3)
Bin4Tabix=$(SoftLocate tabix)
Bin4VcfSort=$(SoftLocate vcfsort)
Bin4bgzip=$(SoftLocate bgzip)


Dir=`dirname ${Vcf}`
source activate $(SoftLocate env4debreak)
debreak --bam ${Bam} \
	-o ${Dir}/debreak_out \
	--rescue_large_ins --rescue_dup --poa --ref ${Genome} --min_size ${MinSize} -t ${NumOfThreads} --min_quality 20 \
	--min_support 3 --maxcov 10000
conda deactivate

Dir4SH=`dirname $0`
VcfBeforeAddEnd=`echo "${Vcf}" | sed 's/.vcf.gz$/.BeforeAddEnd.vcf.gz/'`
cat ${Dir}/debreak_out/debreak.vcf | ${Bin4VcfSort} -p 2 | ${Bin4bgzip} -c > ${VcfBeforeAddEnd}
${Bin4Perl} ${Dir4SH}/debreak.addEND.pl ${VcfBeforeAddEnd} ${Vcf} ${Bin4bgzip}
${Bin4Tabix} -p vcf -f ${Vcf}

# add depth info
VcfAddDR=`echo "${Vcf}" | sed 's/.vcf.gz$/.AddDP.vcf/'`
${Bin4Python} ${Dir4SH}/debreak.addDR.py \
	${Vcf} ${Bam} ${VcfAddDR}
${Bin4bgzip} -f ${VcfAddDR}
${Bin4Tabix} -p vcf -f ${VcfAddDR}.gz
