#!/bin/bash

## for the annotation of CNV

# directory for analysing
Dir4Ana=$1
# soft like QDNAseq
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
		elif [[ ${SoftName} == "bedtools" ]];then
			Soft="~/softs/bedtools-2.26.0/bin/bedtools"
		elif [[ ${SoftName} == "perl" ]];then
			Soft="~/softs/perl-5.26.3/bin/perl"
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		elif [[ ${SoftName} == "annotSV" ]];then
			Soft="~/software/AnnotSV/bin/AnnotSV"
		elif [[ ${SoftName} == "annotSVDB" ]];then
			Soft="~/software/AnnotSV/db/share/AnnotSV"
		elif [[ ${SoftName} == "python2" ]];then
			Soft="~/softs/Python-2.7.16/bin/python"
		elif [[ ${SoftName} == "annovarDB" ]];then
			Soft="~/database/annovar/hg38"
		elif [[ ${SoftName} == "Sif4Annovar" ]];then
			Soft="~/containers/annovar.sif"
		elif [[ ${SoftName} == "python3" ]];then
			Soft="~/softs/Python-3.7.7/bin/python3"
		elif [[ ${SoftName} == "env4fq" ]];then
			Soft="~/softs/miniconda3/envs/sci"
		elif [[ ${SoftName} == "DB4SV" ]];then
			Soft="~/DB/Annotation/SV_hg38"
		elif [[ ${SoftName} == "vcfsort" ]];then
			Soft="~/softs/vcftools_0.1.13/bin/vcf-sort"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Bcftools=$(SoftLocate bcftools)
Bin4Bedtools=$(SoftLocate bedtools)
Bin4Perl=$(SoftLocate perl)
Bin4Tabix=$(SoftLocate tabix)
Bin4AnnotSV=$(SoftLocate annotSV)
DB4AnnotSV=$(SoftLocate annotSVDB)
Bin4Python2=$(SoftLocate python2)
DB4Annovar=$(SoftLocate annovarDB)
Sif4Annovar=$(SoftLocate Sif4Annovar)
Bin4Python3=$(SoftLocate python3)
DB4SV=$(SoftLocate DB4SV)
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
	File4Vcf="${Dir4Ana}/${Soft}/${SP}/${SP}.${Soft}.vcf.gz"
	if [[ ! -s ${File4Vcf} ]];then
		echo "[ Warning ] File not exit (${File4Vcf})"
		continue
	fi
	
	# name revise
	echo "${SP}" > ${Dir4Log}/${Soft}.Name.${SP}.txt
	${Bin4Bcftools} reheader -o ${Dir4Log}/${SP}.${Soft}.vcf.gz -s ${Dir4Log}/${Soft}.Name.${SP}.txt ${File4Vcf}
	${Bin4Bcftools} view -f PASS -Oz -o ${Dir4Log}/${SP}.${Soft}.PASS.vcf.gz ${Dir4Log}/${SP}.${Soft}.vcf.gz
	
	# filter
	# Format Add. GT:BIN:CN 2*2^LOG2CNT,。不过为了便于统一管理，仍然采用GT:GQ:DR:DV格式，BINS填入DR，CN填入DV
	${Bin4Perl} ${Dir4SH}/Vcf_CNVFormatUniform_v1.0.pl ${Dir4Log}/${SP}.${Soft}.PASS.vcf.gz ${Dir4Log}/${SP}.${Soft}.PASS.Flt.vcf.gz ${Bin4bgzip}
	# filter out by coordinate
	if [[ ${Mode4Flt} == "Yes" ]];then
		${Bin4Tabix} -p vcf ${Dir4Log}/${SP}.${Soft}.PASS.Flt.vcf.gz
		${Bin4Tabix} -h -R ${Bed4FltExtend} -T ${Bed4Flt} ${Dir4Log}/${SP}.${Soft}.PASS.Flt.vcf.gz | ${Bin4VcfSort} | uniq | ${Bin4bgzip} -c > ${Dir4Log}/${SP}.${Soft}.PASS.FltByCoord.vcf.gz
		rm ${Dir4Log}/${SP}.${Soft}.PASS.Flt.vcf.gz.tbi
		mv ${Dir4Log}/${SP}.${Soft}.PASS.FltByCoord.vcf.gz ${Dir4Log}/${SP}.${Soft}.PASS.Flt.vcf.gz
	fi
	
	${Bin4Perl} ${Dir4SH}/Vcf2UniformFormat.pl ${Dir4Log}/${SP}.${Soft}.PASS.Flt.vcf.gz ${Dir4Log}/${SP}.${Soft}.PASS.Flt.Uniform.vcf.gz ${Bin4bgzip}
	${Bin4Tabix} -p vcf ${Dir4Log}/${SP}.${Soft}.PASS.Flt.Uniform.vcf.gz
	rm ${Dir4Log}/${Soft}.Name.${SP}.txt
	rm ${Dir4Log}/${SP}.${Soft}.vcf.gz
	rm ${Dir4Log}/${SP}.${Soft}.PASS.vcf.gz
	rm ${Dir4Log}/${SP}.${Soft}.PASS.Flt.vcf.gz
fi

# anno single
if true;then
	cd ${Dir4Log}
	
	# SVID should have
	source activate $(SoftLocate env4fq)
	zcat ${Dir4Log}/${SP}.${Soft}.PASS.Flt.Uniform.vcf.gz > ${Dir4Log}/${SP}.${Soft}.PASS.Flt.Uniform.vcf
	jasmine file_list="${Dir4Log}/${SP}.${Soft}.PASS.Flt.Uniform.vcf" out_file="${Dir4Log}/${SP}.${Soft}.PASS.Flt.Uniform2.vcf" --comma_filelist --output_genotypes
	rm ${Dir4Log}/${SP}.${Soft}.PASS.Flt.Uniform.vcf
	cat ${Dir4Log}/${SP}.${Soft}.PASS.Flt.Uniform2.vcf | ${Bin4bgzip} -c > ${Dir4Log}/${Soft}.vcf.gz
	rm ${Dir4Log}/${SP}.${Soft}.PASS.Flt.Uniform2.vcf
	${Bin4Tabix} -p vcf ${Dir4Log}/${Soft}.vcf.gz
	conda deactivate
	
	# 1. filter 50bp
	${Bin4AnnotSV} -SVinputFile ${Dir4Log}/${Soft}.vcf.gz -annotationsDir ${DB4AnnotSV} -outputDir ${Dir4Log} -outputFile ${Dir4Log}/${Soft}.AnnotSV.tsv -genomeBuild GRCh38 -SVminSize 50 -bedtools ${Bin4Bedtools} -bcftools ${Bin4Bcftools}
	# 2. annovar
	${Bin4Python2} ${Dir4SH}/jasmine2avinput.py ${Dir4Log}/${Soft}.vcf.gz yes > ${Dir4Log}/${Soft}.avinput
  anno_list="refGene,GeneName,cytoband,wgRna,rmsk,genomicSuperDups,cpgIslandExt"
  anno_operation="g,r,r,r,r,r,r"
  anno_argument="--transcript_function,,,,,,"
  RootDir4Sif=`echo "${Sif4Annovar}" | cut -d / -f 1,2`
  RootDir4Log=`echo "${Dir4Log}" | cut -d / -f 1,2`
  echo "[ RootDir4Sif ] ${RootDir4Sif}"
  echo "[ RootDir4Log ] ${RootDir4Log}"
	singularity exec -B ${RootDir4Sif}:${RootDir4Sif} -B ${RootDir4Log}:${RootDir4Log} ${Sif4Annovar} table_annovar.pl ${Dir4Log}/${Soft}.avinput ${DB4Annovar} --buildver hg38 --outfile ${Dir4Log}/${Soft} --remove --protocol "${anno_list}" --operation "${anno_operation}" --nastring . --argument "${anno_argument}" --otherinfo
	
	# 3. ~/project/FromDirData/sniffles/AnnotSV_reform_V2.py
	${Bin4Python3} ${Dir4SH}/AnnotSV_reform_V2.py ${Dir4Log}/${Soft}.AnnotSV.tsv ${Dir4Log}/${Soft}.AnnotSV.Reform.txt ${DB4SV}
	# 4. ~/project/FromDirData/sniffles/Annovar_Breakpoint_Extract_V2.py
	${Bin4Python3} ${Dir4SH}/Annovar_Breakpoint_Extract_V2.py ${Dir4Log}/${Soft}.hg38_multianno.txt ${Dir4Log}/${Soft}.Breakpoint.txt ${DB4SV}
	# 5. ~/project/FromDirData/sniffles/DECIPHER_CNV_Anno.py
	${Bin4Python3} ${Dir4SH}/DECIPHER_CNV_Anno.py ${Dir4Log}/${Soft}.vcf.gz ${DB4SV}/DECIPHER_CNV.xls ${Dir4Log}/${Soft}.DECIPHER_CNV.txt
	# 6. ~/project/FromDirData/sniffles/DGV_Anno.py
	${Bin4Python3} ${Dir4SH}/DGV_Anno.py ${Dir4Log}/${Soft}.vcf.gz ${DB4SV}/DGV_GRCh38_hg38_variants_2020-02-25.txt ${Dir4Log}/${Soft}.DGV.txt
	# 7. ~/project/FromDirData/sniffles/CHD_Anno.py
	${Bin4Python3} ${Dir4SH}/CHD_Anno_v1.1.py ${Dir4Log}/${Soft}.vcf.gz ${DB4SV}/tableExport.ascii.txt ${Dir4Log}/${Soft}.CHD.AddPerInfo.txt
fi

# anno merge
if true;then
	cd ${Dir4Log}
	# 整合以AnnotSV的结果为基础，所以默认AnnotSV的输出是完整的。从当前的结果来看应该是完整的，除了SVLEN不足50bp的。
	
	# 1 添加起始和结束坐标对应的基因信息
	awk -F '\t' -v OFS='\t' 'BEGIN{NLine="";}{if(NR == FNR){ GN[$1]=$2;NLine="-";for(i = 3;i <= NF;i ++){GN[$1]=GN[$1]"\t"$i;NLine=NLine"\t-"; } }else{TLine=NLine; if(GN[$1]){TLine = GN[$1];};print $0"\t"TLine }}' ${Dir4Log}/${Soft}.Breakpoint.txt ${Dir4Log}/${Soft}.AnnotSV.Reform.txt > ${Dir4Log}/join1.txt
	# 2 添加DECIPHER数据库信息
	awk -F '\t' -v OFS='\t' 'BEGIN{NLine="";}{if(NR == FNR){ GN[$1]=$2;NLine="-";for(i = 3;i <= NF;i ++){GN[$1]=GN[$1]"\t"$i;NLine=NLine"\t-"; } }else{TLine=NLine; if(GN[$1]){TLine = GN[$1];};print $0"\t"TLine }}' ${Dir4Log}/${Soft}.DECIPHER_CNV.txt ${Dir4Log}/join1.txt > ${Dir4Log}/join2.txt
	# 3 添加DGV数据库信息
	awk -F '\t' -v OFS='\t' 'BEGIN{NLine="";}{if(NR == FNR){ GN[$1]=$2;NLine="-";for(i = 3;i <= NF;i ++){GN[$1]=GN[$1]"\t"$i;NLine=NLine"\t-"; } }else{TLine=NLine; if(GN[$1]){TLine = GN[$1];};print $0"\t"TLine }}' ${Dir4Log}/${Soft}.DGV.txt ${Dir4Log}/join2.txt > ${Dir4Log}/join3.txt
	# 3 添加CHD数据库信息
	awk -F '\t' -v OFS='\t' 'BEGIN{NLine="";}{if(NR == FNR){ GN[$1]=$2;NLine="-";for(i = 3;i <= NF;i ++){GN[$1]=GN[$1]"\t"$i;NLine=NLine"\t-"; } }else{TLine=NLine; if(GN[$1]){TLine = GN[$1];};print $0"\t"TLine }}' ${Dir4Log}/${Soft}.CHD.AddPerInfo.txt ${Dir4Log}/join3.txt > ${Dir4Log}/${Soft}.SV.annotations.txt
	rm ${Dir4Log}/join1.txt ${Dir4Log}/join2.txt ${Dir4Log}/join3.txt
	
	cat ${Dir4Log}/${Soft}.SV.annotations.txt | head -n1 > ${Dir4Log}/${Soft}.SV.multisample.annotations.txt
	cat ${Dir4Log}/${Soft}.SV.annotations.txt | sed 1d | awk -F '\t' -v OFS='\t' '{if($2 == "DEL" && $3 > 0){$3 = 0 - $3;};print}' | sort -n -k2 | sort -n -k3 >> ${Dir4Log}/${Soft}.SV.multisample.annotations.txt
fi

# revise for variants filter
# CHD_Anno_v1.0.py or CHD_Anno_v1.1.py
if true;then
	cd ${Dir4Log}
	ln -sf ${Dir4Log}/${Soft}.SV.multisample.annotations.txt ${Dir4Log}/${Soft}.txt
	
	Dir4Excel="${Dir4Log}/Excel"
	if [[ ! -d ${Dir4Excel} ]];then
		mkdir -p ${Dir4Excel}
	fi
	
	# Chrom1 Pos1 Chrome2 Pos2 前移
	Id4Chrom1=`cat ${Dir4Log}/${Soft}.txt | head -n1 | sed 's/\t/\n/g' | awk '{if($1 == "Chrom1"){print NR;exit;}}'`
	Id4Pos1=`cat ${Dir4Log}/${Soft}.txt | head -n1 | sed 's/\t/\n/g' | awk '{if($1 == "Pos1"){print NR;exit;}}'`
	Id4Chrom2=`cat ${Dir4Log}/${Soft}.txt | head -n1 | sed 's/\t/\n/g' | awk '{if($1 == "Chrom2"){print NR;exit;}}'`
	Id4Pos2=`cat ${Dir4Log}/${Soft}.txt | head -n1 | sed 's/\t/\n/g' | awk '{if($1 == "Pos2"){print NR;exit;}}'`
	Id4Pre1=$((${Id4Chrom1} - 1))
	Id4Suf1=$((${Id4Pos1} + 1))
	Id4Pre2=$((${Id4Chrom2} - 1))
	Id4Suf2=$((${Id4Pos2} + 1))
	paste <(cat ${Dir4Log}/${Soft}.txt | cut -f 1-2) <(cat ${Dir4Log}/${Soft}.txt | cut -f ${Id4Chrom1},${Id4Pos1},${Id4Chrom2},${Id4Pos2}) <(cat ${Dir4Log}/${Soft}.txt | cut -f 3-${Id4Pre1},${Id4Suf1}-${Id4Pre2},${Id4Suf2}-) > ${Dir4Log}/${Soft}.ColReOrg.txt
	
	# Delete Smaple_Count and Sample_ID
	Id4SampleCount=`cat ${Dir4Log}/${Soft}.ColReOrg.txt | head -n1 | sed 's/\t/\n/g' | awk '{if($1 == "Sample_Count"){print NR;exit;}}'`
	Id4SampleId=`cat ${Dir4Log}/${Soft}.ColReOrg.txt | head -n1 | sed 's/\t/\n/g' | awk '{if($1 == "Sample_ID"){print NR;exit;}}'`
	Id4SampleCountPre=$((${Id4SampleCount} - 1))
	Id4SampleIdSuf=$((${Id4SampleId} + 1))
	cat ${Dir4Log}/${Soft}.ColReOrg.txt | cut -f 1-${Id4SampleCountPre},${Id4SampleIdSuf}- > ${Dir4Log}/${Soft}.ColReOrg2.txt
	
	# split by SVType
	for SVType in DEL DUP
	do
		cat ${Dir4Log}/${Soft}.ColReOrg2.txt | head -n1 > ${Dir4Excel}/${SVType}
		
		if [[ ${SVType} == "DEL" ]];then
			cat ${Dir4Log}/${Soft}.ColReOrg2.txt | awk -F '\t' -v NType="${SVType}" '{if(NR > 1 && $2 == NType){print}}' | sort -n -k7 >> ${Dir4Excel}/${SVType}
		else
			cat ${Dir4Log}/${Soft}.ColReOrg2.txt | awk -F '\t' -v NType="${SVType}" '{if(NR > 1 && $2 == NType){print}}' | sort -rn -k7 >> ${Dir4Excel}/${SVType}
		fi
	done
	
	${Bin4Python3} ${Dir4SH}/Convert2Excel.v1.1.py -t -i ${Dir4Excel}/DEL -i ${Dir4Excel}/DUP -o ${Dir4Log}/${Soft}.xls
	
	cp ${Dir4Excel}/DEL ${Dir4Log}/CNV_DEL
	cp ${Dir4Excel}/DUP ${Dir4Log}/CNV_DUP
fi
