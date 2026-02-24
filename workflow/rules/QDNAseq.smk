# for QDNAseq

rule QDNAseq_Calling:
	input:
		bam = "minimap2/{Sample}/{Sample}.sort.bam",
		geninfo = "QC/{Sample}/{Sample}.GenderInfo.txt"
	output:
		"QDNAseq/{Sample}/{Sample}.QDNAseq.Original.vcf.gz"
	params:
		basedir = WorkDir,
		bed = config["Bed4Panel"],
		prefix = "QDNAseq/{Sample}/{Sample}.QDNAseq",
		bininfo = config["BinInfo4QDNAseq"],
		gtype = config["GenType"],
		binsize = config["CNVBin"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		5
	log:
		stdout = "logs/QDNAseq_Calling.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/CNV/QDNAseq_Panel.sh {params.basedir}/{input.bam} {params.basedir}/{input.geninfo} {params.bed} {params.basedir}/{params.prefix} {params.gtype} {params.binsize} {params.basedir}/{output} {params.bininfo} > {log.stdout} 2>&1
		"""

rule QDNAseq_GenderFlt:
	input:
		vcf = "QDNAseq/{Sample}/{Sample}.QDNAseq.Original.vcf.gz",
		gender = "QC/{Sample}/{Sample}.GenderInfo.txt"
	output:
		"QDNAseq/{Sample}/{Sample}.QDNAseq.vcf.gz"
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		2
	log:
		stdout = "logs/QDNAseq_GenderFlt.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/CNV/QDNAseq_Panel_GenderFlt.sh {input.vcf} {output} {input.gender} > {log.stdout} 2>&1
		"""

rule QDNAseq_Anno:
	input:
		"QDNAseq/{Sample}/{Sample}.QDNAseq.vcf.gz"
	output:
		merge = "QDNAseq/{Sample}/Annotation/QDNAseq.xls",
		cnv_del = "QDNAseq/{Sample}/Annotation/CNV_DEL",
		cnv_dup = "QDNAseq/{Sample}/Annotation/CNV_DUP"
	params:
		sp = "{Sample}",
		basedir = WorkDir
	threads:
		2
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/QDNAseq_Anno.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Annotation/Anno.CNV.sh {params.basedir} QDNAseq {params.sp} > {log.stdout} 2>&1
		"""