#!/bin/bash

# pbsv
Bam=$1
Vcf=$2
NumOfThreads=$3
Genome=$4
SP=$5

if [[ ! ${Bam} || ! ${Vcf} || ! ${NumOfThreads} || ! ${Genome} || ! ${SP} ]];then
	echo "[ Warning ] Not enough argument"
	exit
else
	echo "[ Info ] pbsv begin."
fi
if [[ ${Vcf} != *.gz ]];then
	echo "[ Error ] ${Vcf} not in gz format"
	exit
fi

Dir=`dirname ${Vcf}`
if [[ ! -d ${Dir} ]];then
	mkdir -p ${Dir}
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
		if [[ ${SoftName} == "pbsv" ]];then
			Soft="~/softs/miniconda3/bin/pbsv"
		elif [[ ${SoftName} == "perl" ]];then
			Soft="~/softs/perl-5.26.3/bin/perl"
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		elif [[ ${SoftName} == "samtools1" ]];then
			Soft="~/softs/samtools-1.14/bin/samtools"
		elif [[ ${SoftName} == "vcfsort" ]];then
			Soft="~/softs/vcftools_0.1.13/bin/vcf-sort"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Bin4pbsv=$(SoftLocate pbsv)
Bin4Perl=$(SoftLocate perl)
Bin4tabix=$(SoftLocate tabix)
Bin4Samtools=$(SoftLocate samtools1)
Bin4VcfSort=$(SoftLocate vcfsort)
Bin4bgzip=$(SoftLocate bgzip)
# for directory of shell
Dir4SH=$(dirname $0)


## sv calling
NoZipVcf=`echo "${Vcf}" | sed 's/\.gz$//'`
VcfPrefix=`echo "${NoZipVcf}" | sed 's/\.vcf$//'`

# chech if svsig exit
if [[ ! -s ${Dir}/${SP}.pbsv.svsig.gz ]];then
	date
	echo "[ Info ] Begin pbsv discover ..."
	${Bin4pbsv} discover \
		--min-mapq 20 \
		--tandem-repeats ${Dir4SH}/human_GRCh38_no_alt_analysis_set.trf.bed \
		${Bam} \
		${Dir}/${SP}.pbsv.svsig.gz
fi
# svsig index
if [[ ! -s ${Dir}/${SP}.pbsv.svsig.gz.tbi ]];then
	date
	echo "[ Info ] Begin svsig index"
	${Bin4tabix} -c '#' -s 3 -b 4 -e 4 ${Dir}/${SP}.pbsv.svsig.gz
fi

# check each chr
date
echo "[ Info ] Begin pbsv call ..."
String4Vcf=""

# genome with chr or no
Tag4Chr=`${Bin4Samtools} view -H ${Bam} | awk 'BEGIN{chrTag = 0;}{if(/SN:chr1/){chrTag += 1;}; if(/SN:chr2/){chrTag += 1;}; if(/SN:chr3/){chrTag += 1;}; if(/SN:chr4/){chrTag += 1;}; if(/SN:chr5/){chrTag += 1;};}END{if(chrTag >= 5){print "Yes";}else{print "No"}}'`
CIdS=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y)
if [[ ${Tag4Chr} == "Yes" ]];then
	CIdS=("chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" "chr21" "chr22" "chrX" "chrY")
fi
for cid in ${CIdS[*]}
do
	${Bin4pbsv} call \
		-j ${NumOfThreads} \
		--log-level TRACE \
		--region ${cid} \
		--min-sv-length 50 \
		--max-ins-length 10M \
		--max-dup-length 10M \
		${Genome} \
		${Dir}/${SP}.pbsv.svsig.gz \
		${VcfPrefix}.${cid}.vcf
		
		tNum=`cat ${VcfPrefix}.${cid}.vcf | grep -v ^# | wc -l`
		if [[ ${tNum} -eq 0 ]];then
			echo -e "\n[ Warning ] Calling of ${cid} is empty.\n"
		fi
		
		if [[ ${String4Vcf} ]];then
			String4Vcf="${String4Vcf} ${VcfPrefix}.${cid}.vcf"
		else
			String4Vcf="${VcfPrefix}.${cid}.vcf"
		fi
done
# header
if [[ ${Tag4Chr} == "Yes" ]];then
	cat ${VcfPrefix}.chr1.vcf | grep ^# > ${VcfPrefix}.Dup.vcf
else
	cat ${VcfPrefix}.1.vcf | grep ^# > ${VcfPrefix}.Dup.vcf
fi
# content
cat ${String4Vcf} | grep -v ^# >> ${VcfPrefix}.Dup.vcf
${Bin4Perl} ${Dir4SH}/VcfDeDup.pl ${VcfPrefix}.Dup.vcf ${NoZipVcf} ${Bin4bgzip}
cat ${NoZipVcf} | ${Bin4VcfSort} | ${Bin4bgzip} -c > ${Vcf}
if [[ -s ${Vcf} ]];then
	${Bin4tabix} -p vcf -f ${Vcf}
fi
