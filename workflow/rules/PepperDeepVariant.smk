# for PepperDeepVariant

rule PepperDeepvariant_Calling:
	input:
		bam = "minimap2/{Sample}/{Sample}.sort.bam"
	output:
		vcf = "pepper_deepvariant/{Sample}/{Sample}.pepper_deepvariant.vcf.gz"
	log:
		stdout = "logs/PepperDeepvariant_Calling.{Sample}." + config["Stamp"] + ".log"
	params:
		basedir = WorkDir,
		Samplename = "{Sample}",
		odir = "pepper_deepvariant/{Sample}",
		refgene = config["Genome"],
		bed = config["Bed4Panel"],
		rdir = config["RootDir"],
		model = config["Model4Pepper"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	shell:
		"""
		{Dir4SF}/scripts/SNP_InDel/Pepper_Margin_DeepVariant.sh {params.basedir}/{input.bam} {params.basedir}/{params.odir} {params.Samplename}.pepper_deepvariant {threads} {params.refgene} {params.Samplename} {params.bed} {params.rdir} {params.model} > {log.stdout} 2>&1
		"""

rule PepperDeepvariant_select_pass_norm:
	input:
		"pepper_deepvariant/{Sample}/{Sample}.pepper_deepvariant.vcf.gz"
	output:
		snp = "pepper_deepvariant/{Sample}/{Sample}.snp.vcf",
		indel = "pepper_deepvariant/{Sample}/{Sample}.indel.vcf"
	params:
		snp = "pepper_deepvariant/{Sample}/{Sample}.snp",
		indel = "pepper_deepvariant/{Sample}/{Sample}.indel",
		refgen = config["Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/PepperDeepvariant_select_pass_norm.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/SNP_InDel/VcfSplitPassAndNorm.sh {input} {output.snp} {output.indel} {params.snp} {params.indel} {params.refgen} > {log.stdout} 2>&1
		"""

rule PepperDeepvariant_Anno:
	input:
		snp = "pepper_deepvariant/{Sample}/{Sample}.snp.vcf",
		indel = "pepper_deepvariant/{Sample}/{Sample}.indel.vcf"
	output:
		snp = "pepper_deepvariant/{Sample}/Annotation/pepper_deepvariant.snp.hg38_multianno.txt",
		indel = "pepper_deepvariant/{Sample}/Annotation/pepper_deepvariant.indel.hg38_multianno.txt"
	params:
		sp = "{Sample}",
		basedir = WorkDir,
		bed = config["Bed4Panel"],
		bedextend = config["Bed4PanelExtend"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/PepperDeepvariant_Anno.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Annotation/Anno.SNP_InDel.sh {params.basedir} pepper_deepvariant {params.sp} {params.bed} {params.bedextend} > {log.stdout} 2>&1
		"""