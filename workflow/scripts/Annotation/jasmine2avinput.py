import os
import sys
import re

def safe_open(file_name,mode):
	try:
		if not file_name.endswith('.gz'):
			return open(file_name,mode)
		else:
			import gzip
			return gzip.open(file_name,mode)
	except IOError:
		print(file_name + ' do not exist!')

class sniffles:
	def __init__(self, fields):
		self.chr = fields[0]
		self.start = fields[1]
		self.id = fields[2]
		for i in fields[7].split(";"):
			if i.startswith("SVTYPE="):
				self.svtype = i.split("=")[-1]
			elif i.startswith("END="):
				self.end = i.split("=")[-1]
		self.gt, self.gq, self.dr, self.dv = fields[9].split(":")[0:4]
		#self.gq = '.'
		if self.svtype == "BND":
			parts = re.split("[\[\]]", fields[4])
			for part in parts:
				if ":" in part:
					self.chr2, self.start2 = part.split(":")
		elif self.svtype == "TRA":
			for i in fields[7].split(";"):
				if i.startswith("CHR2="):
					self.chr2 = i.split("=")[-1]
				elif i.startswith("END="):
					self.start2 = i.split("=")[-1]

	def __str__(self):
		if self.svtype in ["DEL", "DUP", "INS"]:
			line = "\t".join([self.chr, self.start, self.end, "0", "-", self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			return line
		elif self.svtype == "BND":
			line1 = "\t".join([self.chr, self.start, str(int(self.start)+1), "0", "-", self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			line2 = "\t".join([self.chr2, self.start2, str(int(self.start2)+1), "0", "-", self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			return line1 + "\n" + line2
		elif self.svtype == "INV":
			line1 = "\t".join([self.chr, self.start, str(int(self.start)+1), "0", "-", self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			line2 = "\t".join([self.chr, self.end, str(int(self.end)+1), "0", "-", self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			return line1 + "\n" + line2
			
	def breakpoint_str(self):
		if self.svtype in ["DEL", "DUP"]:
			line1 = "\t".join([self.chr, self.start, self.start, "0", "-", self.id, self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			line2 = "\t".join([self.chr, self.end, self.end, "0", "-", self.id, self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			return line1 + "\n" + line2
		elif self.svtype == "BND" or self.svtype == "TRA":
			line1 = "\t".join([self.chr, self.start, str(int(self.start)+1), "0", "-", self.id, self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			line2 = "\t".join([self.chr2, self.start2, str(int(self.start2)+1), "0", "-", self.id, self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			return line1 + "\n" + line2
		elif self.svtype == "INV":
			line1 = "\t".join([self.chr, self.start, str(int(self.start)+1), "0", "-", self.id, self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			line2 = "\t".join([self.chr, self.end, str(int(self.end)+1), "0", "-", self.id, self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			return line1 + "\n" + line2
		elif self.svtype == "INS":
			line = "\t".join([self.chr, self.start, self.end, "0", "-", self.id, self.svtype, "GT=%s;GQ=%s;DR=%s;DV=%s"%(self.gt, self.gq, self.dr, self.dv)])
			return line

for line in safe_open(sys.argv[1], "r"):
	try:
		line = str(line, encoding = "utf-8")
	except:
		line = line
	if line.startswith("#"):
		continue
	fields = line.strip().split("\t")
	sc = sniffles(fields)
	#if sys.argv[2]:
	if len(sys.argv) > 2:
		print(sc.breakpoint_str())
	else:
		print(str(sc))
