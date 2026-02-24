#!/bin/bash

# for cnv calling
Bam=$1
File4Gender=$2
# bed
File4ExcludBed=$3
# Prefix (with path)
DirAndPrefix=$4
# hg38 or hg19, not full path
GenomeName=$5
# bin size (default 10kb)
BinSize=$6
# output
Vcf=$7
# file for bin info
File4BinInfo=$8

if [[ ! ${Bam} || ! ${File4Gender} || ! ${DirAndPrefix} || ! ${GenomeName} ]];then
	echo "[ Warning ] Not enough argument"
	exit
else
	echo "[ Info ] QDNAseq begin."
	echo "[ Info ] Genome: ${GenomeName}."
	echo "[ Info ] Bin size ${BinSize} kbp."
fi
if [[ ${GenomeName} == "-" ]];then
	GenomeName="hg38"
fi
if [[ ! ${BinSize} || ${BinSize} == "-" ]];then
	BinSize="10"
fi
Gender=`cat ${File4Gender} | grep ^Gender | cut -f 4`
echo "[ Info ] Gender is ${Gender}."

Dir=`dirname ${DirAndPrefix}`
if [[ ! -d ${Dir} ]];then
	mkdir -p ${Dir}
fi
cd ${Dir}

date
Dir4SH=`dirname $0`
if [[ ${File4ExcludBed} == "-" ]];then
	if [[ ${File4BinInfo} && ${File4BinInfo} != "-" && -s ${File4BinInfo} ]];then
		bash ${Dir4SH}/QDNASeq_WGS_v1.3.sh ${Bam} ${Gender} ${DirAndPrefix} ${GenomeName} ${BinSize} ${DirAndPrefix}.Original.vcf.gz - ${File4BinInfo}
	else
		bash ${Dir4SH}/QDNASeq_WGS_v1.3.sh ${Bam} ${Gender} ${DirAndPrefix} ${GenomeName} ${BinSize} ${DirAndPrefix}.Original.vcf.gz - -
	fi
else
	if [[ ${File4BinInfo} && ${File4BinInfo} != "-" && -s ${File4BinInfo} ]];then
		bash ${Dir4SH}/QDNASeq_WGS_v1.3.sh ${Bam} ${Gender} ${DirAndPrefix} ${GenomeName} ${BinSize} ${DirAndPrefix}.Original.vcf.gz ${File4ExcludBed} ${File4BinInfo}
	else
		bash ${Dir4SH}/QDNASeq_WGS_v1.3.sh ${Bam} ${Gender} ${DirAndPrefix} ${GenomeName} ${BinSize} ${DirAndPrefix}.Original.vcf.gz ${File4ExcludBed} -
	fi
fi
date