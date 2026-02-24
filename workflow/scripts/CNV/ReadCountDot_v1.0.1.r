#!/usr/bin/Rscript

# 输入;
myArg <- commandArgs(FALSE)
BinDir = substring(myArg[grep('--file=',myArg)],8)
ScriptName = basename(BinDir)
BinDir = dirname(BinDir)
ArgsId = grep('--args',myArg)
ArgsId = ArgsId + 1
myArg = myArg[ArgsId:length(myArg)]
tLen=length(myArg)
if(length(myArg) < 10 || length(myArg) %% 5 != 0)
{
	options(warning.length = 3000)
	stop("The Arguments' number was not 10 or 5n + 5. (",tLen,")
	
	Example: Rscript ",ScriptName," Image.pdf WidthUnit HeightUnit MapInPage MaxCol Data.txt Title XLable YLable String4Y
	
	用于绘制基本的染色体区域点图。
	
	")
}
suppressMessages(library(ggplot2))
suppressMessages(library(grid))
suppressMessages(library(svglite))
library(scales)
set.seed(20240801)


ImgFile = myArg[1]
StrWidthUnit = myArg[2]
StrHeightUnit = myArg[3]
MapInPage = as.numeric(myArg[4])
MaxCol = as.numeric(myArg[5])
if (MapInPage < MaxCol) { MaxCol = MapInPage }
MaxRow = ceiling(MapInPage / MaxCol)
cat("[ Info ] Max Column is ",MaxCol,"\n")
cat("[ Info ] Max Row is ",MaxRow,"\n")

if ( StrWidthUnit != '-' ) { WidthUnit = as.numeric(StrWidthUnit) } else { WidthUnit = 15 }
if ( StrHeightUnit != '-' ) { HeightUnit = as.numeric(StrHeightUnit) } else { HeightUnit = 4 }
cat("[ Info ] WidthUnit is ",WidthUnit,"\n")
cat("[ Info ] HeightUnit is ",HeightUnit,"\n")
Svg = sub('pdf$','svg',ImgFile)
svglite(Svg,width = WidthUnit * MaxCol,height = HeightUnit * MaxRow,fix_text_size = FALSE)
svgH = dev.cur()
pdf(ImgFile,width = WidthUnit * MaxCol,height = HeightUnit * MaxRow)
dev.control("enable")
PInfo = matrix(data = NA, ncol = 3, byrow = FALSE, dimnames = NULL)

InitialId = (length(myArg) - 5) / 5 - 1
for (tId in c(0:InitialId))
{
	FromId = tId * 5 + 5
	File4Data = myArg[FromId + 1]
	Title = myArg[FromId + 2]
	XLab = myArg[FromId + 3]
	YLab = myArg[FromId + 4]
	Str4YAxis = myArg[FromId + 5]
	
	## 绘图区域
	ColNum = MaxCol
	RowNum = MaxRow
	PageTotal = MapInPage
	if (tId %% PageTotal == 0 && tId > 0) { grid.newpage() }
	ttId = tId %% PageTotal
	ShiftX = ttId %% ColNum
	ShiftY = floor(ttId / ColNum)
	XPos = (1 / ColNum) * (ShiftX + 0.5)
	YPos = 1 - (1 / RowNum) * (ShiftY + 0.5)
	MapWidth = 1 / ColNum
	MapHeight = (1 / RowNum) * 0.95
	GPos = viewport(x = XPos,y = YPos,width = MapWidth,height = MapHeight)
	
	## 假如该绘图区域需要置空
	if (File4Data == '-') { next }
	
	## 分类顺序
	Data = read.table(File4Data,header = T,sep = '\t',check.names = F, stringsAsFactors = F)
	if (dim(Data)[1] == 0) { next }
	Level4Chr = unique(Data$Chr)
	Data$Chr = as.factor(factor(Data$Chr,levels = Level4Chr[Level4Chr %in% Data$Chr]))
	cat("[ Info ] Levels for chr: ",paste(levels(Data$Chr),sep = ', '),"\n")
	
	## x轴标签
	XBreak = c(1)
	XLabel = c(as.character(Data$Chr[0]))
	BreakFrom = 0
	BreakTo = 0
	BreakId = 0
	PreTag = ''
	for (TagId in c(1:length(Data$Chr)))
	{
		if(Data$Chr[TagId] == PreTag)
		{
			BreakTo = BreakTo + 1
		} else {
			if(BreakId > 0)
			{
				XBreak[BreakId] = round((BreakFrom + BreakTo) / 2)
				XLabel[BreakId] = as.character(Data$Chr[TagId - 1])
			}
			BreakFrom = TagId
			BreakTo = TagId
			BreakId = BreakId + 1
			PreTag = Data$Chr[TagId]
		}
	}
	if(BreakId == 0)
	{
		BreakId = BreakId + 1
	}
	XBreak[BreakId] = round((BreakFrom + BreakTo) / 2)
	XLabel[BreakId] = as.character(Data$Chr[length(Data$Chr)])
	
	## 假如因子个数较少就用指定的颜色
	AllColors = c("#FFA54F","#63b8ff","#228B22","#CD5B45","#8B658B")
	TColor = c(AllColors[1])
	ColorId = 1
	for (TagId in c(1:length(Data$Chr)))
	{
		if(XLabel[ColorId] != Data$Chr[TagId])
		{
			ColorId = ColorId + 1
			if(ColorId > BreakId)
			{
				stop("---");
			}
		}
		TColor[TagId] = AllColors[1 + (ColorId - 1) %% 5]
	}
	
	## basic for ggplot2
	Data$RowId = c(1:dim(Data)[1])
	MedianY = median(Data$Value)
	Data$Value = Data$Value - MedianY
	MAD4 = 8 * mad(Data$Value)
	Data$Value[which(Data$Value > MAD4)] = MAD4
	GPlot = ggplot(Data,aes(x = RowId, y = Value, fill = Chr, group = Chr)) +
		geom_point(aes(colour = TColor), size = 0.1)
	
	## lab for x and y
	GPlot = GPlot + xlab(XLab) + ylab(YLab)
	if ( length(Title) > 0 && Title != '-' && Title != '' && Title != '\t' ) { GPlot = GPlot + ggtitle(Title) }
	GPlot = GPlot + scale_x_continuous(breaks = XBreak, labels = XLabel)
	if ( length(Str4YAxis) > 0 && Str4YAxis != '' && Str4YAxis != '-' ) {
		Num4YAxis = as.numeric(strsplit(Str4YAxis,',')[[1]])
		if (length(Num4YAxis) == 3) {
			GPlot = GPlot + scale_y_continuous(limits = c(Num4YAxis[1], Num4YAxis[2]),breaks=seq(Num4YAxis[1], Num4YAxis[2], Num4YAxis[3]))
		} else if (length(Num4YAxis) == 5) {
			GPlot = GPlot + scale_y_continuous(limits = c(Num4YAxis[1], Num4YAxis[2]),breaks=seq(Num4YAxis[3], Num4YAxis[4], Num4YAxis[5]))
		}
		PLabY = Num4YAxis[1] + 0.95 * (Num4YAxis[2] - Num4YAxis[1])
	} else {
		MinY = min(Data$Value)
		MaxY = max(Data$Value)
		MedianY = median(Data$Value)
		FinalMinY = MinY
		FinalMaxY = MaxY
		if (MaxY - MedianY > MedianY - MinY)
		{
			FinalMinY = MedianY - (MaxY - MedianY)
		}
		else if (MaxY - MedianY < MedianY - MinY)
		{
			FinalMaxY = MedianY + (MedianY - MinY)
		}
		GPlot = GPlot + scale_y_continuous(limits = c(FinalMinY,FinalMaxY))
	}
	
	## adjust
	GPlot = GPlot +
	theme(
		panel.border = element_blank(),
		panel.grid = element_blank(),
		panel.background = element_blank(),
		plot.margin = unit(c(0.5,0,0,0.5),"lines"),
		legend.title = element_blank(),
		legend.position = "none",
		plot.title = element_text(margin = margin(t = 0, r = 20, b = 20, l = 0),colour = "black",face = "bold",size = 16,hjust = 0.5),
		axis.line = element_line(colour = "black",linetype = 1,size = 0.6),
		axis.ticks.x = element_blank(),
		axis.ticks.y = element_line(colour = "black",linetype = 1,size = 0.6),
		axis.ticks.length = unit(-0.15, "lines"),
		axis.text = element_text(colour = "black",face = "bold",size = 6),
		axis.text.x = element_text(margin = unit(c(0.6,0,0,0), "lines"),angle = 45,hjust = 1,vjust = 1,size = 8,face = "bold"),
		axis.text.y = element_text(margin = unit(c(0,0.6,0,0), "lines"),size = 8),
		axis.title = element_text(colour = "black",face = "bold",size = 16)
	)
	print(GPlot,vp = GPos)
}
dev.copy(which = svgH)
dev.off()
dev.off()
