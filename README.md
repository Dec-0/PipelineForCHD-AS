# **PipelineForCHD-AS**

## Introduction
 This pipeline was designed for germline variant calling using Nanopore adaptive sampling data. It is compatible with samples derived from blood cells or tissues, and the gene panel can scale from one single gene to several hundreds. Two analysing modes were supported, CHD-1 for the variants calling of CNV in off-target region and SNP/InDel/SV/CNV in on-target region, CHD-2 for the variants calling of CNV in off-target and SV in on-target.

## Requirements
 Softwares and databases required were listed in config.yaml and soft.yaml. And the corresponding entries should be replaced manually according to the environment.

## Testing
 1. The adaptive sampling data of NA24385 on R10 flowcell was recommended.
 2. Minimal coverage on target area should not below 20x and the commands for CHD-1 was suggested.

## Command for analysing
 1. CHD-1: nohup snakemake -s /path/to/Snakefile --cores 30 --config Sample="NA24385R10" Flag4QC="Yes" Flag4SnpIndel="Yes" Flag4SV="Yes" Flag4CNV_On="Yes" Flag4CNV_Off="Yes" Flag4Trim="No" > nohup.log 2>&1 &
 2. CHD-2: nohup snakemake -s /path/to/Snakefile --cores 30 --config Sample="NA24385R10" Flag4QC="Yes" Flag4SnpIndel="No" Flag4SV="Yes" Flag4CNV_On="No" Flag4CNV_Off="Yes" Flag4Trim="No" > nohup.log 2>&1 &
 3. For sample name like NA24385R10，there should be a file named NA24385R10.FqList.txt under the directory of Prefix4Fq.
