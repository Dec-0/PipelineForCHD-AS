# for sniffles2

rule Sniffles_Calling:
	input:
		"minimap2/{Sample}/{Sample}.sort.bam",
	output:
		"sniffles/{Sample}/{Sample}.sniffles.all.vcf.gz"
	params:
		genome = config["Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/Sniffles_Calling.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SV/Sniffles2.sh {input} {output} {params.genome} 50 {threads} > {log.stdout} 2>&1
		"""

rule Sniffles_Filter:
	input:
		"sniffles/{Sample}/{Sample}.sniffles.all.vcf.gz",
	output:
		"sniffles/{Sample}/{Sample}.sniffles.vcf.gz",
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/Sniffles_Filter.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SV/SVVcfFilter.sh {input} {output} > {log.stdout} 2>&1
		"""