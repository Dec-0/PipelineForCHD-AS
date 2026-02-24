#!/bin/bash

# bam
Bam=$1
# window
File4Window=$2
WinSize=$3
# prefix
Fileprefix=$4
# sp
SP=$5
# .PanelStat.txt
File4PanelQC=$6
# like hg38
GenType=$7

if [[ ! ${Bam} || ! ${File4Window} || ! ${WinSize} || ! ${Fileprefix} || ! ${SP} || ! ${File4PanelQC} || ! ${GenType} ]];then
        echo "[ Warning ] Not enough argument"
        exit
else
        echo "[ Info ] WGS Circos begin."
        echo "[ Info ] Window: ${File4Window}."
        echo "[ Info ] WinSize: ${WinSize}."
        echo "[ Info ] Sample name: ${SP}."
        echo "[ Info ] Reference: ${GenType}."
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
		if [[ ${SoftName} == "bedtools" ]];then
			Soft="~/softs/bedtools-2.26.0/bin/bedtools"
		elif [[ ${SoftName} == "python1" ]];then
			Soft="~/softs/miniconda3/envs/sci/bin/python"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Bedtools=$(SoftLocate bedtools)
Bin4Python=$(SoftLocate python1)


date
# coverage
${Bin4Bedtools} multicov -q 20 -bams ${Bam} -bed ${File4Window} > ${Fileprefix}.cov.histogram
# draw
Dir4SH=`dirname $0`
Item=`echo "${File4Window}" | cut -d '_' -f 1 | awk -F '.' '{print $NF}' | sed 's/k//' | awk '{print $1 * 2;}'`
MaxCount=`cat ${File4PanelQC} | grep ^'Mean coverage Off-target:' | cut -f 2 | awk -F '\t' -v NItem="${Item}" '{printf "%.0f", NItem * $1 * 1.3;}'`
echo "[ Info ] Max count is ${MaxCount}"
Dir4SH=`dirname $0`
${Bin4Python} ${Dir4SH}/GenomeCovWithCircos_v1.0.py \
	-sp ${SP} -cov ${Fileprefix}.cov.histogram \
	-o ${Fileprefix}.cov.png \
	-max ${MaxCount} \
	-gen ${GenType} \
	-binsize ${WinSize}
date
