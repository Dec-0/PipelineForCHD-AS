#!/bin/bash

# for report of snp, indel, sv, and cnv

File4ReportQC=$1
File4ReportSNP_InDel=$2
File4ReportSV=$3
File4ReportCNV=$4
File4QC=$5
File4Gender=$6
File4SNP=$7
File4InDel=$8
File4SV_DEL=$9
File4SV_INS=${10}
File4SV_DUP=${11}
File4SV_INV=${12}
File4SV_TRA=${13}
File4CNV_On_DEL=${14}
File4CNV_On_DUP=${15}
File4CNV_Off_DEL=${16}
File4CNV_Off_DUP=${17}

if [[ ! -s ${File4QC} || ! -s ${File4Gender} || ! -s ${File4SNP} || ! -s ${File4InDel} || ! -s ${File4SV_DEL} || ! -s ${File4SV_INS} || ! -s ${File4SV_DUP} || ! -s ${File4SV_INV} || ! -s ${File4SV_TRA} || ! -s ${File4CNV_On_DEL} || ! -s ${File4CNV_On_DUP} || ! -s ${File4CNV_Off_DEL} || ! -s ${File4CNV_Off_DUP} ]];then
	echo "[ Warning ] Some file not exist."
	echo "QC: ${File4QC}"
	echo "Gender: ${File4Gender}"
	echo "SNP: ${File4SNP}"
	echo "InDel: ${File4InDel}"
	echo "SV_DEL: ${File4SV_DEL}"
	echo "SV_INS: ${File4SV_INS}"
	echo "SV_DUP: ${File4SV_DUP}"
	echo "SV_INV: ${File4SV_INV}"
	echo "SV_TRA: ${File4SV_TRA}"
	echo "CNV_On_DEL: ${File4CNV_On_DEL}"
	echo "CNV_On_DUP: ${File4CNV_On_DUP}"
	echo "CNV_Off_DEL: ${File4CNV_Off_DEL}"
	echo "CNV_Off_DUP: ${File4CNV_Off_DUP}"
	for fs in "${File4QC}" "${File4Gender}" "${File4SNP}" "${File4InDel}" "${File4SV_DEL}" "${File4SV_INS}" "${File4SV_DUP}" "${File4SV_INV}" "${File4SV_TRA}" "${File4CNV_On_DEL}" "${File4CNV_On_DUP}" "${File4CNV_Off_DEL}" "${File4CNV_Off_DUP}"
	do
		if [[ ! -s ${fs} ]];then
			echo "[ Warning ] File not exist (${fs})"
		fi
	done
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
		if [[ ${SoftName} == "python3" ]];then
			Soft="~/softs/Python-3.7.7/bin/python3"
		fi
	fi
	
	echo "${Soft}"
}
Bin4Python3=$(SoftLocate python3)
Dir4SH=$(dirname $0)


Dir4Report=""
if [[ ${File4ReportQC} && ${File4ReportQC} != "-" ]];then
	Dir4Report=`dirname ${File4ReportQC}`
elif [[ ${File4ReportSNP_InDel} && ${File4ReportSNP_InDel} != "-" ]];then
	Dir4Report=`dirname ${File4ReportSNP_InDel}`
elif [[ ${File4ReportSV} && ${File4ReportSV} != "-" ]];then
	Dir4Report=`dirname ${File4ReportSV}`
elif [[ ${File4ReportCNV} && ${File4ReportCNV} != "-" ]];then
	Dir4Report=`dirname ${File4ReportCNV}`
fi
if [[ ! -d ${Dir4Report} ]];then
	mkdir -p ${Dir4Report}
fi

if [[ -s ${File4QC} && -s ${File4Gender} ]];then
	cp ${File4QC} ${Dir4Report}/QC
	cat ${File4Gender} | grep ^Gender | cut -f 1,4 | awk -F '\t' '{print $1":\t"$2 }' >> ${Dir4Report}/QC
	${Bin4Python3} ${Dir4SH}/../Annotation/Convert2Excel.v1.1.py -t -i ${Dir4Report}/QC -o ${File4ReportQC}
	rm ${Dir4Report}/QC
fi

if [[ -s ${File4SNP} && -s ${File4InDel} ]];then
	cp ${File4SNP} ${Dir4Report}/SNP
	cp ${File4InDel} ${Dir4Report}/InDel
	${Bin4Python3} ${Dir4SH}/../Annotation/Convert2Excel.v1.1.py -t -i ${Dir4Report}/SNP -i ${Dir4Report}/InDel -o ${File4ReportSNP_InDel}
	rm ${Dir4Report}/SNP ${Dir4Report}/InDel
fi

if [[ -s ${File4SV_DEL} && -s ${File4SV_INS} && -s ${File4SV_DUP} && -s ${File4SV_INV} && -s ${File4SV_TRA} ]];then
	cp ${File4SV_DEL} ${Dir4Report}/SV_DEL
	cp ${File4SV_INS} ${Dir4Report}/SV_INS
	cp ${File4SV_DUP} ${Dir4Report}/SV_DUP
	cp ${File4SV_INV} ${Dir4Report}/SV_INV
	cp ${File4SV_TRA} ${Dir4Report}/SV_TRA_BND
	${Bin4Python3} ${Dir4SH}/../Annotation/Convert2Excel.v1.1.py -t -i ${Dir4Report}/SV_DEL -i ${Dir4Report}/SV_INS -i ${Dir4Report}/SV_DUP -i ${Dir4Report}/SV_INV -i ${Dir4Report}/SV_TRA_BND -o ${File4ReportSV}
	rm ${Dir4Report}/SV_DEL ${Dir4Report}/SV_INS ${Dir4Report}/SV_DUP ${Dir4Report}/SV_INV ${Dir4Report}/SV_TRA_BND
fi

if [[ -s ${File4CNV_On_DEL} && -s ${File4CNV_On_DUP} && -s ${File4CNV_Off_DEL} && -s ${File4CNV_Off_DUP} ]];then
	cp ${File4CNV_On_DEL} ${Dir4Report}/CNV_OnTarget_DEL
	cp ${File4CNV_On_DUP} ${Dir4Report}/CNV_OnTarget_DUP
	cp ${File4CNV_Off_DEL} ${Dir4Report}/CNV_OffTarget_DEL
	cp ${File4CNV_Off_DUP} ${Dir4Report}/CNV_OffTarget_DUP
	${Bin4Python3} ${Dir4SH}/../Annotation/Convert2Excel.v1.1.py -t -i ${Dir4Report}/CNV_OnTarget_DEL -i ${Dir4Report}/CNV_OnTarget_DUP -i ${Dir4Report}/CNV_OffTarget_DEL -i ${Dir4Report}/CNV_OffTarget_DUP -o ${File4ReportCNV}
	rm ${Dir4Report}/CNV_OnTarget_DEL ${Dir4Report}/CNV_OnTarget_DUP ${Dir4Report}/CNV_OffTarget_DEL ${Dir4Report}/CNV_OffTarget_DUP
elif [[ -s ${File4CNV_Off_DEL} && -s ${File4CNV_Off_DUP} ]];then
	cp ${File4CNV_Off_DEL} ${Dir4Report}/CNV_OffTarget_DEL
	cp ${File4CNV_Off_DUP} ${Dir4Report}/CNV_OffTarget_DUP
	${Bin4Python3} ${Dir4SH}/../Annotation/Convert2Excel.v1.1.py -t -i ${Dir4Report}/CNV_OffTarget_DEL -i ${Dir4Report}/CNV_OffTarget_DUP -o ${File4ReportCNV}
	rm ${Dir4Report}/CNV_OffTarget_DEL ${Dir4Report}/CNV_OffTarget_DUP
fi
