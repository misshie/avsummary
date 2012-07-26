#!/bin/bash
cmd="/opt/annovar-2012May25/annotate_variation.pl"
db="/opt/annovar-humandb"
# SNV
mkdir -p SNV
${cmd} --outfile SNV/CytoBand --regionanno --buildver hg19 --dbtype cytoband snv500.av ${db} 2> SNV/CytoBand.log
${cmd} --outfile SNV/RefGene --geneanno --buildver hg19 --dbtype refgene snv500.av ${db} 2> SNV/RefGene.log
${cmd} --outfile SNV/EnsGene --geneanno --buildver hg19 --dbtype ensgene snv500.av ${db} 2> SNV/EnsGene.log
${cmd} --outfile SNV/GENCODE_basic_V7 --geneanno --buildver hg19 --dbtype wgEncodeGencodeBasicV7 snv500.av ${db} 2> SNV/GENCODE_basic_V7.log
${cmd} --outfile SNV/miRNA --regionanno --buildver hg19 --dbtype mirna snv500.av ${db} 2> SNV/miRNA.log
${cmd} --outfile SNV/miRNAtarget --regionanno --buildver hg19 --dbtype mirnatarget snv500.av ${db} 2> SNV/miRNAtarget.log
${cmd} --outfile SNV/SegDup --regionanno --buildver hg19 --dbtype segdup snv500.av ${db} 2> SNV/SegDup.log
${cmd} --outfile SNV/DGV --regionanno --buildver hg19 --dbtype dgv snv500.av ${db} 2> SNV/DGV.log
${cmd} --outfile SNV/dbSNP135 --filter --buildver hg19 --dbtype snp135 snv500.av ${db} 2> SNV/dbSNP135.log
${cmd} --outfile SNV/CG69 --filter --buildver hg19 --dbtype generic --genericdbfile hg19_cg69.txt snv500.av ${db} 2> SNV/CG69.log
${cmd} --outfile SNV/ESP6500_all --filter --buildver hg19 --dbtype generic --genericdbfile hg19_esp6500_all.txt snv500.av ${db} 2> SNV/ESP6500_all.log
# INDEL
mkdir -p INDEL
${cmd} --outfile INDEL/CytoBand --regionanno --buildver hg19 --dbtype cytoband indel500.av ${db} 2> SNV/CytoBand.log
${cmd} --outfile INDEL/RefGene --geneanno --buildver hg19 --dbtype refgene indel500.av ${db} 2> SNV/RefGene.log
${cmd} --outfile INDEL/EnsGene --geneanno --buildver hg19 --dbtype ensgene indel500.av ${db} 2> SNV/EnsGene.log
${cmd} --outfile INDEL/GENCODE_basic_V7 --geneanno --buildver hg19 --dbtype wgEncodeGencodeBasicV7 indel500.av ${db} 2> SNV/GENCODE_basic_V7.log
${cmd} --outfile INDEL/miRNA --regionanno --buildver hg19 --dbtype mirna indel500.av ${db} 2> SNV/miRNA.log
${cmd} --outfile INDEL/miRNAtarget --regionanno --buildver hg19 --dbtype mirnatarget indel500.av ${db} 2> SNV/miRNAtarget.log
${cmd} --outfile INDEL/SegDup --regionanno --buildver hg19 --dbtype segdup indel500.av ${db} 2> SNV/SegDup.log
${cmd} --outfile INDEL/DGV --regionanno --buildver hg19 --dbtype dgv indel500.av ${db} 2> SNV/DGV.log
${cmd} --outfile INDEL/dbSNP135 --filter --buildver hg19 --dbtype snp135 indel500.av ${db} 2> SNV/dbSNP135.log
${cmd} --outfile INDEL/CG69 --filter --buildver hg19 --dbtype generic --genericdbfile hg19_cg69.txt indel500.av ${db} 2> SNV/CG69.log
${cmd} --outfile INDEL/ESP6500_all --filter --buildver hg19 --dbtype generic --genericdbfile hg19_esp6500_all.txt indel500.av ${db} 2> SNV/ESP6500_all.log
