# for debreak

rule Debreak_Calling:
	input:
		"minimap2/{Sample}/{Sample}.sort.bam"
	output:
		ori = "debreak/{Sample}/{Sample}.debreak.all.vcf.gz",
		dp = "debreak/{Sample}/{Sample}.debreak.all.AddDP.vcf.gz"
	params:
		genome = config["Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/Debreak_Calling.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SV/debreak.sh {input} {output.ori} {params.genome} 50 {threads} > {log.stdout} 2>&1
		"""

rule Debreak_Filter:
	input:
		"debreak/{Sample}/{Sample}.debreak.all.AddDP.vcf.gz"
	output:
		"debreak/{Sample}/{Sample}.debreak.vcf.gz"
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/Debreak_Filter.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SV/SVVcfFilter.sh {input} {output} > {log.stdout} 2>&1
		"""