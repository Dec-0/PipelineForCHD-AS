#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import os
import sys
import re
from pycirclize import Circos
from pycirclize.utils import ColorCycler, load_eukaryote_example_dataset
import numpy as np
from collections import defaultdict

class MyParser(argparse.ArgumentParser):
	def error(self, message):
		sys.stderr.write('error: %s\n' % message)
		self.print_help()
		sys.exit(2)

def LocalCircosDraw(SPNames, Files4Cov, File4Plot, MaxCount, WidthSize, GenType):
	# coverage info for each sample
	CovInfo = defaultdict(lambda : defaultdict(dict))
	
	for i in range(len(SPNames)):
		SP = SPNames[i]
		cov_file = Files4Cov[i]
		
		with open(cov_file,"r") as ch:
			Line = ch.readline()
			while Line:
				Cols = Line.strip('\n').split('\t')
				# filter chr in name
				Cols[0] = re.sub('^chr','',Cols[0],flags = re.I)
				if 'x' not in CovInfo[SP][Cols[0]].keys():
					CovInfo[SP][Cols[0]]['x'] = []
					CovInfo[SP][Cols[0]]['y'] = []
				
				if float(Cols[3]) > float(MaxCount[i]):
					CovInfo[SP][Cols[0]]['x'].append(Cols[1])
					CovInfo[SP][Cols[0]]['y'].append(MaxCount[i])
					Line = ch.readline()
					continue
				CovInfo[SP][Cols[0]]['x'].append(Cols[1])
				CovInfo[SP][Cols[0]]['y'].append(Cols[3])
				Line = ch.readline()
	
	# Circos Plot
	# Initialize Circos from BED chromosomes
	ThisDir = os.path.dirname(os.path.abspath(__file__))
	chr_bed_file = ThisDir + "/" + GenType + "_chr.bed"
	circos = Circos.initialize_from_bed(chr_bed_file, space = 3, start = 8, end = 352, endspace=False)
	circos.text("Homo sapiens\n(" + GenType + ")", size=15)

	# Create chromosome color dict
	ColorCycler.set_cmap("gist_rainbow")
	chr_names = [s.name for s in circos.sectors]
	colors = ColorCycler.get_color_list(len(chr_names))
	chr_name2color = {name: color for name, color in zip(chr_names, colors)}

	# Add cytoband tracks from cytoband file
	cytoband_file = ThisDir + "/" + GenType + "_cytoband.tsv"
	circos.add_cytoband_tracks((95, 100), cytoband_file)

	# draw
	Col4Track = ["tomato", "skyblue", "olive", "magenta", "lime", "grey", "blue"]
	for sector in circos.sectors:
		# Plot chromosome outer track
		sector.text(sector.name.replace("chr", ""))
		color = chr_name2color[sector.name]
		
		# Bar track
		TrackSize = 15
		if len(SPNames) > 1:
			TrackSize = 10
		for i in range(len(SPNames)):
			# Data
			Data4x = [int(x) for x in CovInfo[SPNames[i]][sector.name.replace("chr", "")]['x']]
			Data4y = [int(x) for x in CovInfo[SPNames[i]][sector.name.replace("chr", "")]['y']]
			TrackLeft = 93 - (i + 1) * TrackSize + 1
			TrackRight = 93 - i * TrackSize - 1
			track = sector.add_track((TrackLeft, TrackRight), r_pad_ratio=0.1)
			track.axis()
			track.bar(Data4x, Data4y, width = int(WidthSize) * 0.7, color = Col4Track[i], vmin = 0,vmax = float(MaxCount[i]))
			# Plot track labels
			if sector.name == circos.sectors[0].name:
				circos.text(SPNames[i], r = track.r_center, deg = 0, color = Col4Track[i], size=8)
	
	circos.savefig(File4Plot)

def main():
	CurrScriptName = os.path.basename(sys.argv[0])
	Descrip = ' ' + CurrScriptName + '''
 Auther: zhangdong_xie@foxmail.com
 
 This script was used to .
 
'''
	parser = MyParser(description=Descrip,formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument('-sp',metavar='' , help='( Required ) Sample name for each covearge file', required=True, dest='SPNames', action='append')
	parser.add_argument('-cov',metavar='' , help='( Required ) Files for coverage', required=True, dest='Files4Cov', action='append')
	parser.add_argument('-o',metavar='', help='( Required ) File for circos plot', required=True, dest='CircosPlot', action='store')
	parser.add_argument('-max',metavar='', help='( Required ) Max y value to show', required=True, dest='MaxCount', action='append')
	parser.add_argument('-binsize',metavar='', help='( Required ) Width size of bar plot', required=True, dest='WidthSize', action='store')
	parser.add_argument('-gen',metavar='', help='( Required ) Genome type like hg38 hg19', required=False, dest='GenType', action='store', default='hg38')
	args = parser.parse_args()
	
	LocalCircosDraw(args.SPNames, args.Files4Cov, args.CircosPlot, args.MaxCount, args.WidthSize, args.GenType)


if __name__ == '__main__':
	main()