#!/bin/bash

File4Bam=$1
File4Log=$2
NumOfThreads=$3

if [[ ! ${File4Bam} || ! ${File4Log} || ! ${NumOfThreads} ]];then
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
		elif [[ ${SoftName} == "File4SNPList" ]];then
			Soft="~/DB/Annotation/hg38/hg38_EAS.sites.2015_08.Freq0.5.txt.gz"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Perl=$(SoftLocate perl)
Bin4Samtools=$(SoftLocate samtools1)
File4SNPList=$(SoftLocate File4SNPList)


DirBH=`dirname $0`
unset PERL5LIB
${Bin4Perl} ${DirBH}/GenderFromBam_v1.0/GenderFromBam_v1.0.pl \
	-bam ${File4Bam} \
	-log ${File4Log} \
	-list ${File4SNPList} \
	-st ${Bin4Samtools} \
	-t ${NumOfThreads}
