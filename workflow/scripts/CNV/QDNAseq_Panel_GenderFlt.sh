#!/bin/bash

# CNV calling result like QDNAseq
CNVOri=$1
# CMV filter result
CNVFlt=$2
# Gender file which recored like Male or Female
File4Gender=$3

if [[ ! ${CNVOri} || ! ${CNVFlt} || ! ${File4Gender} ]];then
	echo "[ Warning ] Not enough argument"
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
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Perl=$(SoftLocate perl)
Bin4Tabix=$(SoftLocate tabix)
Bin4bgzip=$(SoftLocate bgzip)
Dir4SH=$(dirname $0)


Gender=`cat ${File4Gender} | grep ^'Gender' | cut -f 4`
${Bin4Perl} ${Dir4SH}/QDNAseq_FltByGender_v1.0.pl \
	-i ${CNVOri} \
	-o ${CNVFlt} \
	-g ${Gender} \
	-bgz ${Bin4bgzip}
if [[ ${CNVFlt} == *.vcf.gz ]];then
	${Bin4Tabix} -p vcf -f ${CNVFlt}
fi
