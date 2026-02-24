#!/usr/bin/Rscript

library(argparser)

p <- arg_parser("Run a CN anlysis via QDNAseq")
p <- add_argument(p, "--bam", help="Input BAM file (ref hg19 or hg38)")
p <- add_argument(p, "--File4Bin", help="File records the bin info", default="-")
p <- add_argument(p, "--gender", help="Gender, Male or Female")
p <- add_argument(p, "--out_prefix", help="Prefix for output file names")
p <- add_argument(p, "--method", help="cutoff or CGHcall", default="cutoff")
p <- add_argument(p, "--cutoff", help="CN cutoff modifer, 0.0-1.0", default='0.5')
p <- add_argument(p, "--cutoffDEL", help="CN cutoff threshold for deletion (double loss)", default=0.5)
p <- add_argument(p, "--cutoffLOSS", help="CN cutoff threshold for loss", default=1.5)
p <- add_argument(p, "--cutoffGAIN", help="CN cutoff threshold for gain", default=2.5)
p <- add_argument(p, "--cellularity", help="CGHcall cellularity", default=1.0)
p <- add_argument(p, "--reference", help="QDNAseq GC/mappability bins reference. Defaults to qdnaseq_hg38", default="hg38")
p <- add_argument(p, "--bed", help="Bed file which will be excluded.", default="-")
p <- add_argument(p, "--binsize", help="bin size in kbp", default=500)
p <- add_argument(p, "--blist", help="Directory records the original blacklist", default="-")
argv <- parse_args(p)
if (argv$cutoff %in% c('none','None','NONE')) {
    argv$cutoff <- 'none'
} else {
    argv$cutoff <- as.numeric(as.character(argv$cutoff))
}
cat("[ Info ] cutoff is ", argv$cutoff, "\n")

library(matrixStats)
library(QDNAseq)
library(Biobase)
set.seed(20240801)

# 1. load genome bin information
if (argv$File4Bin != "-") {
	cat("[ Info ] Loading bin from file.\n")
	bins = read.table(argv$File4Bin,header = T,sep = '\t',check.names = F, stringsAsFactors = F)

	# filter bins with blacklist
	if (argv$bed != "-" && argv$bed != "none") {
		bins$blacklist = calculateBlacklist(bins, bedFiles=c(argv$bed ,paste0(argv$blist,"/hg38-blacklist.v2.nochr.bed")))
	} else if (argv$bed != "none") {
		bins$blacklist = calculateBlacklist(bins, bedFiles=c(paste0(argv$blist,"/hg38-blacklist.v2.nochr.bed")))
	} else {
		cat("[ Info ] No blacklist.\n")
	}

	bins = AnnotatedDataFrame(bins,
		varMetadata=data.frame(labelDescription=c(
		"Chromosome name",
		"Base pair start position",
		"Base pair end position",
		"Percentage of non-N nucleotides (of full bin size)",
		"Percentage of C and G nucleotides (of non-N nucleotides)",
		"Average mappability of 600mers with a maximum of 2 mismatches",
		"Percent overlap with ENCODE blacklisted regions",
		"Median loess residual from CHD (600mers)",
		"Whether the bin should be used in subsequent analysis steps"),
		row.names=colnames(bins)))
} else if (argv$reference == "hg38") {
	library(QDNAseq.hg38)
	bins <- getBinAnnotations(binSize=argv$binsize, genome="hg38")
	
	# filter bins with blacklist
	if (argv$bed != "-" && argv$bed != "none") {
		bins@data$blacklist = calculateBlacklist(bins@data, bedFiles=c(argv$bed ,paste0(argv$blist,"/hg38-blacklist.v2.nochr.bed")))
	} else if (argv$bed != "none") {
		bins@data$blacklist = calculateBlacklist(bins@data, bedFiles=c(paste0(argv$blist,"/hg38-blacklist.v2.nochr.bed")))
	} else {
		cat("[ Info ] No blacklist.\n")
	}
} else if (argv$reference == "hg19") {
	library(QDNAseq.hg19)
	bins <- getBinAnnotations(binSize=argv$binsize, genome="hg19")

	# filter bins with blacklist
	if (argv$bed != "-" && argv$bed != "none") {
		bins@data$blacklist = calculateBlacklist(bins@data, bedFiles=c(argv$bed ,paste0(argv$blist,"/hg19-blacklist.v2.nochr.bed")))
	} else if (argv$bed != "none") {
		bins@data$blacklist = calculateBlacklist(bins@data, bedFiles=c(paste0(argv$blist,"/hg19-blacklist.v2.nochr.bed")))
	} else {
		cat("[ Info ] No blacklist.\n")
	}
}

# 2. read count or mean depth info should be given from file too
cat("[ Info ] Begin process count info\n")
readCounts <- binReadCounts(bins, bamfiles=argv$bam)
# 3. Apply filters and plot median read counts as a function of GC content and mappability (only marker, not filter really, column of use markered with FALSE)
autosomalReadCountsFiltered <- applyFilters(readCounts, residual=TRUE, blacklist=TRUE, mappability=95)
# 4. Estimate the GC / mappability correction
autosomalReadCountsFiltered <- estimateCorrection(autosomalReadCountsFiltered)

# map draw
pdf_file <- paste(argv$out_prefix, 'plots.pdf', sep="_")
pdf(pdf_file)
# median(readCounts@assayData$counts)
tCount = readCounts@assayData$counts
UpLimit4ReadCount = 2 * median(tCount[which(tCount > 0)])
if (UpLimit4ReadCount < 100)
{
	UpLimit4ReadCount = 100
}
plot(readCounts, logTransform=FALSE, ylim=c(0, UpLimit4ReadCount))

if (argv$gender == 'Female' || argv$gender == 'female') {
	############### all chromosome ###############
	# Create copy numbers object
	readCountsFiltered <- applyFilters(autosomalReadCountsFiltered, chromosomes=c("Y"), mappability=95)
	# Apply correction for GC content and mappability
	copyNumbers <- correctBins(readCountsFiltered)
	# Median Normalization
	copyNumbersNormalized <- normalizeBins(copyNumbers)
	# Smooth outliers
	copyNumbersSmooth <- smoothOutlierBins(copyNumbersNormalized)
	# segmentation: CBS algorithm from DNAcopy
	copyNumbersSegmented <- segmentBins(copyNumbersSmooth, transformFun="sqrt", undo.splits="sdundo", undo.SD=0.5, alpha=0.001)
	# it will record: 
	# Performing segmentation:
	# Segmenting: Simulated (1 of 1) ...
	copyNumbersSegmented <- normalizeSegmentedBins(copyNumbersSegmented)
	plot(copyNumbersSegmented)
	## Record for debugging after segmentation
	if (TRUE) {
		tassayData = assayData(copyNumbersSegmented)
		tfeatureData = featureData(copyNumbersSegmented)
		tDF = data.frame(chromosome = tfeatureData$chromosome, start = tfeatureData$start, end = tfeatureData$end, bases = tfeatureData$bases, gc = tfeatureData$gc, mappability = tfeatureData$mappability, blacklist = tfeatureData$blacklist, residual = tfeatureData$residual, use = tfeatureData$use, cpname = rownames(tassayData$copynumber), copynumber = tassayData$copynumber[,1], segname = rownames(tassayData$segmented), segmented = tassayData$segmented[,1])
		tFile = paste(argv$out_prefix, "Segmentation.txt", sep="_")
		write.table(tDF, file = tFile, quote=FALSE, sep="\t", na="-", row.names=FALSE)
	}
	# it will record:
	# Calling aberrations with the following cutoffs:
	# homozygous deletion < -2 < loss < -0.42 < normal < 0.32 gain < 2.32 < amplification
	if (argv$method=='cutoff') {
		if (argv$cutoff == 'none') {
			copyNumbersCalled <- callBins(copyNumbersSegmented, method = 'cutoff')
		}
		else {
			cutoffDEL <- argv$cutoffDEL + 0.5 - argv$cutoff
			cutoffLOSS <- argv$cutoffLOSS + 0.5 - argv$cutoff
			cutoffGAIN <- argv$cutoffGAIN + argv$cutoff - 0.5
			# with integer -2, -1, 0, 1, 2 or 3
			copyNumbersCalled <- callBins(copyNumbersSegmented, method = 'cutoff', cutoffs=log2(c(deletion = cutoffDEL, loss = cutoffLOSS, gain = cutoffGAIN, amplification = 10)/2))
		}
	}
	if (argv$method=='CGHcall') {
		copyNumbersCalled <- callBins(copyNumbersSegmented, method = 'CGHcall', cellularity=argv$cellularity )
	}
	# write outputs
	vcfout <- paste(argv$out_prefix, "calls.vcf", sep="_")
	exportBins(copyNumbersCalled, file=vcfout, format="vcf", type="calls")
	cat("[ Info ] Export to ", vcfout, "\n")
} else {
	############### autosome ###############
	# Create copy numbers object
	readCountsFiltered <- applyFilters(autosomalReadCountsFiltered, chromosomes=c("X","Y"), mappability=95)
	# Apply correction for GC content and mappability
	copyNumbers <- correctBins(readCountsFiltered)
	# Median Normalization
	copyNumbersNormalized <- normalizeBins(copyNumbers)
	# Smooth outliers
	copyNumbersSmooth <- smoothOutlierBins(copyNumbersNormalized)
	# segmentation: CBS algorithm from DNAcopy
	copyNumbersSegmented <- segmentBins(copyNumbersSmooth, transformFun="sqrt", undo.splits="sdundo", undo.SD=0.5, alpha=0.001)
	# it will record: 
	# Performing segmentation:
	# Segmenting: Simulated (1 of 1) ...
	copyNumbersSegmented <- normalizeSegmentedBins(copyNumbersSegmented)
	plot(copyNumbersSegmented)
	## Record for debugging after segmentation
	if (TRUE) {
		tassayData = assayData(copyNumbersSegmented)
		tfeatureData = featureData(copyNumbersSegmented)
		tDF = data.frame(chromosome = tfeatureData$chromosome, start = tfeatureData$start, end = tfeatureData$end, bases = tfeatureData$bases, gc = tfeatureData$gc, mappability = tfeatureData$mappability, blacklist = tfeatureData$blacklist, residual = tfeatureData$residual, use = tfeatureData$use, cpname = rownames(tassayData$copynumber), copynumber = tassayData$copynumber[,1], segname = rownames(tassayData$segmented), segmented = tassayData$segmented[,1])
		tFile = paste(argv$out_prefix, "Segmentation.Auto.txt", sep="_")
		write.table(tDF, file = tFile, quote=FALSE, sep="\t", na="-", row.names=FALSE)
	}
	# it will record:
	# Calling aberrations with the following cutoffs:
	# homozygous deletion < -2 < loss < -0.42 < normal < 0.32 gain < 2.32 < amplification
	if (argv$method=='cutoff') {
		if (argv$cutoff == 'none') {
			copyNumbersCalled <- callBins(copyNumbersSegmented, method = 'cutoff')
		}
		else {
			cutoffDEL <- argv$cutoffDEL + 0.5 - argv$cutoff
			cutoffLOSS <- argv$cutoffLOSS + 0.5 - argv$cutoff
			cutoffGAIN <- argv$cutoffGAIN + argv$cutoff - 0.5
			# with integer -2, -1, 0, 1, 2 or 3
			copyNumbersCalled <- callBins(copyNumbersSegmented, method = 'cutoff', cutoffs=log2(c(deletion = cutoffDEL, loss = cutoffLOSS, gain = cutoffGAIN, amplification = 10)/2))
		}
	}
	if (argv$method=='CGHcall') {
		copyNumbersCalled <- callBins(copyNumbersSegmented, method = 'CGHcall', cellularity=argv$cellularity )
	}
	# write outputs
	vcfout <- paste(argv$out_prefix, "auto_calls.vcf", sep="_")
	exportBins(copyNumbersCalled, file=vcfout, format="vcf", type="calls")
	cat("[ Info ] Export to ", vcfout, "\n")

	############### sex chromosome ###############
	# Create copy numbers object
	readCountsFiltered <- applyFilters(autosomalReadCountsFiltered, chromosomes=c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22), mappability=95)
	# Apply correction for GC content and mappability
	copyNumbers <- correctBins(readCountsFiltered)
	# Median Normalization
	copyNumbersNormalized <- normalizeBins(copyNumbers)
	# Smooth outliers
	copyNumbersSmooth <- smoothOutlierBins(copyNumbersNormalized)
	# segmentation: CBS algorithm from DNAcopy
	copyNumbersSegmented <- segmentBins(copyNumbersSmooth, transformFun="sqrt", undo.splits="sdundo", undo.SD=0.5, alpha=0.001)
	# it will record: 
	# Performing segmentation:
	# Segmenting: Simulated (1 of 1) ...
	copyNumbersSegmented <- normalizeSegmentedBins(copyNumbersSegmented)
	plot(copyNumbersSegmented)
	## Record for debugging after segmentation
	if (TRUE) {
		tassayData = assayData(copyNumbersSegmented)
		tfeatureData = featureData(copyNumbersSegmented)
		tDF = data.frame(chromosome = tfeatureData$chromosome, start = tfeatureData$start, end = tfeatureData$end, bases = tfeatureData$bases, gc = tfeatureData$gc, mappability = tfeatureData$mappability, blacklist = tfeatureData$blacklist, residual = tfeatureData$residual, use = tfeatureData$use, cpname = rownames(tassayData$copynumber), copynumber = tassayData$copynumber[,1], segname = rownames(tassayData$segmented), segmented = tassayData$segmented[,1])
		tFile = paste(argv$out_prefix, "Segmentation.Sex.txt", sep="_")
		write.table(tDF, file = tFile, quote=FALSE, sep="\t", na="-", row.names=FALSE)
	}
	# it will record:
	# Calling aberrations with the following cutoffs:
	# homozygous deletion < -2 < loss < -0.42 < normal < 0.32 gain < 2.32 < amplification
	if (argv$method=='cutoff') {
		if (argv$cutoff == 'none') {
			copyNumbersCalled <- callBins(copyNumbersSegmented, method = 'cutoff')
		}
		else {
			cutoffDEL <- argv$cutoffDEL + 0.5 - argv$cutoff
			cutoffLOSS <- argv$cutoffLOSS - 1 + 0.5 - argv$cutoff
			cutoffGAIN <- argv$cutoffGAIN + 1 + argv$cutoff - 0.5
			# with integer -2, -1, 0, 1, 2 or 3
			copyNumbersCalled <- callBins(copyNumbersSegmented, method = 'cutoff', cutoffs=log2(c(deletion = cutoffDEL, loss = cutoffLOSS, gain = cutoffGAIN, amplification = 10)/2))
		}
	}
	if (argv$method=='CGHcall') {
		copyNumbersCalled <- callBins(copyNumbersSegmented, method = 'CGHcall', cellularity=argv$cellularity )
	}
	# write outputs
	vcfout <- paste(argv$out_prefix, "sex_calls.vcf", sep="_")
	exportBins(copyNumbersCalled, file=vcfout, format="vcf", type="calls")
	cat("[ Info ] Export to ", vcfout, "\n")
}
