#!/bin/bash

# Bam
BamTest=$1
# Male
Gender4Test=$2
# None
BamRef=$3
# ./ExomeDepth.NA24385 which should be with path !!!
FilePrefix=$4
File4Ref=$5
File4BedPrefix=$6
File4PreviousMeanDepthPrefix=$7
File4PreviousReadCountPrefix=$8
# number of threads
NumOfThreads=$9

if [[ ! ${BamTest} || ! ${Gender4Test} || ((! ${BamRef} || ${BamRef} == "-") && (! ${File4PreviousReadCountPrefix} || ! ${File4PreviousMeanDepthPrefix})) || ! ${FilePrefix} || ! ${File4Ref} || ! ${File4BedPrefix} ]];then
	echo "[ Warning ] Not enough argument"
	exit
else
	echo "[ Info ] ExomeDepth begin."
	echo "[ Info ] BamTest: ${BamTest}."
	echo "[ Info ] FilePrefix: ${FilePrefix}."
	echo "[ Info ] File for Ref: ${File4Ref}."
	echo "[ Info ] File prefix for Bed: ${File4BedPrefix}."
	
	if [[ -s ${Gender4Test} ]];then
		tGender4Test=`cat ${Gender4Test} | grep ^Gender | cut -f 4`
		Gender4Test=${tGender4Test}
		echo "[ Info ] Gender4Test: ${Gender4Test}."
	fi
	
	BamList="${BamTest}"
	# if it's a file record bam files
	if [[ ${BamRef} != *.bam && -s ${BamRef} ]];then
		tBamRef=`cat ${BamRef} | sed ':a;N;s/\n/,/g;ba'`
		BamRef="${tBamRef}"
	fi
	echo "[ Info ] BamRef: ${BamRef}."
	if [[ ${BamRef} && ${BamRef} != "-" ]];then
		BamList="${BamList},${BamRef}"
	fi
fi
if [[ ${File4PreviousMeanDepthPrefix} && ${File4PreviousReadCountPrefix} ]];then
	echo "[ Info ] File prefix for Previous MeanDepth: ${File4PreviousMeanDepthPrefix}."
	echo "[ Info ] File prefix for Previous ReadCount: ${File4PreviousReadCountPrefix}."
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
		if [[ ${SoftName} == "bedtools" ]];then
			Soft="~/softs/bedtools-2.26.0/bin/bedtools"
		elif [[ ${SoftName} == "samtools1" ]];then
			Soft="~/softs/samtools-1.14/bin/samtools"
		elif [[ ${SoftName} == "python4" ]];then
			Soft="~/softs/miniconda3/envs/sci/bin/python3"
		elif [[ ${SoftName} == "Rscript1" ]];then
			Soft="~/softs/miniconda3/envs/R36/bin/Rscript"
		elif [[ ${SoftName} == "Rscript2" ]];then
			Soft="~/softs/miniconda3/envs/R42/bin/Rscript"
		elif [[ ${SoftName} == "perl" ]];then
			Soft="~/softs/perl-5.26.3/bin/perl"
		elif [[ ${SoftName} == "tabix" ]];then
			Soft="~/softs/samtools-1.14/bin/tabix"
		elif [[ ${SoftName} == "bgzip" ]];then
			Soft="~/softs/samtools-1.14/bin/bgzip"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Bedtools=$(SoftLocate bedtools)
Bin4Samtools=$(SoftLocate samtools1)
Bin4Python=$(SoftLocate python4)
Bin4Rscript1=$(SoftLocate Rscript1)
Bin4Rscript2=$(SoftLocate Rscript2)
Bin4Perl=$(SoftLocate perl)
Bin4Tabix=$(SoftLocate tabix)
Bin4bgzip=$(SoftLocate bgzip)
Dir4SH=`dirname $0`


#==========================================================
# function
SingleBedThread() {
	local SpecFile4Bed=$1
	local SpecFilePrefix=$2
	local SpecMidFix=$3
	local SpecFile4PreviousMeanDepthPrefix=$4
	local SpecFile4PreviousReadCountPrefix=$5
	
	# GC info on bed area
	${Bin4Bedtools} nuc -fi ${File4Ref} -bed ${SpecFile4Bed} | grep -v ^# | cut -f 1-3,5 | awk -F '\t' -v OFS='\t' '{if(NR == 1){ print "chromosome\tstart\tend\tGC"; }; print $0;}' > ${SpecFilePrefix}.GCInfo.txt
	# format prepare for read count and mean depth
	cp ${SpecFilePrefix}.GCInfo.txt ${SpecFilePrefix}.ReadCount.txt
	cp ${SpecFilePrefix}.GCInfo.txt ${SpecFilePrefix}.MeanDepth.txt
	rm ${SpecFilePrefix}.GCInfo.txt
	
	if [[ ${BamList} ]];then
		for bam in $(echo "${BamList}" | sed 's/,/ /g')
		do
			echo "[ Info ] Processing ${bam}"
			if [[ ! -s ${bam}.bai ]];then
				echo "[ Info ] Index not exist for ${bam}."
				${Bin4Samtools} index -@ ${NumOfThreads} ${bam}
			fi
			tName=`basename ${bam} | sed 's/\.bam$//'`
			
			MinBaseQ=7
			MinMapQ=20
			MinReadLen=200
			
			# Mean Depth
			if [[ ! -s ${SpecFilePrefix}.MeanDepth.${tName}.txt ]];then
				echo "[ Info ] Collecting info of mean depth for ${tName}"
				${Bin4Python} ${Dir4SH}/BinCov_MeanDepth_v1.1.3.py \
					-b ${bam} -r ${SpecFile4Bed} -o ${SpecFilePrefix}.MeanDepth.${tName}.txt -t ${NumOfThreads} -q ${MinBaseQ} -Q ${MinMapQ} -L ${MinReadLen} -p ${SpecFile4Bed}
			fi
			# Merge (需要四舍五入，否则ExomeDepth需要40min)
			awk -F '\t' -v OFS='\t' -v NName="${tName}" '{if(NR == FNR){ GN[$1"\t"$2"\t"$3]=$4; }else{ if(FNR == 1){print $0"\t"NName }else{ MeanDepth="0";if(GN[$1"\t"$2"\t"$3]){MeanDepth = GN[$1"\t"$2"\t"$3];}; MeanDepth = int(MeanDepth + 0.5);print $0"\t"MeanDepth; } }}' ${SpecFilePrefix}.MeanDepth.${tName}.txt ${SpecFilePrefix}.MeanDepth.txt > ${SpecFilePrefix}.MeanDepth.tmp.txt
			mv ${SpecFilePrefix}.MeanDepth.tmp.txt ${SpecFilePrefix}.MeanDepth.txt
			rm ${SpecFilePrefix}.MeanDepth.${tName}.txt
			
			# Read Count
			if [[ ! -s ${SpecFilePrefix}.ReadCount.${tName}.txt ]];then
				echo "[ Info ] Collecting info of read count for ${tName}"
				${Bin4Python} ${Dir4SH}/BinCov_ReadCount_v1.1.py \
					-b ${bam} -r ${SpecFile4Bed} -o ${SpecFilePrefix}.ReadCount.${tName}.txt -t ${NumOfThreads} -q ${MinBaseQ} -Q ${MinMapQ} -L ${MinReadLen}
			fi
			# Merge
			awk -F '\t' -v OFS='\t' -v NName="${tName}" '{if(NR == FNR){ GN[$1"\t"$2"\t"$3]=$4; }else{ if(FNR == 1){print $0"\t"NName }else{ ReadCount="0";if(GN[$1"\t"$2"\t"$3]){ReadCount = GN[$1"\t"$2"\t"$3];}; print $0"\t"ReadCount; } }}' ${SpecFilePrefix}.ReadCount.${tName}.txt ${SpecFilePrefix}.ReadCount.txt > ${SpecFilePrefix}.ReadCount.tmp.txt
			mv ${SpecFilePrefix}.ReadCount.tmp.txt ${SpecFilePrefix}.ReadCount.txt
			rm ${SpecFilePrefix}.ReadCount.${tName}.txt
		done
	fi
	# Merge old and new if old exist
	if [[ ${SpecFile4PreviousMeanDepthPrefix} && -s ${SpecFile4PreviousMeanDepthPrefix}.${SpecMidFix}.txt ]];then
		paste ${SpecFilePrefix}.MeanDepth.txt <(cat ${SpecFile4PreviousMeanDepthPrefix}.${SpecMidFix}.txt | cut -f 5-) > ${SpecFilePrefix}.MeanDepth.tmp.txt
		mv ${SpecFilePrefix}.MeanDepth.tmp.txt ${SpecFilePrefix}.MeanDepth.txt
	fi
	if [[ ${SpecFile4PreviousReadCountPrefix} && -s ${SpecFile4PreviousReadCountPrefix}.${SpecMidFix}.txt ]];then
		paste ${SpecFilePrefix}.ReadCount.txt <(cat ${SpecFile4PreviousReadCountPrefix}.${SpecMidFix}.txt | cut -f 5-) > ${SpecFilePrefix}.ReadCount.tmp.txt
		mv ${SpecFilePrefix}.ReadCount.tmp.txt ${SpecFilePrefix}.ReadCount.txt
	fi
	# check if file was intact
	if true;then
		ColNumConsistent=`cat ${SpecFilePrefix}.ReadCount.txt | awk '{print NF}' | uniq | wc -l`
		if [[ ${ColNumConsistent} > 1 ]];then
			echo "[ Error ] Column number not consistent for file ${SpecFilePrefix}.ReadCount.txt"
			exit
		fi
		
		Flag4Header=`cat ${SpecFilePrefix}.ReadCount.txt | head -n1 | awk -F '\t' '{if($1 == "chromosome" && $2 == "start" && $3 == "end" && $4 == "GC"){print "Yes";}else{print "No";}}'`
		if [[ ${Flag4Header} == "No" ]];then
			echo "[ Error ] Header item not correct for file ${SpecFilePrefix}.ReadCount.txt"
			exit
		fi
	fi

	echo "[ Info ] Begin ExomeDepth CNV calling"
	# argument for run_ExomeDepth
	TransProb="0.0001"
	
	${Bin4Rscript2} ${Dir4SH}/run_ExomeDepth_v1.0_revisedClass.r \
		--readcount ${SpecFilePrefix}.MeanDepth.txt \
		--prefix ${SpecFilePrefix}.MeanDepth.ExomeDepth \
		--prob ${TransProb}

	${Bin4Rscript2} ${Dir4SH}/run_ExomeDepth_v1.0_revisedClass.r \
		--readcount ${SpecFilePrefix}.ReadCount.txt \
		--prefix ${SpecFilePrefix}.ReadCount.ExomeDepth \
		--prob ${TransProb}
}
FltTargetSPFromRef() {
	local SpecFile4Ori=$1
	local SpecFile4Flt=$2
	local SpecSP=$3

	Id4Target=`cat ${SpecFile4Ori} | head -n1 | sed 's/\t/\n/g' | awk -F '\t' -v NSP="${SpecSP}" '{if($1 == NSP){print NR;exit;}}' 2>/dev/null`
	if [[ ${Id4Target} ]];then
		Id4NoTarget=`cat ${SpecFile4Ori} | head -n1 | sed 's/\t/\n/g' | awk -F '\t' -v NSP="${SpecSP}" '{if($1 != NSP){print NR;}}' | sed ':a;N;s/\n/,/g;ba'`
		echo "[ Info ] Filter ${SpecSP} from file, cut string is ${Id4NoTarget}"
		cat ${SpecFile4Ori} | cut -f ${Id4NoTarget} > ${SpecFile4Flt}
	else
		echo "[ Info ] ${SpecSP} not found from previous file"
		cp ${SpecFile4Ori} ${SpecFile4Flt}
	fi
}


# Begin
Dir=`dirname ${FilePrefix}`
if [[ ! -d ${Dir} ]];then
	mkdir -p ${Dir}
fi
cd ${Dir}

date
SPName=`basename ${BamTest} | cut -d '.' -f 1`

#==========================================================
# if female, compare to chr1~X
if [[ ${Gender4Test} == "Female" ]];then
	# chr1~X
	echo "[ Info ] Begin processing chr1_X"
	if [[ -s ${File4PreviousMeanDepthPrefix}.chr1_X.txt ]];then
		echo "[ Info ] Filter ${SPName} from previous MeanDepth chr1_X info."
		FltTargetSPFromRef ${File4PreviousMeanDepthPrefix}.chr1_X.txt ${FilePrefix}.PreviousRefMeanDepth.chr1_X.txt ${SPName}
	fi
	if [[ -s ${File4PreviousReadCountPrefix}.chr1_X.txt ]];then
		echo "[ Info ] Filter ${SPName} from previous ReadCount chr1_X info."
		FltTargetSPFromRef ${File4PreviousReadCountPrefix}.chr1_X.txt ${FilePrefix}.PreviousRefReadCount.chr1_X.txt ${SPName}
	fi
	SingleBedThread ${File4BedPrefix}.${Gender4Test}.chr1_X.bed ${FilePrefix}.chr1_X chr1_X ${FilePrefix}.PreviousRefMeanDepth ${FilePrefix}.PreviousRefReadCount

	for tag in ReadCount MeanDepth
	do
		cp ${FilePrefix}.chr1_X.${tag}.ExomeDepth.txt ${FilePrefix}.${tag}.ExomeDepth.txt
		cp ${FilePrefix}.chr1_X.${tag}.ExomeDepth.TestCount.txt ${FilePrefix}.${tag}.ExomeDepth.TestCount.txt
		cp ${FilePrefix}.chr1_X.${tag}.ExomeDepth.RelativeCount.txt ${FilePrefix}.${tag}.ExomeDepth.RelativeCount.txt
		cp ${FilePrefix}.chr1_X.${tag}.txt ${FilePrefix}.${tag}.txt

		rm ${FilePrefix}.chr1_X.${tag}.ExomeDepth.txt ${FilePrefix}.chr1_X.${tag}.ExomeDepth.TestCount.txt ${FilePrefix}.chr1_X.${tag}.ExomeDepth.RelativeCount.txt
	done
# if male, compare to chr1~22 chrX~Y
elif [[ ${Gender4Test} == "Male" ]];then
	# chr1~22
	echo "[ Info ] Begin processing chr1_22"
	if [[ -s ${File4PreviousMeanDepthPrefix}.chr1_22.txt ]];then
		echo "[ Info ] Filter ${SPName} from previous MeanDepth chr1_22 info."
		FltTargetSPFromRef ${File4PreviousMeanDepthPrefix}.chr1_22.txt ${FilePrefix}.PreviousRefMeanDepth.chr1_22.txt ${SPName}
	fi
	if [[ -s ${File4PreviousReadCountPrefix}.chr1_22.txt ]];then
		echo "[ Info ] Filter ${SPName} from previous ReadCount chr1_22 info."
		FltTargetSPFromRef ${File4PreviousReadCountPrefix}.chr1_22.txt ${FilePrefix}.PreviousRefReadCount.chr1_22.txt ${SPName}
	fi
	SingleBedThread ${File4BedPrefix}.${Gender4Test}.chr1_22.bed ${FilePrefix}.chr1_22 chr1_22 ${FilePrefix}.PreviousRefMeanDepth ${FilePrefix}.PreviousRefReadCount
	# chrX~chrY
	echo "[ Info ] Begin processing chrX_Y"
	if [[ -s ${File4PreviousMeanDepthPrefix}.chrX_Y.txt ]];then
		echo "[ Info ] Filter ${SPName} from previous MeanDepth chrX_Y info."
		FltTargetSPFromRef ${File4PreviousMeanDepthPrefix}.chrX_Y.txt ${FilePrefix}.PreviousRefMeanDepth.chrX_Y.txt ${SPName}
	fi
	if [[ -s ${File4PreviousReadCountPrefix}.chrX_Y.txt ]];then
		echo "[ Info ] Filter ${SPName} from previous ReadCount chrX_Y info."
		FltTargetSPFromRef ${File4PreviousReadCountPrefix}.chrX_Y.txt ${FilePrefix}.PreviousRefReadCount.chrX_Y.txt ${SPName}
	fi
	SingleBedThread ${File4BedPrefix}.${Gender4Test}.chrX_Y.bed ${FilePrefix}.chrX_Y chrX_Y ${FilePrefix}.PreviousRefMeanDepth ${FilePrefix}.PreviousRefReadCount
	
	for tag in ReadCount MeanDepth
	do
		cp ${FilePrefix}.chr1_22.${tag}.ExomeDepth.txt ${FilePrefix}.${tag}.ExomeDepth.txt
		cat ${FilePrefix}.chrX_Y.${tag}.ExomeDepth.txt | sed 1d >> ${FilePrefix}.${tag}.ExomeDepth.txt
	
		cp ${FilePrefix}.chr1_22.${tag}.ExomeDepth.TestCount.txt ${FilePrefix}.${tag}.ExomeDepth.TestCount.txt
		cat ${FilePrefix}.chrX_Y.${tag}.ExomeDepth.TestCount.txt | sed 1d >> ${FilePrefix}.${tag}.ExomeDepth.TestCount.txt

		cp ${FilePrefix}.chr1_22.${tag}.ExomeDepth.RelativeCount.txt ${FilePrefix}.${tag}.ExomeDepth.RelativeCount.txt
		cat ${FilePrefix}.chrX_Y.${tag}.ExomeDepth.RelativeCount.txt | sed 1d >> ${FilePrefix}.${tag}.ExomeDepth.RelativeCount.txt

		cp ${FilePrefix}.chr1_22.${tag}.txt ${FilePrefix}.${tag}.txt
		cat ${FilePrefix}.chrX_Y.${tag}.txt | sed 1d >> ${FilePrefix}.${tag}.txt

		rm ${FilePrefix}.chr1_22.${tag}.ExomeDepth.txt ${FilePrefix}.chr1_22.${tag}.ExomeDepth.TestCount.txt ${FilePrefix}.chr1_22.${tag}.ExomeDepth.RelativeCount.txt
		rm ${FilePrefix}.chrX_Y.${tag}.ExomeDepth.txt ${FilePrefix}.chrX_Y.${tag}.ExomeDepth.TestCount.txt ${FilePrefix}.chrX_Y.${tag}.ExomeDepth.RelativeCount.txt
	done
# others
else
	echo "[ Error ] Unknown gender ${Gender4Test}"
	exit
fi

#==========================================================
echo "[ Info ] Map draw"
for midfix in "ReadCount.ExomeDepth" "MeanDepth.ExomeDepth"
do
	cat ${FilePrefix}.${midfix}.TestCount.txt | head -n1 > ${FilePrefix}.${midfix}.TestCount.Sort.txt
	cat ${FilePrefix}.${midfix}.TestCount.txt | sed 1d | grep -v ^X | grep -v ^Y | sort -n -k1 -k2 >> ${FilePrefix}.${midfix}.TestCount.Sort.txt
	cat ${FilePrefix}.${midfix}.TestCount.txt | sed 1d | grep ^X | sort -n -k2 >> ${FilePrefix}.${midfix}.TestCount.Sort.txt
	cat ${FilePrefix}.${midfix}.TestCount.txt | sed 1d | grep ^Y | sort -n -k2 >> ${FilePrefix}.${midfix}.TestCount.Sort.txt
	${Bin4Rscript1} ${Dir4SH}/ReadCountDot_v1.0.r ${FilePrefix}.${midfix}.TestCount.pdf 15 4 1 1 ${FilePrefix}.${midfix}.TestCount.Sort.txt '' 'chromosome' 'Read Count' -

	cat ${FilePrefix}.${midfix}.RelativeCount.txt | head -n1 > ${FilePrefix}.${midfix}.RelativeCount.Sort.txt
	cat ${FilePrefix}.${midfix}.RelativeCount.txt | sed 1d | grep -v ^X | grep -v ^Y | sort -n -k1 -k2 >> ${FilePrefix}.${midfix}.RelativeCount.Sort.txt
	cat ${FilePrefix}.${midfix}.RelativeCount.txt | sed 1d | grep ^X | sort -n -k2 >> ${FilePrefix}.${midfix}.RelativeCount.Sort.txt
	cat ${FilePrefix}.${midfix}.RelativeCount.txt | sed 1d | grep ^Y | sort -n -k2 >> ${FilePrefix}.${midfix}.RelativeCount.Sort.txt
	${Bin4Rscript1} ${Dir4SH}/ReadCountDot_v1.0.r ${FilePrefix}.${midfix}.RelativeCount.pdf 15 4 1 1 ${FilePrefix}.${midfix}.RelativeCount.Sort.txt '' 'chromosome' 'Relative Read Count' -
done

#==========================================================
echo "[ Info ] Vcf convert"
${Bin4Perl} ${Dir4SH}/ExomeDepth_Convert2Vcf_v1.0.pl \
	${FilePrefix}.ReadCount.ExomeDepth.txt \
	${FilePrefix}.ExomeDepth.vcf.gz \
	${Bin4bgzip}
${Bin4Tabix} -p vcf -f ${FilePrefix}.ExomeDepth.vcf.gz

date
