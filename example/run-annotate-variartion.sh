#!/bin/bash
set -e
cmd="/opt/annovar/annotate_variation.pl"
db="/opt/annovar-humandb"
# SNV
mkdir -p SNV
${cmd} --outfile SNV/CytoBand --regionanno --buildver hg19 --dbtype cytoband snv500.av ${db} 2> SNV/CytoBand.log
${cmd} --outfile SNV/RefGene --geneanno --buildver hg19 --dbtype refgene snv500.av ${db} 2> SNV/RefGene.log
${cmd} --outfile SNV/EnsGene --geneanno --buildver hg19 --dbtype ensgene snv500.av ${db} 2> SNV/EnsGene.log
${cmd} --outfile SNV/GENCODE_basic_V7 --geneanno --buildver hg19 --dbtype wgEncodeGencodeBasicV7 snv500.av ${db} 2> SNV/GENCODE_basic_V7.log
${cmd} --outfile SNV/miRNA --regionanno --buildver hg19 --dbtype mirna snv500.av ${db} 2> SNV/miRNA.log
${cmd} --outfile SNV/miRNAtarget --regionanno --buildver hg19 --dbtype mirnatarget snv500.av ${db} 2> SNV/miRNAtarget.log
# INDEL
mkdir -p INDEL
${cmd} --outfile INDEL/CytoBand --regionanno --buildver hg19 --dbtype cytoband indel500.av ${db} 2> SNV/CytoBand.log
${cmd} --outfile INDEL/RefGene --geneanno --buildver hg19 --dbtype refgene indel500.av ${db} 2> SNV/RefGene.log
${cmd} --outfile INDEL/EnsGene --geneanno --buildver hg19 --dbtype ensgene indel500.av ${db} 2> SNV/EnsGene.log
${cmd} --outfile INDEL/GENCODE_basic_V7 --geneanno --buildver hg19 --dbtype wgEncodeGencodeBasicV7 indel500.av ${db} 2> SNV/GENCODE_basic_V7.log
${cmd} --outfile INDEL/miRNA --regionanno --buildver hg19 --dbtype mirna indel500.av ${db} 2> SNV/miRNA.log
${cmd} --outfile INDEL/miRNAtarget --regionanno --buildver hg19 --dbtype mirnatarget indel500.av ${db} 2> SNV/miRNAtarget.log
