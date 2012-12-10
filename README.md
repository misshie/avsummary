#AvSummary
##Introduction
GATK & ANNOVAR workflow tools 

## avsummary.rb
At first, accoding to the 'avconfig' file using Ruby DSL, 'ruby avsummary.rb annotate' generates two shell script files: a shell script to convert one-sample-per-file vcf files for SNVs and INDELs to ANNOVAR's input file (avsummary annotate) and a shellscript to run annotate-variation.pl. After runnning these shell scripts, execute 'ruby avsummary.rb integrate' and get an integrated table. You can filter the intehrated table using awk scripts. 

## vcf-gtselect.rb & vcf-locusselect.rb
If locus-based (physical position-based) set intersection or subtraction is necessary, please try GATK's ConvertAnnotation and run vcf-gtselect.rb to select locus. Locus-wise statistics (such as QUAL) can be restore using vcf-locusselect.rb

## genewise.rb
Using gene-prediction annotation (such as GENCODEv12), gene-wise summarization and sample superimposition can be performed using genewise.rb

##Warning
I am sorry for poor documentation. Feel free to contact me to ask how to use.

Copyright (c) 2012 Hiroyuki Mishima. See LICENSE.txt for
further details.

