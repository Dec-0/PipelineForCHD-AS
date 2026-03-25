# **PipelineForCHD-AS**

## Introduction
 This pipeline was designed for germline variant calling using Nanopore adaptive sampling and is applicable to datasets generated from any sample type. The gene panel can be flexibly configured, ranging from a single gene to several hundreds. Two analysis modes are supported, utilizing breakpoint and read depth information: CHD-1, which performs SNP, Indel, and SV detection in on-target regions and CNV detection in off-target regions; and CHD-2, which performs SV detection in on-target regions and CNV detection in off-target regions.

## Requirements
 The required software and databases are listed in config.yaml and soft.yaml, and the relevant entries should be manually updated according to the environment.

## Testing
 1. The adaptive sampling data of NA24385 on the R10 flowcell is recommended.
 2. A minimum read depth of 20× in the target region and 1× in the off-target region is recommended for optimal performance, and the commands for CHD-1 and CHD-2 are provided below.

## Command for analysing
 1. CHD-1: nohup snakemake -s /path/to/Snakefile --cores 30 --config Sample="NA24385R10" Flag4QC="Yes" Flag4SnpIndel="Yes" Flag4SV="Yes" Flag4CNV_On="Yes" Flag4CNV_Off="Yes" > nohup.log 2>&1 &
 2. CHD-2: nohup snakemake -s /path/to/Snakefile --cores 30 --config Sample="NA24385R10" Flag4QC="Yes" Flag4SnpIndel="No" Flag4SV="Yes" Flag4CNV_On="No" Flag4CNV_Off="Yes" > nohup.log 2>&1 &
 3. For each sample (e.g., NA24385R10), all associated FASTQ files should be listed in a file named NA24385R10.FqList.txt, with one FASTQ file per line. This file should be placed in the directory specified in the configuration file.
