#!/bin/bash
input=$1
FinalSNP=$2
FinalIndel=$3
Prefix4SNP=$4
Prefix4InDel=$5
Genome=$6

if [[ ! ${input} || ! ${FinalSNP} || ! ${FinalIndel} || ! ${Prefix4SNP} || ! ${Prefix4InDel} || ! ${Genome} ]];then
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
		if [[ ${SoftName} == "vcftools" ]];then
			Soft="~/softs/vcftools_0.1.13/bin/vcftools"
		elif [[ ${SoftName} == "bcftools" ]];then
			Soft="~/softs/hap.py-0.3.15/bin/bcftools"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Vcftools=$(SoftLocate vcftools)
Bin4Bcftools=$(SoftLocate bcftools)


${Bin4Vcftools} --gzvcf ${input} --remove-indels --recode --recode-INFO-all --out ${Prefix4SNP}
${Bin4Vcftools} --gzvcf ${input} --keep-only-indels --recode --recode-INFO-all --out ${Prefix4InDel}
awk -F '\t' '{{if($0 ~ /\#/) print; else if($7 == "PASS") print}}' ${Prefix4SNP}.recode.vcf > ${Prefix4SNP}.pass.vcf
awk -F '\t' '{{if($0 ~ /\#/) print; else if($7 == "PASS") print}}' ${Prefix4InDel}.recode.vcf > ${Prefix4InDel}.pass.vcf
${Bin4Bcftools} norm -m -both -c w -f ${Genome} -o ${Prefix4SNP}.vcf ${Prefix4SNP}.pass.vcf
${Bin4Bcftools} norm -m -both -c w -f ${Genome} -o ${Prefix4InDel}.vcf ${Prefix4InDel}.pass.vcf
rm ${Prefix4SNP}.recode.vcf
rm ${Prefix4SNP}.pass.vcf
rm ${Prefix4InDel}.recode.vcf
rm ${Prefix4InDel}.pass.vcf
