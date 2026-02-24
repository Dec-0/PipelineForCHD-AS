# for fq manipulation

rule fqtrim:
	input:
		config["Prefix4Fq"] + "/{Sample}.FqList.txt"
	output:
		"raw/{Sample}/FqList.txt"
	params:
		flag4trim = config["Flag4Trim"],
		logdir = "raw/{Sample}"
	resources:
		tmpdir = WorkDir + "/.tmp"
	threads:
		10
	log:
		stdout = "logs/fqtrim.{Sample}." + config["Stamp"] + ".log"
	shell:
		"""
		{Dir4SF}/scripts/Fq/FqTrim.sh {threads} {input} {params.logdir} {params.flag4trim} > {log.stdout} 2>&1
		"""