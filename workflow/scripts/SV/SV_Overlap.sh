#!/bin/bash

# comparation of sv calling result by different softs
RDir=$1
LDir=$2
SP=$3
# seperated by comma like 'cuteSV,sniffles,debreak,pbsv'
SoftString=$4

if [[ ! ${RDir} || ! ${LDir} || ! ${SoftString} ]];then
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
		if [[ ${SoftName} == "perl" ]];then
			Soft="~/softs/perl-5.26.3/bin/perl"
		elif [[ ${SoftName} == "truvari" ]];then
			Soft="~/softs/Python-3.7.7/bin/truvari"
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Perl=$(SoftLocate perl)
Bin4Tabix=$(SoftLocate tabix)
Bin4Truvari=$(SoftLocate truvari)
Bin4bgzip=$(SoftLocate bgzip)
# for directory of shell
Dir4SH=$(dirname $0)


if [[ ! -d ${LDir} ]];then
	mkdir ${LDir}
fi
Softs=(`echo "${SoftString}" | sed 's/,/ /g'`)
if [[ -s ${LDir}/truvari.stat.txt ]];then
	rm ${LDir}/truvari.stat.txt
fi

# debreak shoud add FORMAT GT info in head
if [[ ${Softs[@]} =~ "debreak" ]];then
	File4OriVcf="${RDir}/debreak/${SP}/${SP}.debreak.AddDP.vcf.gz"
	if [[ ! -s ${File4OriVcf} ]];then
		File4OriVcf="${RDir}/debreak/${SP}/${SP}.debreak.vcf.gz"
	fi
	if [[ ! -s ${File4OriVcf} ]];then
		echo "[ Error ] File not exit (${File4OriVcf})"
		exit
	fi
	zcat ${File4OriVcf} | grep ^'##' > ${LDir}/${SP}.debreak.vcf
	echo "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">" >> ${LDir}/${SP}.debreak.vcf
	echo "##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Read depth at this position for this sample\">" >> ${LDir}/${SP}.debreak.vcf
	echo "##FORMAT=<ID=DR,Number=1,Type=Integer,Description=\"Number of reference reads\">" >> ${LDir}/${SP}.debreak.vcf
	echo "##FORMAT=<ID=DV,Number=1,Type=Integer,Description=\"Number of variant reads\">" >> ${LDir}/${SP}.debreak.vcf
	zcat ${File4OriVcf} | grep -v ^'##' >> ${LDir}/${SP}.debreak.vcf
	${Bin4bgzip} -f ${LDir}/${SP}.debreak.vcf
	${Bin4Tabix} -p vcf ${LDir}/${SP}.debreak.vcf.gz
	
	# dump TRA in symbolic notation is not convenient for other procedures like annotation
	${Bin4Perl} ${Dir4SH}/SVSplit.TypeAndLen.pl ${LDir}/${SP}.debreak.vcf.gz ${LDir}/${SP}.debreak.Flt.vcf.gz "INS,DEL,DUP,INV" - - ${Bin4bgzip} ${Bin4Tabix}
fi
for soft in ${Softs[*]}
do
	if [[ ${soft} == "debreak" ]];then
		continue
	fi
	
	OriVcf="${RDir}/${soft}/${SP}/${SP}.${soft}.vcf.gz"
	if [[ ! -s ${OriVcf} ]];then
		echo "[ Error ] File not exit (${OriVcf})"
		exit
	fi
	${Bin4Perl} ${Dir4SH}/SVSplit.TypeAndLen.pl ${OriVcf} ${LDir}/${SP}.${soft}.Flt.vcf.gz "INS,DEL,DUP,INV,BND" - - ${Bin4bgzip} ${Bin4Tabix}
done

# compare two softs each time
for s1 in ${!Softs[@]}
do
	for s2 in ${!Softs[@]}
	do
		if [ ${s1} -ge ${s2} ];then
			continue
		fi
		
		Soft1="${Softs[$s1]}"
		Soft2="${Softs[$s2]}"
		echo "[ Info ] ${Soft1} vs ${Soft2}"
		Vcf1="${LDir}/${SP}.${Soft1}.Flt.vcf.gz"
		Vcf2="${LDir}/${SP}.${Soft2}.Flt.vcf.gz"
		
		Dir4Bench="${LDir}/${Soft1}_${Soft2}"
		if [[ -d ${Dir4Bench} ]];then
			rm -r ${Dir4Bench}
		fi
		
		# compare
		${Bin4Truvari} bench --passonly --typeignore -r 1000 -C 1000 -p 0 -P 0.7 -s 0 -S 0 --sizemax 100000000 -b ${Vcf1} -c ${Vcf2} -o ${Dir4Bench}
		# result stat
		File4FN="${LDir}/${Soft1}_${Soft2}/fn.vcf"
		File4FP="${LDir}/${Soft1}_${Soft2}/fp.vcf"
		File4TP1="${LDir}/${Soft1}_${Soft2}/tp-base.vcf"
		File4TP2="${LDir}/${Soft1}_${Soft2}/tp-call.vcf"
		${Bin4Perl} ${Dir4SH}/SV_Overlap.Compare.pl ${LDir}/truvari.stat.txt ${Soft1} ${Soft2} ${File4FN} ${File4FP} ${File4TP1} ${File4TP2}
	done
done
