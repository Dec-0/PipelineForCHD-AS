import os
import sys
import re
from collections import defaultdict

invcf = sys.argv[1]
dgv = sys.argv[2]
out = sys.argv[3]

output = open(out, "w")
output.write("\t".join(["SVID", "CHDdb_Evidence", "CHDdb_Consequence", "CHDdb_associatedCHD", 
	"CHDdb_Syndrome", "CHDdb_Result", "CHDdb_DBOverlapPercents", "CHDdb_DBMinPercents", "CHDdb_DBMaxPercents", "CHDdb_CurrentOverlapPercents", "CHDdb_CurrentMinPercents", "CHDdb_CurrentMaxPercents", "CHDdb_MinPercents", "CHDdb_MaxPercents"]) + "\n") 

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

# CHD database
chd_dict = defaultdict(lambda: defaultdict(lambda: defaultdict()))
first = True
for line in open(dgv, "r"):
	fields = line.strip().split("\t")
	if first:
		first = False
		continue
	Items = fields[1].split(":")
	if len(Items) < 2:
		continue
	Items[0] = re.sub('^chr','',Items[0],flags = re.I)
	if len(Items) == 2:
		Result = re.search('([\d\D]+\d)([^\d]+)$',Items[1])
		if Result is None:
			continue
		MInfo1 = Result.group(1)
		MInfo2 = Result.group(2)
		Items[1] = MInfo1
		Items.append(MInfo2)
	chd_dict[Items[0]][Items[1]]["evidence"] = fields[0]
	chd_dict[Items[0]][Items[1]]["consequence"] = fields[5]
	chd_dict[Items[0]][Items[1]]["chd"] = fields[12]
	chd_dict[Items[0]][Items[1]]["syndrome"] = fields[13]
	chd_dict[Items[0]][Items[1]]["result"] = fields[14]

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
		if svtype in ["DEL", "DUP", "INS"]:
			chr = fields[0]
			start = fields[1]
			flag = False
			chd_evis = list()
			chd_cons = list()
			chd_chds = list()
			chd_syns = list()
			chd_res = list()
			chd_overdb = list()
			chd_overcurrent = list()
			# same chr
			if chr in chd_dict:
				for d_pos in chd_dict[chr]:
					chd_con = chd_dict[chr][d_pos]["consequence"]
					if svtype == "DEL" and ("deletion" in chd_con):
						pass
					elif svtype == "DUP" and ("duplication" in chd_con):
						pass
					elif svtype == "INS" and ("insertion" in chd_con):
						pass
					else:
						continue
					d_start, d_end = d_pos.split("-")
					overlap = get_overlap(list(map(int, [start, end, d_start, d_end])))
					# collect all overlap info (perhaps more than 1)
					if overlap:
						# format %.4f
						PercentOnDB = str("%.3f" % float((overlap[1] - overlap[0] + 1) / (int(d_end) - int(d_start) + 1)))
						PercentOnCurrent = str("%.3f" % float((overlap[1] - overlap[0] + 1) / (int(end) - int(start) + 1)))
						if float(PercentOnDB) > 0 and float(PercentOnCurrent) > 0:
							chd_evis.append(chd_dict[chr][d_pos]["evidence"])
							chd_cons.append(chd_dict[chr][d_pos]["consequence"])
							chd_chds.append(chd_dict[chr][d_pos]["chd"])
							chd_syns.append(chd_dict[chr][d_pos]["syndrome"])
							chd_res.append(chd_dict[chr][d_pos]["result"])
							chd_overdb.append(PercentOnDB)
							chd_overcurrent.append(PercentOnCurrent)
			if chd_evis:
				evis = ";".join(chd_evis)
				cons = ";".join(chd_cons)
				chds = ";".join(chd_chds)
				syns = ";".join(chd_syns)
				res = ";".join(chd_res)
				overdb = ";".join(chd_overdb)
				overcurrent = ";".join(chd_overcurrent)
				# max and min overdb
				(MinDb, MaxDb) = (chd_overdb[0], chd_overdb[0])
				for i in range(len(chd_overdb)):
					if float(chd_overdb[i]) < float(MinDb):
						MinDb = chd_overdb[i]
					if float(chd_overdb[i]) > float(MaxDb):
						MaxDb = chd_overdb[i]
				# max and min overcurrent
				(MinCurrent, MaxCurrent) = (chd_overcurrent[0], chd_overcurrent[0])
				for i in range(len(chd_overcurrent)):
					if float(chd_overcurrent[i]) < float(MinCurrent):
						MinCurrent = chd_overcurrent[i]
					if float(chd_overcurrent[i]) > float(MaxCurrent):
						MaxCurrent = chd_overcurrent[i]
				(MinAll, MaxAll) = (MinDb, MaxDb)
				if float(MinCurrent) < float(MinAll):
					MinAll = MinCurrent
				if float(MaxCurrent) > float(MaxAll):
					MaxAll = MaxCurrent
				output.write("\t".join(list(map(str, [fields[2], evis, cons, chds, syns, res, overdb, MinDb, MaxDb, overcurrent, MinCurrent, MaxCurrent, MinAll, MaxAll]))) + "\n")