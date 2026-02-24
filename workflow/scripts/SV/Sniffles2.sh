#!/bin/bash

# clair3
Bam=$1
Vcf=$2
Genome=$3
MinSize=$4
NumOfThreads=$5

if [[ ! ${Bam} || ! ${Vcf} || ! ${Genome} || ! ${MinSize} || ! ${NumOfThreads} ]];then
	echo "[ Warning ] Not enough argument"
	exit
else
	echo "[ Info ] Sniffles2 begin."
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
		if [[ ${SoftName} == "sniffles" ]];then
			Soft="~/softs/Python-3.7.7/bin/sniffles"
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
Bin4Sniffles=$(SoftLocate sniffles)
Bin4Tabix=$(SoftLocate tabix)
Bin4VcfSort=$(SoftLocate vcfsort)
Bin4bgzip=$(SoftLocate bgzip)


# sniffles
VcfNoGzip=`echo "${Vcf}" | sed 's/\.gz//g'`
${Bin4Sniffles} \
	-i ${Bam} \
	-v ${VcfNoGzip} \
	--reference ${Genome} \
	--minsvlen ${MinSize} \
	--allow-overwrite \
	-t ${NumOfThreads} \
	--mapq 20 --detect-large-ins True
cat ${VcfNoGzip} | ${Bin4VcfSort} -p 2 | ${Bin4bgzip} -c > ${Vcf}
${Bin4Tabix} -p vcf -f ${Vcf}
if [[ -s ${Vcf} && -s ${VcfNoGzip} ]];then
	rm ${VcfNoGzip}
fi
