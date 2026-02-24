#!/bin/bash

# File for depth like .MeanDepth.txt
Bam=$1
# Panel
Panel=$2
# prefix
FilePrefix=$3
# sp
SP=$4
# .PanelStat.txt
File4PanelQC=$5
# like hg38
GenType=$6

if [[ ! ${Bam} || ! ${Panel} || ! ${FilePrefix} || ! ${SP} || ! ${File4PanelQC} || ! ${GenType} ]];then
        echo "[ Warning ] Not enough argument"
        exit
else
        echo "[ Info ] Panel Circos begin."
        echo "[ Info ] Bam: ${Bam}."
        echo "[ Info ] Panel: ${Panel}."
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
		if [[ ${SoftName} == "perl" ]];then
			Soft="~/softs/perl-5.26.3/bin/perl"
		elif [[ ${SoftName} == "python1" ]];then
			Soft="~/softs/miniconda3/envs/sci/bin/python"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Perl=$(SoftLocate perl)
Bin4Python=$(SoftLocate python1)


date
# coverage
Dir4SH=$(dirname $0)
${Bin4Perl} ${Dir4SH}/BinCov_v1.0/BinCov_v1.0.pl \
	-bam ${Bam} \
	-bed ${Panel} \
	-log ${FilePrefix}.OriCov.txt
# sort
cat ${FilePrefix}.OriCov.txt | sed 1d | cut -f 1 | uniq -c | sed -E 's/\s+/\t/g' | awk '{ print $2"\t0\t"$1 }' | grep -vE ^'X|Y|chrX|chrY' | sort -n -k1 > ${FilePrefix}.bed
cat ${FilePrefix}.OriCov.txt | sed 1d | cut -f 1 | uniq -c | sed -E 's/\s+/\t/g' | awk '{ print $2"\t0\t"$1 }' | grep -E ^'X|Y|chrX|chrY' | sort -k1 >> ${FilePrefix}.bed
cat ${FilePrefix}.OriCov.txt | sed 1d | cut -f 1-3,5 | awk 'BEGIN{Id = 0;}{if(GN[$1] != "Yes"){ Id = 0;GN[$1] = "Yes"}else{Id += 1;}; print $1"\t"Id"\t"$3"\t"$4 }' | grep -vE ^'X|Y|chrX|chrY' | sort -n -k1 -k2 > ${FilePrefix}.Cov.txt
cat ${FilePrefix}.OriCov.txt | sed 1d | cut -f 1-3,5 | awk 'BEGIN{Id = 0;}{if(GN[$1] != "Yes"){ Id = 0;GN[$1] = "Yes"}else{Id += 1;}; print $1"\t"Id"\t"$3"\t"$4 }' | grep -E ^'X|Y|chrX|chrY' | sort -n -k1 -k2 >> ${FilePrefix}.Cov.txt
# draw
Dir4SH=`dirname $0`
MaxCount=`cat ${File4PanelQC} | grep ^'Mean coverage On-target:' | cut -f 2 | awk -F '\t' -v NItem="1" '{printf "%.0f", NItem * $1 * 1.6;}'`
echo "[ Info ] Max count is ${MaxCount}"
${Bin4Python} ${Dir4SH}/PanelCovWithCircos_v1.0.py \
	-bed ${FilePrefix}.bed \
	-sp ${SP} \
	-cov ${FilePrefix}.Cov.txt \
	-o ${FilePrefix}.cov.png \
	-max ${MaxCount} \
	-gen ${GenType} \
	-binsize 1
date
