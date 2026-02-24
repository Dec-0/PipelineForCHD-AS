#!/usr/bin/python
# -*- coding: UTF-8 -*-
import sys
import commands

def main():
	Sample = sys.argv[1]
	File4Summary = sys.argv[2]
	File4Threshold = sys.argv[3]
	File4Stat = sys.argv[4]
	Bin4csvtk = sys.argv[5]
	
	mean_depth = commands.getoutput("""tail -n1 %s|awk '{{print $4}}' """%(File4Summary))
	coverage = commands.getoutput("""%s summary -C "$" -t -f 5:sum,6:sum,7:sum,8:sum,9:sum,10:sum,11:sum %s"""%(Bin4csvtk, File4Threshold))
	coverage_percent = ["%0.2f"%(float(i)/2934704722*100) for i in coverage.split("\n")[1].split()]
	with open(File4Stat, "w") as out:
		out.write("\t".join(["Sample", "Mean Depth (x)", "Coverage", "Coverage at least>5x", "Coverage at least>10x", "Coverage at least>15x", "Coverage at least>20x", "Coverage at least>25x", "Coverage at least>30x"]) + "\n")
		out.write("\t".join([Sample, str(mean_depth)] + coverage_percent) + "\n")

if __name__ == '__main__':
	main()