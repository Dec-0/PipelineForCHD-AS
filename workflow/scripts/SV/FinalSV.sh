#!/bin/bash

# For generation of final sv result
RDir=$1
LDir=$2
SP=$3
# seperated by comma like 'cuteSV,sniffles,debreak,pbsv'
SoftString=$4

if [[ ! ${RDir} || ! ${LDir} || ! ${SP} || ! ${SoftString} ]];then
	echo "[ Warning ] Not enough arguments"
	exit
fi

if [[ ${RDir} == ${LDir} ]];then
	echo "[ Error ] L and R directory should not be the same"
	exit
fi
if [[ ! -d ${LDir} ]];then
	mkdir ${LDir}
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
		elif [[ ${SoftName} == "vcfsort" ]];then
			Soft="~/softs/vcftools_0.1.13/bin/vcf-sort"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Perl=$(SoftLocate perl)
Bin4Tabix=$(SoftLocate tabix)
Bin4VcfSort=$(SoftLocate vcfsort)
Bin4bgzip=$(SoftLocate bgzip)


# for directory of shell
Dir4SH=$(dirname $0)
Softs=(`echo "${SoftString}" | sed 's/,/ /g'`)

# rules:
# 1. all sv of debreak other than TRA;
# 2. INS DUP or DEL larger than 10kb not detected by debreak
# 3. other than debreak & minimal two soft detected, order: pbsv,sniffles,cuteSV
File4Stat="${RDir}/truvari.stat.txt"
# output all debreak result other than TRA
if [[ ${Softs[@]} =~ "debreak" ]];then
	# other than TRA
	zcat ${RDir}/${SP}.debreak.Flt.vcf.gz | awk -F '\t' '{if(/^#/ || $4 != "<TRA>"){print}}' | ${Bin4bgzip} -c > ${LDir}/${SP}.debreak.Final.vcf.gz
fi
# BND from cuteSV
if [[ ${Softs[@]} =~ "cuteSV" ]];then
	# only BND
	zcat ${RDir}/${SP}.cuteSV.Flt.vcf.gz | awk -F '\t' '{if(/^#/ || /SVTYPE=BND/){print}}' | ${Bin4bgzip} -c > ${LDir}/${SP}.cuteSV.Final.vcf.gz
fi
# output pbsv
if [[ ${Softs[@]} =~ "pbsv" ]];then
	# INS DUP or DEL larger than 10kb not detected by debreak（only detected by pbsv）
	# 2025.1.16 10kb改为1kb
	# 2025.4.15 1kb改为10kb（模拟数据1~10kb的性能数据不太好，测试用）
	cat ${File4Stat} | sed 's/,/\t/g' | awk -F '\t' '{if($3 == "INS" || $3 == "DUP" || $3 == "DEL"){print}}' | awk -F '\t' '{if($4 >= 10000){print}}' | sed 's/\t/,/' | sed 's/\t/,/' | sed 's/\t/,/' | awk -F '\t' '{if($3 == "pbsv"){print}}' | cut -f 1,2 > ${LDir}/${SP}.pbsv.SVInfo.txt
	# other than BND, not called by debreak, but called by pbsv and others;
	cat ${File4Stat} | awk -F '\t' '{if($1 !~ /BND/){print}}' | awk -F '\t' '{if($3 !~ /debreak/){print}}' | awk -F '\t' '{if($3 ~ /pbsv/ && $3 ~ /,/){print}}' | cut -f 1,2 >> ${LDir}/${SP}.pbsv.SVInfo.txt
	# BND, called by more than two softs
	cat ${File4Stat} | awk -F '\t' '{if($1 ~ /BND/){print}}' | awk -F '\t' '{if($3 !~ /cuteSV/ && $3 ~ /pbsv/ && $3 ~ /,/){print}}' | cut -f 1-2 >> ${LDir}/${SP}.pbsv.SVInfo.txt
	# pbsv.BND in the same chr are removed (2025.5.8修改为不过滤)
	${Bin4Perl} ${Dir4SH}/FinalSV.Extract.pl ${LDir}/${SP}.pbsv.SVInfo.txt ${RDir}/${SP}.pbsv.Flt.vcf.gz ${LDir}/${SP}.pbsv.Final.vcf.gz ${Bin4bgzip}
fi
# output sniffles
if [[ ${Softs[@]} =~ "sniffles" ]];then
	# other than BND, not called by debreak and pbsv, but called by sniffles and others;
	cat ${File4Stat} | awk -F '\t' '{if($1 !~ /BND/){print}}' | awk -F '\t' '{if($3 !~ /debreak/ && $3 !~ /pbsv/){print}}' | awk -F '\t' '{if($3 ~ /sniffles/ && $3 ~ /,/){print}}' | cut -f 1,2 > ${LDir}/${SP}.sniffles.SVInfo.txt
	# BND, no need;
	${Bin4Perl} ${Dir4SH}/FinalSV.Extract.pl ${LDir}/${SP}.sniffles.SVInfo.txt ${RDir}/${SP}.sniffles.Flt.vcf.gz ${LDir}/${SP}.sniffles.Final.vcf.gz ${Bin4bgzip}
fi


zcat ${LDir}/${SP}.sniffles.Final.vcf.gz | grep ^## > ${LDir}/${SP}.FinalSV.vcf
zcat ${LDir}/${SP}.debreak.Final.vcf.gz | grep ^## | grep -E 'SVMETHOD|SUPPREAD|MAPQ' >> ${LDir}/${SP}.FinalSV.vcf
zcat ${LDir}/${SP}.debreak.Final.vcf.gz | grep ^## | grep -E 'MULTI|START2|END2|SVLEN2' >> ${LDir}/${SP}.FinalSV.vcf
zcat ${LDir}/${SP}.pbsv.Final.vcf.gz | grep ^# | grep -E 'AD|DP|SAC|SVANN' >> ${LDir}/${SP}.FinalSV.vcf
zcat ${LDir}/${SP}.sniffles.Final.vcf.gz | grep ^# | grep -v ^## >> ${LDir}/${SP}.FinalSV.vcf


for s1 in ${!Softs[@]}
do
	Soft="${Softs[$s1]}"
	File4Vcf="${LDir}/${SP}.${Soft}.Final.vcf.gz"
	if [[ ! -s ${File4Vcf} ]];then
		continue
	fi
	zcat ${File4Vcf} | grep -v ^# >> ${LDir}/${SP}.FinalSV.vcf
done
cat ${LDir}/${SP}.FinalSV.vcf | ${Bin4VcfSort} | ${Bin4bgzip} -c > ${LDir}/${SP}.FinalSV.vcf.gz
${Bin4Tabix} -p vcf -f ${LDir}/${SP}.FinalSV.vcf.gz
rm ${LDir}/${SP}.FinalSV.vcf
