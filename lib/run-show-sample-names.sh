find . -name "*.vcf" | while read -r d; do echo $d; cat $d | grep '^\#CHROM'; done
