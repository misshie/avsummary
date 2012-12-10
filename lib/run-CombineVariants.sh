java="/usr/java/default/bin/java"
javamemory="42g"
javatemp="/data/scratch"
gatk_dir="/opt/GenomeAnalysisTK-2.2-2-gf44cc4e"
gatk_jar="${gatk_dir}/GenomeAnalysisTK.jar"
reference="/data/Genomes/human_hg19_GRCh37/hg19.hg1x.fasta"

output="integrated.vcf"
${java} \
    -Xmx${javamemory} \
    -Djava.io.tmpdir=${javatemp} \
    -jar ${gatk_jar} \
    -T CombineVariants \
    -R ${reference} \
    -o ${output} \
    --minimumN 1 \
    --filteredAreUncalled \
    --printComplexMerges \
    --variant sample1.indel.vcf \
    --variant sample1.snv.vcf \
    --variant sample2.indel.vcf \
    --variant sample2.snv.vcf \
    -genotypeMergeOptions UNSORTED \
    > ${output}.log 2>&1

ruby vcf-gtselect.rb show integrated.vcf
