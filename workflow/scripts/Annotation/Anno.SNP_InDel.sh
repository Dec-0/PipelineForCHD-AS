#!/bin/bash

## for the annotation of SNP&InDel

# directory for analysing
Dir4Ana=$1
# soft like pepper_deepvariant
Soft=$2
# sp
SP=$3
if [[ ! ${Soft} || ! -d ${Dir4Ana} ||  ! ${SP} ]];then
	echo "[ Error ] Arguments not enough."
fi
# for area filter
# like CHDPanel_Genes.hg38.PromoterGeneBody.nochr.bed
File4Bed=$4
# liek CHDPanel_Genes.hg38.PromoterGeneBody.80kb.nochr.bed
File4BedExtend=$5
Flag4Flt="No"
if [[ ${File4Bed} && -s ${File4Bed} && ${File4BedExtend} && -s ${File4BedExtend} ]];then
	Flag4Flt="Yes"
fi
Dir4SH=`dirname $0`


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
		if [[ ${SoftName} == "bcftools" ]];then
			Soft="~/softs/hap.py-0.3.15/bin/bcftools"
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		elif [[ ${SoftName} == "annovarDB" ]];then
			Soft="~/database/annovar/hg38"
		elif [[ ${SoftName} == "Sif4Annovar" ]];then
			Soft="~/containers/annovar.sif"
		elif [[ ${SoftName} == "perl" ]];then
			Soft="~/softs/perl-5.26.3/bin/perl"
		elif [[ ${SoftName} == "vcfsort" ]];then
			Soft="~/softs/vcftools_0.1.13/bin/vcf-sort"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Bcftools=$(SoftLocate bcftools)
Bin4Tabix=$(SoftLocate tabix)
DB4Annovar=$(SoftLocate annovarDB)
Sif4Annovar=$(SoftLocate Sif4Annovar)
Bin4Perl=$(SoftLocate perl)
Bin4VcfSort=$(SoftLocate vcfsort)
Bin4bgzip=$(SoftLocate bgzip)
Dir4SH=$(dirname $0)


# directory for annotation
Dir4Log="${Dir4Ana}/${Soft}/${SP}/Annotation"
if [[ ! -d ${Dir4Log} ]];then
	echo "[ Info ] Directory for delivery not exist, mkdir it (${Dir4Log})"
	mkdir -p ${Dir4Log}
fi
cd ${Dir4Log}
echo "[ Sample ] ${SP}"

# name format and pass filter
if true;then
	for svtype in snp indel
	do
		File4Vcf="${Dir4Ana}/${Soft}/${SP}/${SP}.${svtype}.vcf"
		if [[ ! -s ${File4Vcf} ]];then
			echo "[ Warning ] File not exit (${File4Vcf})"
			continue
		fi
		
		# name revise
		cat ${File4Vcf} | ${Bin4bgzip} -c > ${Dir4Log}/${SP}.${svtype}.vcf.gz
		File4Vcf="${Dir4Log}/${SP}.${svtype}.vcf.gz"
		echo "${SP}" > ${Dir4Log}/${Soft}.Name.${SP}.txt
		${Bin4Bcftools} reheader -o ${Dir4Log}/${SP}.${Soft}.${svtype}.vcf.gz -s ${Dir4Log}/${Soft}.Name.${SP}.txt ${File4Vcf}
		rm ${Dir4Log}/${Soft}.Name.${SP}.txt ${Dir4Log}/${SP}.${svtype}.vcf.gz
		
		# filter out by coordinate
		if [[ ${Mode4Flt} == "Yes" ]];then
			${Bin4Tabix} -p vcf ${Dir4Log}/${SP}.${Soft}.${svtype}.vcf.gz
			${Bin4Tabix} -h -R ${Bed4FltExtend} -T ${Bed4Flt} ${Dir4Log}/${SP}.${Soft}.${svtype}.vcf.gz | ${Bin4VcfSort} | uniq | ${Bin4bgzip} -c > ${Dir4Log}/${SP}.${Soft}.${svtype}.FltByCoord.vcf.gz
			rm ${Dir4Log}/${SP}.${Soft}.${svtype}.vcf.gz.tbi
			mv ${Dir4Log}/${SP}.${Soft}.${svtype}.FltByCoord.vcf.gz ${Dir4Log}/${SP}.${Soft}.${svtype}.vcf.gz
		fi
	done
fi

# anno single
if true;then
	cd ${Dir4Log}
	
	for svtype in snp indel
	do
		# var uniform
		${Bin4Perl} ${Dir4SH}/Anno.SNP_InDel.Uniform.pl ${Dir4Log}/${SP}.${Soft}.${svtype}.vcf.gz ${Dir4Log}/${SP}.${Soft}.${svtype}.avinput
		
		# annovar
	  anno_list="refGene,cytoband,wgRna,rmsk,genomicSuperDups,cpgIslandExt,esp6500siv2_all,gnomad211_exome,ALL.sites.2015_08,EAS.sites.2015_08,SAS.sites.2015_08,EUR.sites.2015_08,AMR.sites.2015_08,AFR.sites.2015_08,cosmic70,clinvar_20210501,dbnsfp30a"
	  anno_operation="g,r,r,r,r,r,f,f,f,f,f,f,f,f,f,f,f"
	  RootDir4Sif=`echo "${Sif4Annovar}" | cut -d / -f 1,2`
	  RootDir4Log=`echo "${Dir4Log}" | cut -d / -f 1,2`
	  echo "[ RootDir4Sif ] ${RootDir4Sif}"
	  echo "[ RootDir4Log ] ${RootDir4Log}"
		singularity exec -B ${RootDir4Sif}:${RootDir4Sif} -B ${RootDir4Log}:${RootDir4Log} ${Sif4Annovar} table_annovar.pl ${Dir4Log}/${SP}.${Soft}.${svtype}.avinput ${DB4Annovar} --buildver hg38 --outfile ${Dir4Log}/${Soft}.${svtype}.Initial --remove --protocol "${anno_list}" --operation "${anno_operation}" --nastring . --otherinfo
		
		# revise
		${Bin4Perl} ${Dir4SH}/Anno.SNP_InDel.Revise.pl ${Dir4Log}/${SP}.${Soft}.${svtype}.vcf.gz ${Dir4Log}/${Soft}.${svtype}.Initial.hg38_multianno.txt ${Dir4Log}/${Soft}.${svtype}.hg38_multianno.txt
		rm ${Dir4Log}/${SP}.${Soft}.${svtype}.avinput ${Dir4Log}/${Soft}.${svtype}.Initial.hg38_multianno.txt
	done
fi
