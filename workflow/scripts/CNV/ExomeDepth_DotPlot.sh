#!/bin/bash

# ./ExomeDepth.NA24385 which should be with path !!!
Dir4Ana=$1
SPName=$2


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
		if [[ ${SoftName} == "Rscript1" ]];then
			Soft="~/softs/miniconda3/envs/R36/bin/Rscript"
		fi
	fi
	
	echo "${Soft}"
}


#==========================================================
Bin4Rscript=$(SoftLocate Rscript1)
Dir4SH=`dirname $0`
echo "[ Info ] Map draw"
for midfix in "ReadCount.ExomeDepth"
do
	FilePrefix="${Dir4Ana}/ExomeDepth/${SPName}/${SPName}"
	# all chr on even space on del and dup
	${Bin4Rscript} ${Dir4SH}/ReadCountDot_v1.0.r ${FilePrefix}.${midfix}.RelativeCount.pdf 15 4 1 1 ${FilePrefix}.${midfix}.RelativeCount.Sort.txt '' 'chromosome' 'Relative Read Count' -
	
	# chr split
	Str4Map=""
	Num4Map=0
	for chr in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y
	do
		ChrNum=`cat ${FilePrefix}.${midfix}.RelativeCount.txt | sed 1d | awk -F '\t' -v CName="${chr}" '{if($1 == CName){print;}}' | wc -l`
		if [[ ${ChrNum} == 0 ]];then
			continue
		fi
		
		cat ${FilePrefix}.${midfix}.RelativeCount.txt | head -n1 > ${FilePrefix}.${midfix}.RelativeCount.Sort.chr${chr}.txt
		cat ${FilePrefix}.${midfix}.RelativeCount.txt | sed 1d | awk -F '\t' -v CName="${chr}" '{if($1 == CName){print;}}' | sort -n -k1 -k2 >> ${FilePrefix}.${midfix}.RelativeCount.Sort.chr${chr}.txt
		
		Num4Map=$((${Num4Map} + 1))
		if [[ ! ${Str4Map} ]];then
			Str4Map="${FilePrefix}.${midfix}.RelativeCount.Sort.chr${chr}.txt '' 'chromosome' 'Relative Read Count' -"
		else
			Str4Map="${Str4Map} ${FilePrefix}.${midfix}.RelativeCount.Sort.chr${chr}.txt '' 'chromosome' 'Relative Read Count' -"
		fi
	done
	echo "${Str4Map}" | xargs ${Bin4Rscript} ${Dir4SH}/ReadCountDot_v1.0.1.r ${FilePrefix}.${midfix}.RelativeCount.ChrSplit.pdf 6 2 ${Num4Map} 1
	# rm
	for chr in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y
	do
		if [[ -s ${FilePrefix}.${midfix}.RelativeCount.Sort.chr${chr}.txt ]];then
			rm ${FilePrefix}.${midfix}.RelativeCount.Sort.chr${chr}.txt
		fi
	done
done
