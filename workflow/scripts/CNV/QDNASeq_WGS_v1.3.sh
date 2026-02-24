#!/bin/bash

# For WGS CNV calling
Bam=$1
Gender=$2
# Prefix (with path)
DirAndPrefix=$3
# hg38 or hg19, not full path
GenomeName=$4
# bin size (default 10kb)
BinSize=$5
# output
Vcf=$6
# Bed for exclude (a file or none)
Bed4Exclude=$7
# file for bin info
File4BinInfo=$8

if [[ ! ${Bam} || ! ${Gender} || ! ${DirAndPrefix} || ! ${GenomeName} ]];then
	echo "[ Warning ] Not enough argument"
	exit
else
	echo "[ Info ] QDNAseq begin."
	echo "[ Info ] Gender: ${Gender}."
	echo "[ Info ] Genome: ${GenomeName}."
	echo "[ Info ] Bin size ${BinSize} kbp."
fi
if [[ ${Gender} == "-" ]];then
	Gender="Female"
	echo "[ Info ] Default gender: ${Gender}."
fi
if [[ ${GenomeName} == "-" ]];then
	GenomeName="hg38"
	echo "[ Info ] Default genome: ${GenomeName}."
fi
if [[ ! ${BinSize} || ${BinSize} == "-" ]];then
	BinSize="10"
	echo "[ Info ] Default bin size: ${BinSize} kbp."
fi
if [[ ${Bed4Exclude} != "-" && -s ${Bed4Exclude} ]];then
	echo "[ Info ] Bed for excluding is ${Bed4Exclude}."
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
		if [[ ${SoftName} == "Rscript2" ]];then
			Soft="~/softs/miniconda3/envs/R42/bin/Rscript"
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Rscript=$(SoftLocate Rscript2)
Bin4tabix=$(SoftLocate tabix)
Bin4bgzip=$(SoftLocate bgzip)


Dir=`dirname ${DirAndPrefix}`
if [[ ! -d ${Dir} ]];then
	echo "[ Info ] mkdir for ${Dir}"
	mkdir -p ${Dir}
fi
cd ${Dir}

date
Dir4SH=$(dirname $0)
if [[ ${Bed4Exclude} && ${Bed4Exclude} != "-" ]];then
	if [[ ${File4BinInfo} && ${File4BinInfo} != "-" && -s ${File4BinInfo} ]];then
		${Bin4Rscript} ${Dir4SH}/QDNASeq_WGS_v1.3.r \
			-b ${Bam} \
			-o ${DirAndPrefix} \
			-r ${GenomeName} \
			--gender ${Gender} \
			--binsize ${BinSize} \
			--bed ${Bed4Exclude} \
			--blist ${Dir4SH} \
			--File4Bin ${File4BinInfo}
	else
		${Bin4Rscript} ${Dir4SH}/QDNASeq_WGS_v1.3.r \
			-b ${Bam} \
			-o ${DirAndPrefix} \
			-r ${GenomeName} \
			--gender ${Gender} \
			--binsize ${BinSize} \
			--blist ${Dir4SH} \
			--bed ${Bed4Exclude}
	fi
else
	if [[ ${File4BinInfo} && ${File4BinInfo} != "-" && -s ${File4BinInfo} ]];then
		${Bin4Rscript} ${Dir4SH}/QDNASeq_WGS_v1.3.r \
			-b ${Bam} \
			-o ${DirAndPrefix} \
			-r ${GenomeName} \
			--gender ${Gender} \
			--binsize ${BinSize} \
			--blist ${Dir4SH} \
			--File4Bin ${File4BinInfo}
	else
		${Bin4Rscript} ${Dir4SH}/QDNASeq_WGS_v1.3.r \
			-b ${Bam} \
			-o ${DirAndPrefix} \
			-r ${GenomeName} \
			--gender ${Gender} \
			--blist ${Dir4SH} \
			--binsize ${BinSize}
	fi
fi
date

# --------------------------------------
# function
exportBinsBugFix() {
	local SpecFile4Previous=$1
	local SpecSPName=$2
	
	# bug appears when only one variant called
	tNum4TwoLine=`cat ${SpecFile4Previous} | grep ^# | wc -l`
	tNum4OneLine=`cat ${SpecFile4Previous} | grep ^# | grep -v ^## | wc -l`
	tNum4LeftLine=`cat ${SpecFile4Previous} | grep -v ^# | wc -l`
	if [[ ${tNum4TwoLine} > 0 && ${tNum4OneLine} == 0 && ${tNum4LeftLine} == 11 ]];then
		cat ${SpecFile4Previous} | grep ^## > ${SpecFile4Previous}.tmp
		echo -e "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t${SpecSPName}" >> ${SpecFile4Previous}.tmp
		cat ${SpecFile4Previous} | grep -v ^# | sed 1d | sed ':a;N;s/\n/\t/g;ba' >> ${SpecFile4Previous}.tmp
		mv ${SpecFile4Previous}.tmp ${SpecFile4Previous}
	fi
	
}
if true;then
	echo "[ Info ] Bug fixing for exportBins in QDNAseq."
	if [[ ${Gender} == "Male" ]];then
		exportBinsBugFix ${DirAndPrefix}_auto_calls.vcf ${DirAndPrefix}
		exportBinsBugFix ${DirAndPrefix}_sex_calls.vcf ${DirAndPrefix}
	else
		exportBinsBugFix ${DirAndPrefix}_calls.vcf ${DirAndPrefix}
	fi
fi


if [[ ${Gender} == "Male" ]];then
	cat ${DirAndPrefix}_auto_calls.vcf | grep ^# > ${DirAndPrefix}_calls.vcf
	cat ${DirAndPrefix}_auto_calls.vcf | grep -v ^# >> ${DirAndPrefix}_calls.vcf
	cat ${DirAndPrefix}_sex_calls.vcf | grep -v ^# >> ${DirAndPrefix}_calls.vcf
	rm ${DirAndPrefix}_auto_calls.vcf ${DirAndPrefix}_sex_calls.vcf
fi

if [[ ${Vcf} && ${Vcf} = *.gz ]];then
	tVcf="${DirAndPrefix}_calls.vcf"
	if [[ -s ${tVcf} ]];then
		cat ${tVcf} | ${Bin4bgzip} -c > ${Vcf}
		${Bin4tabix} -p vcf -f ${Vcf}
	fi
fi
