import os
import sys
from collections import defaultdict

annotsv = sys.argv[1]
out = open(sys.argv[2], "w")
Dir4DB = sys.argv[3]
Dir4SH = os.path.abspath(__file__)
Dir4SH = os.path.dirname(Dir4SH)

hpo_dict = defaultdict(lambda: defaultdict())
for line in open(f"{Dir4DB}/hpo_item.txt"):
    fields = line.strip().split("\t")
    hpo_dict[fields[0]]["EN"] = fields[1]
    hpo_dict[fields[0]]["CN"] = fields[2]

gnom_dict = defaultdict()
gnom_files = [f"{Dir4DB}/benign_Gain_SV_GRCh38.sorted.bed",
               f"{Dir4DB}/benign_Ins_SV_GRCh38.sorted.bed",
               f"{Dir4DB}/benign_Inv_SV_GRCh38.sorted.bed",
               f"{Dir4DB}/benign_Loss_SV_GRCh38.sorted.bed"]

for g_file in gnom_files:
    for line in open(g_file, "r"):
        fields = line.strip().split("\t")
        gnom_dict[fields[3]] = fields[5]

clinvar_dict = defaultdict(lambda: defaultdict())
for line in open(f"{Dir4DB}/clinvar_20230514.txt", "r"):
    fields = line.strip().split("\t")
    clinvar_dict[fields[0]]["CLNVC"] = fields[1]
    clinvar_dict[fields[0]]["CLNSIG"] = fields[2]

omim_gene_dict = defaultdict(list)
import gzip
for line in gzip.open(f"{Dir4DB}/20220905_OMIM-1-annotations.tsv.gz", "r"):
    try:
        line = str(line, encoding = "utf-8")
    except:
        line = line
    fields = line.strip().split("\t")
    genes = fields[0].split(";")
    omims = fields[1].split(";")
    for omim in omims:
        for gene in genes:
            omim_gene_dict[omim].append(gene)

class AnnotSV:
    def __init__(self, svid, sampleid, svtype, svlen, sampleformat, cyto, gene_count, gene_name, 
                acmg, annotsv_rank, hi, ts, hpo, hpo_en, hpo_cn,
                gnomAD_AF, clinvar_id, clinvar_ac, clinvar_sig):
        self.svid = svid
        self.sampleid = sampleid
        self.svtype = svtype
        self.svlen = svlen
        self.format = sampleformat
        self.samplenum = str(len(sampleid.split(",")))
        self.cyto = cyto
        self.gene_count = gene_count
        self.gene_name = gene_name
        self.gene_name_list = gene_name.split(";")
        self.acmg = acmg
        self.annotsv_rank = annotsv_rank
        self.hi = hi
        self.ts = ts
        self.hpo = hpo
        self.hpo_en = hpo_en
        self.hpo_cn = hpo_cn
        self.gnomAD_AF = gnomAD_AF
        self.clinvar_id = ";".join(clinvar_id)
        self.clinvar_ac = ";".join(clinvar_ac)
        self.clinvar_sig = ";".join(clinvar_sig)
        self.omim_gene = list()
        self.omim_phenotype = list()
        self.omim_inher = list()
    def add_omim(self, omim_id, omim_phenotype, omim_inher):
        omim_genes = omim_gene_dict[omim_id]
        target_genes = list(set(omim_genes) & set(self.gene_name_list))
        for gene in target_genes:
            self.omim_gene.append(gene)
            self.omim_phenotype.append(omim_phenotype)
            self.omim_inher.append(omim_inher)

    def __str__(self):
        return "\t".join([self.svid, self.svtype, self.svlen, self.cyto, self.acmg, self.annotsv_rank, self.gene_count, self.gene_name, self.hi, self.ts, self.samplenum, self.sampleid, self.format, self.hpo, self.hpo_en, self.hpo_cn, str(self.gnomAD_AF), self.clinvar_id, self.clinvar_ac, self.clinvar_sig, ";".join(self.omim_gene), ";".join(self.omim_phenotype), ";".join(self.omim_inher)])

def process_format(informat):
    parts = informat.split(":")[:5]
    parts[0] = "GT=%s"%(parts[0])
    #parts[1] = "GQ=%s"%(parts[1])
    parts[1] = "GQ=."
    parts[2] = "DR=%s"%(parts[4])
    parts[3] = "DV=%s"%(parts[3])
    return ":".join(parts[0:4])

first = True
title_ind = defaultdict()

samples = list()
sv_dict = defaultdict()
for line in open(annotsv, "r"):
    fields = line.strip().split("\t")
    if first:
        for i, j in enumerate(fields):
            title_ind[j] = i
        samples = fields[title_ind["FORMAT"] + 1: title_ind["Annotation_mode"]]
        first = False
        continue
    svid = fields[title_ind["ID"]]
    sampleid = fields[title_ind["Samples_ID"]]
    if sampleid == "":
    	for sp in samples:
    		if fields[title_ind[sp]] != "./.:NA:NA:NA:NA":
    			if sampleid == "":
    				sampleid = sp
    			else:
    				sampleid = sampleid + "," + sp
    svtype = fields[title_ind["SV_type"]]
    svlen = fields[title_ind["SV_length"]]
    if fields[title_ind["Annotation_mode"]] == "full":
        cyto = fields[title_ind["CytoBand"]]
        gene_count = fields[title_ind["Gene_count"]]
        gene_name = fields[title_ind["Gene_name"]]
        HI = fields[title_ind["HI"]]
        TS = fields[title_ind["TS"]]
        AnnotSV_ranking_score = fields[title_ind["AnnotSV_ranking_score"]]
        ACMG_class = fields[title_ind["ACMG_class"]]
        samples_format = []
        for sample in samples:
            samples_format.append(process_format(fields[title_ind[sample]]))
        hpo = []
        hpo_en = ""
        hpo_cn = ""
        gnomAD_res = list()
        clinvar_id = list()
        clinvar_vc = list()
        clinvar_sig = list()
        if svtype == "DUP":
            if fields[title_ind["P_gain_hpo"]]:
                hpo.append(fields[title_ind["P_gain_hpo"]])
        elif svtype == "INS":
            if fields[title_ind["P_ins_hpo"]]:
                hpo.append(fields[title_ind["P_ins_hpo"]])
        elif svtype == "DEL":
            if fields[title_ind["P_loss_hpo"]]:
                hpo.append(fields[title_ind["P_loss_hpo"]])
        for i in ["P_loss_source", "P_gain_source", "P_ins_source"]:
            if fields[title_ind[i]]:
                for s in fields[title_ind[i]].split(";"):
                    if s.startswith("CLN"):
                        if s.split(":")[-1] in clinvar_dict:
                            clinvar_id.append(s.split(":")[-1])
                            clinvar_vc.append(clinvar_dict[s.split(":")[-1]]["CLNVC"])
                            clinvar_sig.append(clinvar_dict[s.split(":")[-1]]["CLNSIG"])
        for i in ["B_loss_source", "B_gain_source", "B_ins_source"]:
            if fields[title_ind[i]]:
                for s in fields[title_ind[i]].split(";"):
                    if s.startswith("gnomAD-SV"):
                        gnomAD_res.append(gnom_dict[s])
        if hpo:
            hpo = ";".join(hpo)
            hpo_en = ";".join([hpo_dict[i]["EN"] for i in hpo.split(";") if i in hpo_dict])
            hpo_cn = ";".join([hpo_dict[i]["CN"] for i in hpo.split(";") if i in hpo_dict])
        else:
            hpo = ""
        if gnomAD_res:
            gnomAD_af = max([float(i) for i in gnomAD_res])
        else:
            gnomAD_af = ""
        sv_dict[svid] = AnnotSV(svid, sampleid, svtype, svlen, "\t".join(samples_format), cyto, gene_count, gene_name, ACMG_class, AnnotSV_ranking_score, HI, TS, hpo, hpo_en, hpo_cn, gnomAD_af, clinvar_id, clinvar_vc, clinvar_sig)
    elif fields[title_ind["Annotation_mode"]] == "split":
        omim_id = fields[title_ind["OMIM_ID"]]
        omim_pheno = fields[title_ind["OMIM_phenotype"]]
        omim_inher = fields[title_ind["OMIM_inheritance"]]
        sv_dict[svid].add_omim(omim_id, omim_pheno, omim_inher)


out.write("\t".join(["SVID", "SV_Type", "SV_Length", "CytoBand", "ACMG", "AnnotSV_ranking_score", "Gene_Count", "Gene_Name", "HI", "TS", "Sample_Count", "Sample_ID"] + samples + ["HPO_ITEM", "HPO_Syndrome", "HPO_Syndrome_CN", "gnomAD_AF", "Clinvar_AlleleID", "Clinvar_VariantType", "Clinvar_Sig", "OMIM_Gene", "OMIM_Phenotype", "OMIM_Inheritance"]) + "\n")
for svid in sv_dict:
    out.write(str(sv_dict[svid]) + "\n")
