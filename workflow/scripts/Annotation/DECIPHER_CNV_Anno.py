import os
import sys
from collections import defaultdict

invcf = sys.argv[1]
decipher = sys.argv[2]
out = sys.argv[3]

output = open(out, "w")
output.write("\t".join(["SVID", "DECIPHER_CNV_Syndrome", "DECIPHER_CNV_Genotype", "DECIPHER_CNV_Size", "DECIPHER_CNV_Grade", "DECIPHER_CNV_OverlapPercents"]) + "\n")

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
    if overlap_end > overlap_start:
        return [overlap_start, overlap_end]
    else:
        return False

decipher_dict = defaultdict(lambda: defaultdict(lambda: defaultdict()))
first = True
for line in open(decipher, "r"):
    fields = line.strip().split("\t")
    if first:
        first = False
        continue
    #decipher_dict[fields[0]]["%s-%s"%(fields[1], fields[2])] = line.strip()
    decipher_dict[fields[0]]["%s-%s"%(fields[1], fields[2])]["syndrome"] = fields[3]
    decipher_dict[fields[0]]["%s-%s"%(fields[1], fields[2])]["genotype"] = fields[4]
    decipher_dict[fields[0]]["%s-%s"%(fields[1], fields[2])]["size"] = fields[5]
    decipher_dict[fields[0]]["%s-%s"%(fields[1], fields[2])]["grade"] = fields[6]

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
    if svtype in ["DEL", "DUP"]:
        chr = fields[0]
        start = fields[1]
        syns = list()
        genos = list()
        sizes = list()
        grades = list()
        overlaps = list()
        if chr in decipher_dict:
            for d_pos in decipher_dict[chr]:
                d_start, d_end = d_pos.split("-")
                overlap = get_overlap(list(map(int, [start, end, d_start, d_end])))
                if overlap:
                    percent = (overlap[1] - overlap[0] + 1) / (int(d_end) - int(d_start) + 1) * 100
                    if percent > 0:
                        syns.append(decipher_dict[chr][d_pos]["syndrome"])
                        genos.append(decipher_dict[chr][d_pos]["genotype"])
                        sizes.append(decipher_dict[chr][d_pos]["size"])
                        grades.append(decipher_dict[chr][d_pos]["grade"])
                        overlaps.append(round(percent, 6))
        if syns:
            syn = ";".join(syns)
            geno = ";".join(genos)
            size = ";".join(sizes)
            grade = ";".join(grades)
            overlap = ";".join(list(map(str, overlaps)))
            output.write("\t".join(list(map(str, [fields[2], syn, geno, size, grade, overlap]))) + "\n")

