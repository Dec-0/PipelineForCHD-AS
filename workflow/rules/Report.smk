# for Report generation

rule Report_QC:
	input:
		qc = "QC/{Sample}/{Sample}.PanelStat.txt",
		gender = "QC/{Sample}/{Sample}.GenderInfo.txt"
	output:
		qc = "Report/{Sample}/{Sample}.QC.xls"
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		2
	log:
		stdout = "logs/Report_QC.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Report/Report.sh {output.qc} - - - {input.qc} {input.gender} - - - - - - - - - - - > {log.stdout} 2>&1
		"""

rule Report_SNPInDel:
	input:
		snp = "pepper_deepvariant/{Sample}/Annotation/pepper_deepvariant.snp.hg38_multianno.txt",
		indel = "pepper_deepvariant/{Sample}/Annotation/pepper_deepvariant.indel.hg38_multianno.txt"
	output:
		snpindel = "Report/{Sample}/{Sample}.SNP_InDel.xls"
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		2
	log:
		stdout = "logs/Report_SNPInDel.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Report/Report.sh - {output.snpindel} - - - - {input.snp} {input.indel} - - - - - - - - - > {log.stdout} 2>&1
		"""

rule Report_SV:
	input:
		sv_del = "FinalSV/{Sample}/Annotation/SV_DEL",
		sv_ins = "FinalSV/{Sample}/Annotation/SV_INS",
		sv_dup = "FinalSV/{Sample}/Annotation/SV_DUP",
		sv_inv = "FinalSV/{Sample}/Annotation/SV_INV",
		sv_tra = "FinalSV/{Sample}/Annotation/SV_TRA"
	output:
		sv = "Report/{Sample}/{Sample}.SV.xls"
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		2
	log:
		stdout = "logs/Report_SV.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Report/Report.sh - - {output.sv} - - - - - {input.sv_del} {input.sv_ins} {input.sv_dup} {input.sv_inv} {input.sv_tra} - - - - > {log.stdout} 2>&1
		"""

def Input4CNV(wildcards):
	FileList = ["QDNAseq/{Sample}/Annotation/CNV_DEL","QDNAseq/{Sample}/Annotation/CNV_DUP"]
	if str(config["Flag4CNV_On"]) == "Yes":
		FileList.append("ExomeDepth/{Sample}/Annotation/CNV_DEL")
		FileList.append("ExomeDepth/{Sample}/Annotation/CNV_DUP")
	
	return FileList

rule Report_CNV:
	input:
		unpack(Input4CNV)
	output:
		cnv = "Report/{Sample}/{Sample}.CNV.xls"
	resources:
		tmpdir = WorkDir + "/.tmp"
	params:
		cnv_on_del = "ExomeDepth/{Sample}/Annotation/CNV_DEL",
		cnv_on_dup = "ExomeDepth/{Sample}/Annotation/CNV_DUP",
		cnv_off_del = "QDNAseq/{Sample}/Annotation/CNV_DEL",
		cnv_off_dup = "QDNAseq/{Sample}/Annotation/CNV_DUP"
	threads:
		2
	log:
		stdout = "logs/Report_CNV.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Report/Report.sh - - - {output.cnv} - - - - - - - - - {params.cnv_on_del} {params.cnv_on_dup} {params.cnv_off_del} {params.cnv_off_dup} > {log.stdout} 2>&1
		"""