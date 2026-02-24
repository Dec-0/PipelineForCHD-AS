#!/bin/bash

# .MeanDepth.txt
File4MeanDepth=$1
# .ReadCount.txt
File4ReadCount=$2
# prefix
FilePrefix=$3
# sp
SP=$4

if [[ ! ${File4MeanDepth} || ! ${File4ReadCount} || ! ${FilePrefix} || ! ${SP} ]];then
        echo "[ Warning ] Not enough argument"
        exit
else
        echo "[ Info ] Panel Circos begin."
        echo "[ Info ] File for MeanDepth: ${File4MeanDepth}."
        echo "[ Info ] File for ReadCount: ${File4ReadCount}."
        echo "[ Info ] Sample name: ${SP}."
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
		if [[ ${SoftName} == "python1" ]];then
			Soft="~/softs/miniconda3/envs/sci/bin/python"
		fi
	fi
	
	echo "${Soft}"
}


Bin4Python=$(SoftLocate python1)
Dir4SH=`dirname $0`
date
for str in "${File4ReadCount},ReadCount" "${File4MeanDepth},MeanDepth"
do
	tFile=`echo "${str}" | cut -d ',' -f 1`
	tMid=`echo "${str}" | cut -d ',' -f 2`
	
	# area
	cat ${tFile} | sed 1d | cut -f 1 | uniq -c | sed -E 's/\s+/\t/g' | awk '{ print $2"\t0\t"$1 }' | grep -vE ^'X|Y|chrX|chrY' | sort -n -k1 > ${FilePrefix}.${tMid}.bed
	cat ${tFile} | sed 1d | cut -f 1 | uniq -c | sed -E 's/\s+/\t/g' | awk '{ print $2"\t0\t"$1 }' | grep -E ^'X|Y|chrX|chrY' | sort -k1 >> ${FilePrefix}.${tMid}.bed
	# value and sort
	cat ${tFile}| sed 1d | cut -f 1-3,5 | awk 'BEGIN{Id = 0;}{if(GN[$1] != "Yes"){ Id = 0;GN[$1] = "Yes"}else{Id += 1;}; print $1"\t"Id"\t"$3"\t"$4 }' | grep -vE ^'X|Y|chrX|chrY' | sort -n -k1 -k2 > ${FilePrefix}.${tMid}.Cov.txt
	cat ${tFile}| sed 1d | cut -f 1-3,5 | awk 'BEGIN{Id = 0;}{if(GN[$1] != "Yes"){ Id = 0;GN[$1] = "Yes"}else{Id += 1;}; print $1"\t"Id"\t"$3"\t"$4 }' | grep -E ^'X|Y|chrX|chrY' | sort -n -k1 -k2 >> ${FilePrefix}.${tMid}.Cov.txt
	# draw
	MaxCount=`cat ${tFile} | sed 1d | awk -F '\t' -v NItem="1" 'BEGIN{Sum = 0;Num = 0;}{Sum += $5;Num += 1;}END{ Mean = Sum / Num;printf "%.0f", NItem * Mean * 1.6; }'`
	echo "[ Info ] Max count is ${MaxCount}"
	${Bin4Python} ${Dir4SH}/../QC/PanelCovWithCircos_v1.0.py \
		-bed ${FilePrefix}.${tMid}.bed \
		-sp ${SP} \
		-cov ${FilePrefix}.${tMid}.Cov.txt \
		-o ${FilePrefix}.${tMid}.cov.png \
		-max ${MaxCount} \
		-binsize 1
done
date
