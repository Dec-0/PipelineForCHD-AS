#!/bin/bash

Bam=$1
File4Bed=$2
SPName=$3
File4Log=$4
ThreadsNum=$5
File4GenomeBed=$6
File4BedExtend=$7

if [[ ! ${Bam} || ! ${File4Bed} || ! ${SPName} || ! ${File4Log} || ! ${ThreadsNum} || ! ${File4GenomeBed} || ! ${File4BedExtend} ]];then
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
		if [[ ${SoftName} == "perl" ]];then
			Soft="~/softs/perl-5.26.3/bin/perl"
		elif [[ ${SoftName} == "samtools1" ]];then
			Soft="~/softs/samtools-1.14/bin/samtools"
		elif [[ ${SoftName} == "bedtools" ]];then
			Soft="~/softs/bedtools-2.26.0/bin/bedtools"
		elif [[ ${SoftName} == "fxTools" ]];then
			Soft="~/softs/fxTools-0.1.0/target/release/fxTools"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Perl=$(SoftLocate perl)
Bin4Samtools=$(SoftLocate samtools1)
Bin4Bedtools=$(SoftLocate bedtools)
Bin4fxTools=$(SoftLocate fxTools)


Dir4BH=`dirname $0`
unset PERL5LIB
${Bin4Perl} ${Dir4BH}/ONT_AS_BamQC_v1.0/ONT_AS_BamQC_v1.0.4.pl \
	-bam ${Bam} \
	-bed ${File4Bed} \
	-extend ${File4BedExtend} \
	-name ${SPName} \
	-log ${File4Log} \
	-g ${File4GenomeBed} \
	-smt ${Bin4Samtools} \
	-bt ${Bin4Bedtools} \
	-fxt ${Bin4fxTools} \
	-t ${ThreadsNum}
