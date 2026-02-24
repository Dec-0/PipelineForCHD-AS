#!/usr/bin/python
import argparse
import os
import sys
import xlwt


class MyParser(argparse.ArgumentParser):
	def error(self, message):
		sys.stderr.write('error: %s\n' % message)
		self.print_help()
		sys.exit(2)

class TxtFileGet():
	def __init__(self, ArgsIn, ArgsDir):
		self.File = ArgsIn
		self.Dir = ArgsDir
		
	def DirFileGet(self,tDir):
		for Item in os.listdir(tDir):
			tPath = os.path.join(tDir, Item)
			if os.path.isdir(tPath):
				self.DirFileGet(tPath)
			else:
				self.Items.append(tPath)
				
	def FileGet(self):
		self.Items = []
		if self.File:
			for InFile in self.File:
				if os.path.isfile(InFile):
					self.Items.append(InFile)
				else:
					print("File not exist (%s)." % InFile)
					sys.exit(2)
		
		if self.Dir:
			for InDir in self.Dir:
				if os.path.isdir(InDir):
					self.DirFileGet(InDir)
				else:
					print("Directory not exist (%s)." % InDir)
					sys.exit(2)
		
		self.FinalName = []
		self.FinalPath = []
		for File in self.Items:
			BaseName = os.path.basename(File)
			if BaseName not in self.FinalName:
				self.FinalName.append(BaseName)
				self.FinalPath.append(File)
				print("[ File waiting for converting ] %s" % BaseName)
			else:
				print("[ Duplicate ] %s" % BaseName)
				sys.exit(2)
		
		return self.FinalPath

def ExcelSave(TxtFiles,LogFile,IfTrunc):
	WorkBook = xlwt.Workbook(encoding='utf-8')
	if IfTrunc:
		print("[ Info ] Trunc Mode")
	else:
		print("[ Info ] No Trunc")
	for File in TxtFiles:
		BaseName = os.path.basename(File)
		WorkSheet = WorkBook.add_sheet(BaseName)
		Lines = open(File,'r').readlines()
		RowId = 0
		for Line in Lines:
			Line = Line.strip()
			Cols = Line.split('\t')
			for ColId in range(0, len(Cols)):
				if len(Cols[ColId]) > 32767 and IfTrunc:
					Cols[ColId] = Cols[ColId][0:32747]
					Cols[ColId] = Cols[ColId] + '(Truncated)'
				WorkSheet.write(RowId, ColId, label=Cols[ColId])
			RowId += 1
	WorkBook.save(LogFile)
	print("[ Info ] Converting is successful!")

def main():
	Descrip = '''
 Convert2Excel.py
 Auther: zhangdong_xie@foxmail.com
 
 This script was used to convert txt format files into one excel which can be opened normally by Office Suite in Windows.
 -i and -dir should specify only one.
 
 -t will trunc the strings number in a column to below 32767 characters
    will ignore rows number above 65536 lines
 
'''
	parser = MyParser(description=Descrip,formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument('-i',metavar='File' , help='( Required ) The files in txt format which will be converted into the sheets of a same excel.', dest='InFile', action='append')
	parser.add_argument('-dir',metavar='Dir' , help='( Required ) The directory in which all the files in txt format which will be converted into the sheets of a same excel.', dest='InDir', action='append')
	parser.add_argument('-o',metavar='ConvertedFile', help='( Required ) The generated excel file.', required=True, dest='Out', action='store')
	parser.add_argument('-t', help='( Optional ) If there is need to trunc the rows, columns and strings in column.', required=False, dest='IfTrunc', action='store_true')
	args = parser.parse_args()
	
	# -i and -dir must specified at least one;
	if not (args.InFile or args.InDir):
		print("Please specify -i or -dir (at least one or both)\n%s" % Descrip)
		sys.exit(2)
	if not args.Out:
		print("Please specify -o\n%s" % Descrip)
		sys.exit(2)
	
	# Get the files which are going to be transverted;
	fileget = TxtFileGet(args.InFile,args.InDir)
	TxtFiles = fileget.FileGet()
	
	# file converting;
	ExcelSave(TxtFiles,args.Out,args.IfTrunc)


if __name__ == '__main__':
	main()