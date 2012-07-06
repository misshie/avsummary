#!/bin/sh
cmd="/opt/annovar/annotate_variation.pl"
db="/opt/annovar-humandb"
# SNV
${cmd} --outfile RefGene --geneanno --refver hg19  ${db}
${cmd} --outfile EnsGene --geneanno --refver hg19  ${db}
${cmd} --outfile CytoBand --regionanno --refver hg19 --dbtype cytoband  ${db}
${cmd} --outfile miRNA --regionanno --refver hg19 --dbtype mirna  ${db}
${cmd} --outfile miRNAtarget --regionanno --refver hg19 --dbtype mirnatarget  ${db}
${cmd} --outfile SegDup --regionanno --refver hg19 --dbtype segdup  ${db}
${cmd} --outfile DGV --regionanno --refver hg19 --dbtype dgv  ${db}
${cmd} --outfile CG69 --filter --refver hg19 --dbtype generic --genericcdbfile hg19_cg69.txt  ${db}
${cmd} --outfile dbSNP135 --filter --refver hg19 --dbtype snp135  ${db}
${cmd} --outfile dbSNP135Common --filter --refver hg19 --dbtype snp135Common  ${db}
${cmd} --outfile ESP5400_all --filter --refver hg19 --dbtype generic --genericcdbfile hg19_esp54_all.txt  ${db}
${cmd} --outfile 1000g2012Feb_all --filter --refver hg19 --dbtype 1000g2012feb_all  ${db}
# INDEL
${cmd} --outfile RefGene --geneanno --refver hg19  ${db}
${cmd} --outfile EnsGene --geneanno --refver hg19  ${db}
${cmd} --outfile CytoBand --regionanno --refver hg19 --dbtype cytoband  ${db}
${cmd} --outfile miRNA --regionanno --refver hg19 --dbtype mirna  ${db}
${cmd} --outfile miRNAtarget --regionanno --refver hg19 --dbtype mirnatarget  ${db}
${cmd} --outfile SegDup --regionanno --refver hg19 --dbtype segdup  ${db}
${cmd} --outfile DGV --regionanno --refver hg19 --dbtype dgv  ${db}
${cmd} --outfile CG69 --filter --refver hg19 --dbtype generic --genericcdbfile hg19_cg69.txt  ${db}
${cmd} --outfile dbSNP135 --filter --refver hg19 --dbtype snp135  ${db}
${cmd} --outfile dbSNP135Common --filter --refver hg19 --dbtype snp135Common  ${db}
${cmd} --outfile ESP5400_all --filter --refver hg19 --dbtype generic --genericcdbfile hg19_esp54_all.txt  ${db}
${cmd} --outfile 1000g2012Feb_all --filter --refver hg19 --dbtype 1000g2012feb_all  ${db}
