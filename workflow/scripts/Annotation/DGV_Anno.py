import os
import sys
import re
from collections import defaultdict

invcf = sys.argv[1]
dgv = sys.argv[2]
out = sys.argv[3]

output = open(out, "w")
output.write("\t".join(["SVID", "DGV_Accessions", "DGV_VariantTypes", "DGV_OverlapPercents"]) + "\n") 

def safe_open(file_name,mode):
    try:
        if not file_name.endswith('.gz'):
            return open(file_name,mode)
        else:
            import gzip
            return gzip.open(file_name,mode)
    except IOError:
        print(file_name + ' do not exist!')

def get_overlap(cor_list): #r1_start, r1_end, r2_start, r2_end
    overlap_start = max(cor_list[0], cor_list[2])
    overlap_end = min(cor_list[1], cor_list[3])
    if overlap_end >= overlap_start:
        return [overlap_start, overlap_end]
    else:
        return False

dgv_dict = defaultdict(lambda: defaultdict(lambda: defaultdict()))
first = True
for line in open(dgv, "r"):
    fields = line.strip().split("\t")
    if first:
        first = False
        continue
#    dgv_dict[fields[1]]["%s-%s"%(fields[2], fields[3])] = "\t".join([fields[0], fields[4] + "_" + fields[5], fields[1],
#                                                           fields[2], fields[3], fields[6], fields[7]])
    dgv_dict[fields[1]]["%s-%s"%(fields[2], fields[3])]["id"] = fields[0]
    dgv_dict[fields[1]]["%s-%s"%(fields[2], fields[3])]["type"] = fields[4] + "_" + fields[5]

for line in safe_open(invcf, "r"):
    try:
        line = str(line, encoding = "utf-8")
    except:
        line = line
    if line.startswith("#"):
        continue
    fields = line.strip().split("\t")
    info_parts = fields[7].split(";")
    svtype = ""
    for i in info_parts:
        if i.startswith("SVTYPE="):
            svtype = i.split("=")[1]
        elif i.startswith("END="):
            end = i.split("=")[1]
    if svtype in ["DEL", "DUP", "INS", "INV"]:
        chr = fields[0]
        start = fields[1]
        flag = False
        dgv_ids = list()
        dgv_types = list()
        dgv_overlap = list()
        if chr in dgv_dict:
            for d_pos in dgv_dict[chr]:
                dgv_type = dgv_dict[chr][d_pos]["type"]
                dgv_id = dgv_dict[chr][d_pos]["id"]
                if svtype == "DEL" and ("deletion" in dgv_type or "loss" in dgv_type):
                    pass
                elif svtype == "DUP" and ("duplication" in dgv_type or "gain" in dgv_type):
                    pass
                elif svtype == "INS" and ("insertion" in dgv_type):
                    pass
                elif svtype == "INV" and "inversion" in dgv_type:
                    pass
                else:
                    continue
                d_start, d_end = d_pos.split("-")
                overlap = get_overlap(list(map(int, [start, end, d_start, d_end])))
                if overlap:
                    percent = (overlap[1] - overlap[0] + 1) / (int(d_end) - int(d_start) + 1) * 100
                    if percent > 10:
                        dgv_types.append(dgv_type)
                        dgv_ids.append(dgv_id)
                        dgv_overlap.append("%0.6f"%(percent))
        if dgv_ids:
            ids = ";".join(dgv_ids)
            types = ";".join(dgv_types)
            overlaps = ";".join(dgv_overlap)
            output.write("\t".join(list(map(str, [fields[2], ids, types, overlaps]))) + "\n")

"""
    elif svtype in ["BND"]:
        chr = fields[0]
        start = fields[1]
        parts = re.split("[\[\]]", fields[4])
        for part in parts:
            if ":" in part:
                chr2, start2 = part.split(":") 
        if chr in dgv_dict:
            for d_pos in dgv_dict[chr]:
                dgv_type = dgv_type_dict[chr][d_pos]
                if dgv_type == "OTHER_complex":
                    pass
                else:
                    continue
                d_start, d_end = d_pos.split("-")
                if d_start != d_end:
                    continue
                if int(start) >= int(d_start) and int(start) <= int(d_end):
                    output.write("\t".join(list(map(str, [chr, start, start, fields[2], "Breakpoint"]))) + "\t" +  dgv_dict[chr][d_pos] + "\n")
        if chr2 in dgv_dict:
            for d_pos in dgv_dict[chr2]:
                dgv_type = dgv_type_dict[chr2][d_pos]
                if dgv_type == "OTHER_complex":
                    pass
                else:
                    continue
                d_start, d_end = d_pos.split("-")
                if d_start != d_end:
                    continue
                if int(start2) >= int(d_start) and int(start2) <= int(d_end):
                    output.write("\t".join(list(map(str, [chr2, start2, start2, fields[2], "Breakpoint"]))) + "\t" +  dgv_dict[chr2][d_pos] + "\n")
"""



