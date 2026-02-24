# for fq mapping

rule minimap2:
	input:
		"raw/{Sample}/FqList.txt"
	output:
		"minimap2/{Sample}/{Sample}.sort.bam"
	params:
		odir = "minimap2/{Sample}/tmp",
		genome = config["Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		20
	log:
		stdout = "logs/minimap2.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Map/Minimap2.sh {params.odir} {threads} {input} {output} {params.genome} > {log.stdout} 2>&1
		"""

rule pbmm2:
	input:
		"raw/{Sample}/FqList.txt"
	output:
		"pbmm2/{Sample}/{Sample}.sort.bam"
	params:
		sp = "{Sample}",
		genome = config["Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		20
	log:
		stdout = "logs/pbmm2.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Map/pbmm2.sh {params.sp} {threads} {input} {output} {params.genome} > {log.stdout} 2>&1
		"""