# for DeepVariant

rule Deepvariant_Calling:
	input:
		bam = "minimap2/{Sample}/{Sample}.sort.bam"
	output:
		vcf = "deepvariant/{Sample}/{Sample}.deepvariant.vcf.gz"
	log:
		stdout = "logs/Deepvariant_Calling.{Sample}." + config["Stamp"] + ".log"
	params:
		basedir = WorkDir,
		Samplename = "{Sample}",
		tmpdir = "deepvariant/{Sample}/tmp",
		logdir = "deepvariant/{Sample}/log",
		refgene = config["Genome"],
		refbed = config["Bed4Panel"],
		rdir = config["RootDir"],
		model = config["Model4Deep"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	shell:
		"""
		{Dir4SF}/scripts/SNP_InDel/DeepVariant.sh {params.basedir}/{input.bam} {params.basedir}/{output.vcf} {params.basedir}/{params.tmpdir} {params.basedir}/{params.logdir} {threads} {params.refgene} {params.refbed} {params.Samplename} {params.rdir} {params.model} > {log.stdout} 2>&1
		"""

rule Deepvariant_select_pass_norm:
	input:
		"deepvariant/{Sample}/{Sample}.deepvariant.vcf.gz"
	output:
		snp = "deepvariant/{Sample}/{Sample}.snp.vcf",
		indel = "deepvariant/{Sample}/{Sample}.indel.vcf"
	params:
		snp = "deepvariant/{Sample}/{Sample}.snp",
		indel = "deepvariant/{Sample}/{Sample}.indel",
		refgen = config["Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/Deepvariant_select_pass_norm.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SNP_InDel/VcfSplitPassAndNorm.sh {input} {output.snp} {output.indel} {params.snp} {params.indel} {params.refgen} > {log.stdout} 2>&1
		"""