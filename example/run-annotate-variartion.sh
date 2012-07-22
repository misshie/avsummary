#!/bin/sh
cmd="/opt/annovar/annotate_variation.pl"
db="/opt/annovar-humandb"
# SNV
${cmd} --outfile CytoBand --regionanno --refver hg19 --dbtype cytoband snv500.av ${db}
# INDEL
${cmd} --outfile CytoBand --regionanno --refver hg19 --dbtype cytoband indel500.av ${db}
