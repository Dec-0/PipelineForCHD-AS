import os
import sys
from collections import defaultdict

annovar = sys.argv[1]
Dir4DB = sys.argv[3]
Dir4SH = os.path.abspath(__file__)
Dir4SH = os.path.dirname(Dir4SH)

class refgene:
    def __init__(self, ref_line):
        self.parts = ref_line.strip().split("\t")
        self.tx, self.chr, self.strand, self.tx_start, self.tx_end, \
          self.cds_start, self.cds_end, self.exon_count, self.exon_starts,\
          self.exon_ends, n, self.gene = self.parts[1:-3]

    def get_coding_type(self):
        if self.cds_start != self.cds_end:
            self.coding_type = "coding"
        else:
            self.coding_type = "noncoding"

    def get_exon_intron(self):
        exon_starts = self.exon_starts.strip(",").split(",")
        exon_ends = self.exon_ends.strip(",").split(",")
        if self.strand == "-":
            self.exon_starts = exon_ends[::-1]
            self.exon_ends = exon_starts[::-1]
        else:
            self.exon_starts = exon_starts
            self.exon_ends = exon_ends
        self.regions = defaultdict()
        for i, j in enumerate(self.exon_starts):
            start = j
            end = self.exon_ends[i]
            self.regions["exon%s"%(i + 1)] = [start, end] 
        if len(self.exon_starts) > 1: #intron
            for i, j in enumerate(self.exon_ends[:-1]):
                start = j
                end = self.exon_starts[i + 1]
                self.regions["intron%s"%(i + 1)] = [start, end]
    
    def locate_breakpoint_region(self, breakpoint):
        if breakpoint < int(self.tx_start):
            if self.strand == "+":
                region = "intergenic"
                dist = "-%d"%(abs(int(self.tx_start) - breakpoint)) #upstream
            elif self.strand == "-":
                region = "intergenic"
                dist = "+%d"%(abs(int(self.tx_start) - breakpoint)) #downstream

        elif breakpoint > int(self.tx_end):
            if self.strand == "+":
                region = "intergenic"
                dist = "+%d"%(abs(int(self.tx_start) - breakpoint)) #downstream
            elif self.strand == "-":
                region = "intergenic"
                dist = "-%d"%(abs(int(self.tx_start) - breakpoint)) #upstream
        else:
            for r in self.regions:
                s, e = self.regions[r]
                s = int(s)
                e = int(e)
                if (breakpoint >= s and breakpoint <= e) or (breakpoint >= e and breakpoint <= s):
                    region = r
                    dist = min(abs(s - breakpoint), abs(e - breakpoint))
        return (region, dist)

refgene_dict = defaultdict(lambda: defaultdict())
for line in open(f"{Dir4DB}/hg38_refGene.txt", "r"):
    line =  line.strip()
    ref_class = refgene(line)
    ref_class.get_exon_intron()
    refgene_dict[ref_class.chr][ref_class.tx] = ref_class

first = True
title_ind = defaultdict()
break_dict = defaultdict(lambda: defaultdict(lambda: "-"))
for line in open(annovar, "r"):
    fields = line.strip().split("\t")
    if first:
        for i, j in enumerate(fields):
            title_ind[j] = i
        first = False
        continue
    svid = fields[title_ind["Otherinfo1"]]
    chr = fields[title_ind["Chr"]]
    pos = fields[title_ind["Start"]]
    txes = fields[title_ind["Gene.refGene"]].split(";")
    #txes = fields[title_ind["Gene"]].split(";")
    anno_gene = list()
    anno_tx = list()
    anno_region = list()
    anno_dis = list()
    for tx in txes:
        if tx != "NONE":
            #if not refgene_dict[chr][tx]:
            if not tx in refgene_dict[chr]:
                print("%s does not exist"%(tx))
                #sys.exit()
                continue
            ref_class = refgene_dict[chr][tx]
            region, dis = ref_class.locate_breakpoint_region(int(pos))
            anno_gene.append(ref_class.gene)
            anno_tx.append(tx)
            anno_region.append(region)
            anno_dis.append(str(dis))
    genes = ";".join(anno_gene)
    txes = ";".join(anno_tx)
    regions = ";".join(anno_region)
    dises = ";".join(anno_dis)

    if break_dict[svid]["gene1"] != "-":
        break_dict[svid]["gene2"] = genes
        break_dict[svid]["tx2"] = txes
        break_dict[svid]["chr2"] = chr
        break_dict[svid]["pos2"] = pos
        break_dict[svid]["func2"] = regions
        break_dict[svid]["dist2"] = dises
    else:
        break_dict[svid]["gene1"] = genes
        break_dict[svid]["tx1"] = txes
        break_dict[svid]["chr1"] = chr
        break_dict[svid]["pos1"] = pos
        break_dict[svid]["func1"] = regions
        break_dict[svid]["dist1"] = dises

output = open(sys.argv[2], "w")
output.write("\t".join(["SVID", "Chrom1", "Pos1", "Gene1", "Tx1", "Func1", "Dis1", "Chrom2", "Pos2", "Gene2", "Tx2", "Func2", "Dis2"]) + "\n")
for svid in break_dict:
    output.write("\t".join([svid, break_dict[svid]["chr1"], break_dict[svid]["pos1"], break_dict[svid]["gene1"], 
                            break_dict[svid]["tx1"], break_dict[svid]["func1"], break_dict[svid]["dist1"],
                            break_dict[svid]["chr2"], break_dict[svid]["pos2"], break_dict[svid]["gene2"], 
                            break_dict[svid]["tx2"], break_dict[svid]["func2"], break_dict[svid]["dist2"]]) + "\n")
