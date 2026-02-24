# for QC

rule QC_NanoPlot:
	input:
		"raw/{Sample}/FqList.txt"
	output: 
		"QC/{Sample}/NanoPlot/NanoStats.txt"
	params:
		odir = "QC/{Sample}/NanoPlot"
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/QC_NanoPlot.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/QC/NanoPlot.sh {threads} {input} {params.odir} > {log.stdout} 2>&1
		"""

rule QC_PanelStat:
	input:
		"minimap2/{Sample}/{Sample}.sort.bam"
	output: 
		"QC/{Sample}/{Sample}.PanelStat.txt"
	params:
		basedir = WorkDir,
		spname = "{Sample}",
		bed4panel = config["Bed4Panel"],
		bed4extend = config["Bed4PanelExtend"],
		bed4genome = config["Bed4Genome"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		20
	log:
		stdout = "logs/QC_PanelStat.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/QC/ONT_AS_BamQC.sh {params.basedir}/{input} {params.bed4panel} {params.spname} {params.basedir}/{output} {threads} {params.bed4genome} {params.bed4extend} > {log.stdout} 2>&1
		"""

rule QC_mosdepth:
	input:
		"minimap2/{Sample}/{Sample}.sort.bam"
	output: 
		"QC/{Sample}/{Sample}.mosdepth.summary.txt",
		"QC/{Sample}/{Sample}.mosdepth.global.dist.txt",
		"QC/{Sample}/{Sample}.thresholds.bed.gz"
	params:
		prefix = "QC/{Sample}/{Sample}",
		bed = config["Bed4Depth"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/QC_mosdepth.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/QC/Mosdepth.sh {threads} {params.bed} {params.prefix} {input} > {log.stdout} 2>&1
		"""

rule QC_FullDepth:
	input:
		"minimap2/{Sample}/{Sample}.sort.bam"
	output: 
		"QC/{Sample}/{Sample}.fulldepth.txt.gz"
	params:
		bed = config["Bed4Depth"]
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/QC_FullDepth.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/QC/FullDepth.sh {input} {params.bed} {output} {threads} > {log.stdout} 2>&1
		"""

rule QC_MappingStat:
	input:
		summary = "QC/{Sample}/{Sample}.mosdepth.summary.txt",
		threshold = "QC/{Sample}/{Sample}.thresholds.bed.gz"
	output:
		stat = "QC/{Sample}/{Sample}.bam.stat.txt",
	params:
		spname = "{Sample}",
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		2
	log:
		stdout = "logs/QC_MappingStat.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/QC/MappingStat.sh {params.spname} {input.summary} {input.threshold} {output.stat} > {log.stdout} 2>&1
		"""

rule QC_Circos_WGS:
	input:
		bam = "minimap2/{Sample}/{Sample}.sort.bam",
		mos = "QC/{Sample}/{Sample}.PanelStat.txt"
	output: 
		"QC/{Sample}/Circos/{Sample}.Circos.WGS.cov.png"
	params:
		window = config["WindowWGS"],
		winsize = config["WindowSize4WGS"],
		fileprefix = "QC/{Sample}/Circos/{Sample}.Circos.WGS",
		spname = "{Sample}",
		gentype = config['GenType']
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/QC_Circos_WGS.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/QC/GenomeCovWithCircos_v1.0.sh {input.bam} {params.window} {params.winsize} {params.fileprefix} {params.spname} {input.mos} {params.gentype} > {log.stdout} 2>&1
		"""

rule QC_Circos_Panel:
	input:
		bam = "minimap2/{Sample}/{Sample}.sort.bam",
		mos = "QC/{Sample}/{Sample}.PanelStat.txt"
	output: 
		"QC/{Sample}/Circos/{Sample}.Circos.Panel.cov.png"
	params:
		fileprefix = "QC/{Sample}/Circos/{Sample}.Circos.Panel",
		bed4panel = config["Bed4Panel"],
		spname = "{Sample}",
		gentype = config['GenType']
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/QC_Circos_Panel.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/QC/PanelCovWithCircos_v1.0.sh {input.bam} {params.bed4panel} {params.fileprefix} {params.spname} {input.mos} {params.gentype} > {log.stdout} 2>&1
		"""

rule QC_Gender:
	input:
		bam = "minimap2/{Sample}/{Sample}.sort.bam"
	output: 
		"QC/{Sample}/{Sample}.GenderInfo.txt"
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/QC_Gender.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/QC/GenderInfo.sh {input.bam} {output} {threads} > {log.stdout} 2>&1
		"""