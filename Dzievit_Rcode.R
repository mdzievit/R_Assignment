setwd("C:/Users/mdzievit.IASTATE/Dropbox/Classes/EEOB_546X/BCB546X-Spring2016/R_Assignment")
library(ggplot2)
library(tidyr)
library(dplyr)
library(reshape2)

##Load the 2 files into genotype and pos variables
genotype <- as.data.frame(read.table("fang_et_al_genotypes.txt", sep="\t",header=TRUE))
pos <- as.data.frame(read.table("snp_position.txt", sep="\t",header=TRUE))
str(genotype)
str(pos)

##Create a reduced variable of the pos. Only keep the SNP_ID, Chr, and Pos columns
redPos <- pos[,c(1,3,4)]
redPos[redPos == "unknown"] <- NA
redPos[redPos == "multiple"] <- NA
redPos$Chromosome <- as.numeric(as.character(redPos$Chromosome))
redPos$Position <- as.numeric(as.character(redPos$Position))

##Subset the genotype data into maize and teosinte groups
maize <- genotype[which(genotype$Group=="ZMMIL" | genotype$Group =="ZMMLR" | genotype$Group == "ZMMMR"),]
teosinte <-genotype[which(genotype$Group=="ZMPBA" | genotype$Group =="ZMPIL" | genotype$Group == "ZMPJA"),]

##This allows us to check what our expected sizes should be
genTable <- table(genotype$Group)
genTable <- plyr::ldply(genTable, rbind)
genTableMaize <- genTable[which(genTable$.id=="ZMMIL" | genTable$.id =="ZMMLR" | genTable$.id == "ZMMMR"),]
sum(genTableMaize$`1`)
dim(maize) ##Confirms they are the same size, maize has a label column

genTableTeosinte <- genTable[which(genTable$.id=="ZMPBA" | genTable$.id =="ZMPIL" | genTable$.id == "ZMPJA"),]
sum(genTableTeosinte$`1`)
dim(teosinte) ##Confirms they are the same size, teosinte has a label column

##Formatting the maize file to merge the redPos and maize file
maize <- maize[,c(-2,-3)]
maize <- t(maize)
maize <- cbind(rownames(maize),maize)
rownames(maize) <- NULL
colnames(maize) <- maize[1,]
maize <- maize[-1,]
maize <- as.data.frame(maize)
colnames(maize)[1] <- "SNP_ID" 
maizePos <- merge(redPos,maize,by = "SNP_ID")
maizePos[maizePos == "unknown"] <- NA
maizePos[maizePos == "multiple"] <- NA
maizePos <- maizePos %>% arrange(Chromosome,Position)

##Formatting the teosinte file to merge the redPos and maize file
teosinte <- teosinte[,c(-2,-3)]
teosinte <- t(teosinte)
teosinte <- cbind(rownames(teosinte),teosinte)
rownames(teosinte) <- NULL
colnames(teosinte) <- teosinte[1,]
teosinte <- teosinte[-1,]
teosinte <- as.data.frame(teosinte)
colnames(teosinte)[1] <- "SNP_ID" 
teosintePos <- merge(redPos,teosinte,by = "SNP_ID")
teosintePos[teosintePos == "unknown"] <- NA
teosintePos[teosintePos == "multiple"] <- NA
teosintePos <- teosintePos %>% arrange(Chromosome,Position)

##Loop to subset the data, replace correct characters, sort the data, and create 20 corresponding files
chr <- 1:10
for (i in chr) {
  holder <- as.matrix(maizePos[maizePos$Chromosome == i,])
  holder <- gsub("\\?/\\?","\\?",holder)
  holder <- na.omit(holder)
  if (1 < 10) { write.table(holder,file = paste("Maize_Chr0",i,"_increase.txt",sep=""),row.names = FALSE,sep = "\t",quote = FALSE) }
  else {write.table(holder,file = paste("Maize_Chr",i,"_increase.txt",sep=""),row.names = FALSE, sep = "\t",quote = FALSE)}
  
  holder2 <- maizePos[maizePos$Chromosome == i,]
  holder2 <- na.omit(holder2)
  holder2 <- holder2 %>% arrange(desc(Chromosome),desc(Position))
  holder2 <- as.matrix(holder2)
  holder2 <- gsub("\\?/\\?","-",holder2)
  if (1 < 10) { write.table(holder2,file = paste("Maize_Chr0",i,"_decrease.txt",sep=""),row.names = FALSE,sep = "\t",quote = FALSE) }
  else {write.table(holder2,file = paste("Maize_Chr",i,"_decrease.txt",sep=""),row.names = FALSE, sep = "\t",quote = FALSE)}
  
  holder <- as.matrix(maizePos[maizePos$Chromosome == i,])
  holder <- na.omit(holder)
  holder <- gsub("\\?/\\?","\\?",holder)
  if (1 < 10) { write.table(holder,file = paste("Maize_Chr0",i,"_increase.txt",sep=""),row.names = FALSE,sep = "\t",quote = FALSE) }
  else {write.table(holder,file = paste("Maize_Chr",i,"_decrease.txt",sep=""),row.names = FALSE, sep = "\t",quote = FALSE)}
  
  holder2 <- teosintePos[teosintePos$Chromosome == i,]
  holder2 <- na.omit(holder2)
  holder2 <- holder2 %>% arrange(desc(Chromosome),desc(Position))
  holder2 <- as.matrix(holder2)
  holder2 <- gsub("\\?/\\?","-",holder2)
  if (1 < 10) { write.table(holder2,file = paste("teosinte_Chr0",i,"_increase.txt",sep=""),row.names = FALSE,sep = "\t",quote = FALSE) }
  else {write.table(holder2,file = paste("teosinte_Chr",i,"_decrease.txt",sep=""),row.names = FALSE, sep = "\t",quote = FALSE)}
} 

rm(list=setdiff(ls(), c("genotype","redPos")))

##First plot Question
##Plot the SNP density

##Melt and convert the data. All hets converted to H and missing converted to N
genotype2 <- genotype[,-2]
melted <- melt(genotype2,id=c("Sample_ID","Group"))
colnames(melted)[3:4] <- c("SNP_ID","SNP_Call") 
meltedPos <- merge(redPos,melted,by = "SNP_ID")
convert <- function(x) {
  if ( x == "A/A" | x == "C/C" | x == "G/G" | x == "T/T") {
    return(x)
  }
  else if (x == "?/?") {
    return("N")
  }
  else {return("H")}
}
meltedPos$Converted <- lapply(meltedPos$SNP_Call,convert)
meltedPos$Converted <- as.character(meltedPos$Converted)
meltedPos <- na.omit(meltedPos) #Removed missing chr/pos data

##Grouping the data. Counting the number of occurences for each SNP type as they are grouped by everything
meltedPos3 <- meltedPos %>% group_by(SNP_ID,Group,Chromosome,Position,Converted) %>% summarize(n=n())
meltedPos3 <- meltedPos3 %>% arrange(Group,SNP_ID)

##Grouping the data again, but this summarizes the counts of SNP types. For example, SNP1 has A/A, H
##and T/T. This would get a count of 3, indicating the SNP is polymorphic at the site.
##Or we have N,A/A and would get a count of 2.
##We only counted for types over 1, and missing was considered to be an allele (INDEL) and
##Can contribute to allelic diversity across the genome. Counting over 1 considered that SNP informative
##for that group.
meltedPos4 <- meltedPos3 %>% group_by(SNP_ID,Group,Chromosome,Position) %>% summarize(n=n())
meltedPos5 <- meltedPos4 %>% group_by(Chromosome,Group) %>% filter(n>1) %>% summarize(n=n())

##Calculates the total number of SNPs present in the data to plot as a control.
posTable <- table(redPos$Chromosome)
posTableSum <- plyr::ldply(posTable, rbind)
colnames(posTableSum) <- c("Chromosome","Num_SNPs")
posTableSum$Chromosome <- as.numeric(as.character(posTableSum$Chromosome))
posTableSum <- cbind(posTableSum,c(rep("Total", times = 10)))
colnames(posTableSum)[2:3] <- c("n","Group")
posTableSum <- posTableSum[,c(1,3,2)]
posTableSum <- rbind.data.frame(posTableSum,meltedPos5)

##Plots the combined data, color codes by chromosome
ggplot(posTableSum,aes(x = Group,y = n,fill = Group)) + geom_bar(stat = "identity")  + 
  facet_wrap(~Chromosome, scales = "free_y",ncol=5,nrow=2) + theme_bw()+
  theme(axis.text.x = element_blank(),axis.ticks.x = element_blank())

rm(list=setdiff(ls(), c("genotype","redPos")))

## Question2
##Melted the data to work with
genotype2 <- genotype[,-2]
melted <- melt(genotype2,id=c("Sample_ID","Group"))
colnames(melted)[3:4] <- c("SNP_ID","SNP_Call") 
## Created a function to convert genotype data to 0,1,2
##1 = Homozygous, 2 = Heterozygous, 0 = Missing
convert2 <- function(x) {
  if ( x == "A/A" | x == "C/C" | x == "G/G" | x == "T/T") {
    return(1)
    }
  else if (x == "?/?") {
    return(0)
  }
  else {return(2)}
  }
melted$Converted <- lapply(melted$SNP_Call,convert2)
melted$Converted <- as.numeric(melted$Converted)
melted <- melted %>% arrange(Group, Sample_ID)

##This calculates the total number of SNPs, should be the same, but we can calculate it now
meltedTbl <- melted %>% group_by(Group,Sample_ID) %>% summarize(total = n())

##Calculates the number of SNPs within each group and merges it
meltedTblInd <- melted %>% group_by(Group,Sample_ID,Converted) %>% summarize(n=n())
meltedTblInd <- merge(meltedTblInd,meltedTbl,by = "Sample_ID")
meltedTblInd <- meltedTblInd[,-5]

##Calculates the percentage for each class and resorts the data
meltedTblInd$Percent <- meltedTblInd$n/meltedTblInd$total
colnames(meltedTblInd)[2] <- "Group"
meltedTblInd <- meltedTblInd %>% arrange(Group,Sample_ID)

#Relabels the converted to show up when it is facetted
meltedTblInd$Converted <- ordered(meltedTblInd$Converted,levels = c(0,1,2),
                                  labels = c("% Missing","% Homozygous","% Heterozygous")) 
colnames(meltedTblInd)[c(2)] <- c("Group")

##Plots the data, colors by group, and facets by snp class
ggplot(data = meltedTblInd, aes(x = Sample_ID, y = Percent,colour = Group)) + 
  geom_point() + facet_grid(~ Converted ) 

rm(list=setdiff(ls(), c("genotype","redPos")))

##3rd plot
##Melt and convert the data. All hets converted to H and missing converted to N
genotype2 <- genotype[,-2]
melted <- melt(genotype2,id=c("Sample_ID","Group"))
colnames(melted)[3:4] <- c("SNP_ID","SNP_Call") 
meltedPos <- merge(redPos,melted,by = "SNP_ID")
convert <- function(x) {
  if ( x == "A/A" | x == "C/C" | x == "G/G" | x == "T/T") {
    return(x)
  }
  else if (x == "?/?") {
    return("N")
  }
  else {return("H")}
}
meltedPos$Converted <- lapply(meltedPos$SNP_Call,convert)
meltedPos$Converted <- as.character(meltedPos$Converted)
meltedPos <- na.omit(meltedPos) #Removed missing chr/pos data
meltedPosGrp <- meltedPos[,c(2,5,7)] #Reduces columns, only want Chr, Grp, Converted SNP data

##Now I want to summarize by the different SNP types. I am interested in visualizing distrubution
##of SNPs across chromosomes and groups.
meltedPos2 <- meltedPos %>% group_by(Group,Chromosome,Converted) %>% summarize(n=n())
meltedPos2Total <- meltedPos %>% group_by(Group,Chromosome) %>% summarize(n=n())
colnames(meltedPos2Total)[3] <- "Total"

##Merges the counts and totals together to determine the percentage
meltedPos3 <- merge(meltedPos2,meltedPos2Total)
meltedPos3$Percent <- meltedPos3$n/meltedPos3$Total

##Plotting the data to visualize the percentage of SNP types across the genome
ggplot(data = meltedPos3, aes(x = Converted, y = Percent,fill = Group)) + 
  geom_bar(stat = "identity", position = "dodge") + 
  facet_wrap(~ Chromosome, nrow = 5, ncol = 2 ) + theme_bw() 
