# for cuteSV

rule cuteSV_Calling:
	input:
		"minimap2/{Sample}/{Sample}.sort.bam"
	output:
		initial = "cuteSV/{Sample}/{Sample}.cuteSV.all.vcf.gz",
		adddr = "cuteSV/{Sample}/{Sample}.cuteSV.all.AddDR.vcf.gz"
	params:
		sp = "{Sample}",
		genome = config["Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/cuteSV_Calling.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SV/cuteSV.sh {input} {output.initial} {threads} {params.genome} {params.sp} > {log.stdout} 2>&1
		"""

rule cuteSV_Filter:
	input:
		"cuteSV/{Sample}/{Sample}.cuteSV.all.AddDR.vcf.gz"
	output:
		"cuteSV/{Sample}/{Sample}.cuteSV.vcf.gz"
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/cuteSV_Filter.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SV/SVVcfFilter.sh {input} {output} > {log.stdout} 2>&1
		"""