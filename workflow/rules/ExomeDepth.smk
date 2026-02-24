# for ExomeDepth

rule ExomeDepth_Calling:
	input:
		bam = "minimap2/{Sample}/{Sample}.sort.bam",
		genderfile = "QC/{Sample}/{Sample}.GenderInfo.txt"
	output:
		"ExomeDepth/{Sample}/{Sample}.ReadCount.txt",
		"ExomeDepth/{Sample}/{Sample}.MeanDepth.txt",
		"ExomeDepth/{Sample}/{Sample}.ExomeDepth.vcf.gz"
	params:
		basedir = WorkDir,
		bamref = config["BamRefList"],
		prefix = "ExomeDepth/{Sample}/{Sample}",
		genome = config["Genome"],
		bedbinprefix = config["PanelBinPrefix"],
		refset4countprefix = config["RefSet4ReadCountPrefix"],
		refset4depthprefix = config["RefSet4MeanDepthPrefix"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		5
	log:
		stdout = "logs/ExomeDepth_Calling.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/CNV/ExomeDepth_v1.1.sh {params.basedir}/{input.bam} {params.basedir}/{input.genderfile} {params.bamref} {params.basedir}/{params.prefix} {params.genome} {params.bedbinprefix} {params.refset4depthprefix} {params.refset4countprefix} {threads} > {log.stdout} 2>&1
		"""

rule ExomeDepth_Anno:
	input:
		"ExomeDepth/{Sample}/{Sample}.ExomeDepth.vcf.gz"
	output:
		merge = "ExomeDepth/{Sample}/Annotation/ExomeDepth.xls",
		cnv_del = "ExomeDepth/{Sample}/Annotation/CNV_DEL",
		cnv_dup = "ExomeDepth/{Sample}/Annotation/CNV_DUP"
	params:
		sp = "{Sample}",
		basedir = WorkDir
	threads:
		2
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/ExomeDepth_Anno.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Annotation/Anno.CNV.sh {params.basedir} ExomeDepth {params.sp} > {log.stdout} 2>&1
		"""

rule ExomeDepth_Circos:
	input:
		readcount = "ExomeDepth/{Sample}/{Sample}.ReadCount.txt",
		meandepth = "ExomeDepth/{Sample}/{Sample}.MeanDepth.txt"
	output:
		rc = "ExomeDepth/{Sample}/Circos/{Sample}.ReadCount.cov.png",
		md = "ExomeDepth/{Sample}/Circos/{Sample}.MeanDepth.cov.png"
	params:
		sp = "{Sample}",
		dirandprefix = WorkDir + "/ExomeDepth/{Sample}/Circos/{Sample}"
	threads:
		2
	resources:
		tmpdir = WorkDir + "/.tmp"
	log:
		stdout = "logs/ExomeDepth_Circos.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/CNV/ExomeDepth_Circos.sh {input.meandepth} {input.readcount} {params.dirandprefix} {params.sp} > {log.stdout} 2>&1
		"""