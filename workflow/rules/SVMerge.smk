# for the merge of sv calling result from diff softs

rule FinalSV_Overlap:
	input:
		"cuteSV/{Sample}/{Sample}.cuteSV.vcf.gz",
		"sniffles/{Sample}/{Sample}.sniffles.vcf.gz",
		"pbsv/{Sample}/{Sample}.pbsv.vcf.gz",
		"debreak/{Sample}/{Sample}.debreak.vcf.gz"
	output:
		"SV_Overlap/{Sample}/truvari.stat.txt"
	params:
		sp = "{Sample}",
		RDir = "./",
		LDir = "./SV_Overlap/{Sample}"
	threads:
		2
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/FinalSV_Overlap.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SV/SV_Overlap.sh {params.RDir} {params.LDir} {params.sp} "cuteSV,sniffles,pbsv,debreak" > {log.stdout} 2>&1
		"""

rule FinalSV_Merge:
	input:
		"SV_Overlap/{Sample}/truvari.stat.txt"
	output:
		"FinalSV/{Sample}/{Sample}.FinalSV.vcf.gz"
	params:
		sp = "{Sample}",
		RDir = "./SV_Overlap/{Sample}",
		LDir = "./FinalSV/{Sample}"
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/FinalSV_Merge.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SV/FinalSV2.sh {params.RDir} {params.LDir} {params.sp} "cuteSV,sniffles,pbsv,debreak" > {log.stdout} 2>&1
		"""

rule FinalSV_Anno:
	input:
		"FinalSV/{Sample}/{Sample}.FinalSV.vcf.gz"
	output:
		merge = "FinalSV/{Sample}/Annotation/FinalSV.xls",
		sv_del = "FinalSV/{Sample}/Annotation/SV_DEL",
		sv_dup = "FinalSV/{Sample}/Annotation/SV_DUP",
		sv_ins = "FinalSV/{Sample}/Annotation/SV_INS",
		sv_inv = "FinalSV/{Sample}/Annotation/SV_INV",
		sv_tra = "FinalSV/{Sample}/Annotation/SV_TRA"
	params:
		sp = "{Sample}",
		basedir = WorkDir,
		bed = config["Bed4Panel"],
		bedextend = config["Bed4PanelExtend"]
	threads:
		2
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/FinalSV_Anno.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Annotation/Anno.SV.sh {params.basedir} FinalSV {params.sp} {params.bed} {params.bedextend} > {log.stdout} 2>&1
		"""