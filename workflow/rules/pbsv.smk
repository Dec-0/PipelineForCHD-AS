# for pbsv

rule pbsv_Calling:
	input:
		"pbmm2/{Sample}/{Sample}.sort.bam"
	output:
		"pbsv/{Sample}/{Sample}.pbsv.all.vcf.gz"
	params:
		sp = "{Sample}",
		genome = config["Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/pbsv_Calling.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SV/pbsv.sh {input} {output} {threads} {params.genome} {params.sp} > {log.stdout} 2>&1
		"""

rule pbsv_Filter:
	input:
		"pbsv/{Sample}/{Sample}.pbsv.all.vcf.gz"
	output:
		"pbsv/{Sample}/{Sample}.pbsv.vcf.gz"
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/pbsv_Filter.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SV/SVVcfFilter.sh {input} {output} > {log.stdout} 2>&1
		"""