# for clair3

rule Clair3_Calling:
	input:
		"minimap2/{Sample}/{Sample}.sort.bam"
	output:
		"clair3/{Sample}/{Sample}.clair3.vcf.gz"
	params:
		name = "{Sample}",
		odir = "clair3/{Sample}",
		bed = config["Bed4Panel"],
		model = config["Model4Clair3"],
		genome = config["Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		20
	log:
		stdout = "logs/Clair3_Calling.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SNP_InDel/Clair3.sh {params.odir} {input} {params.bed} {params.genome} {threads} {params.model} {output} {params.name} > {log.stdout} 2>&1
		"""

rule Clair3_select_pass_norm:
	input:
		"clair3/{Sample}/{Sample}.clair3.vcf.gz"
	output:
		snp = "clair3/{Sample}/{Sample}.snp.vcf",
		indel = "clair3/{Sample}/{Sample}.indel.vcf"
	params:
		snp = "clair3/{Sample}/{Sample}.snp",
		indel = "clair3/{Sample}/{Sample}.indel",
		refgen = config["Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/Clair3_select_pass_norm.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SNP_InDel/VcfSplitPassAndNorm.sh {input} {output.snp} {output.indel} {params.snp} {params.indel} {params.refgen} > {log.stdout} 2>&1
		"""