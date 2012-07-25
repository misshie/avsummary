#!/bin/bash
set -e
cmd="/opt/annovar/annotate_variation.pl"
db="/opt/annovar-humandb"
# SNV
mkdir -p SNV
${cmd} --outfile SNV/CytoBand --regionanno --buildver hg19 --dbtype cytoband snv500.av ${db} 2> SNV/CytoBand.log
${cmd} --outfile SNV/dbSNP130 --filter --buildver hg19 --dbtype snp130 snv500.av ${db} 2> SNV/dbSNP130.log
# INDEL
mkdir -p INDEL
${cmd} --outfile INDEL/CytoBand --regionanno --buildver hg19 --dbtype cytoband indel500.av ${db} 2> SNV/CytoBand.log
${cmd} --outfile INDEL/dbSNP130 --filter --buildver hg19 --dbtype snp130 indel500.av ${db} 2> SNV/dbSNP130.log
