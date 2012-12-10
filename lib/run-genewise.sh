#!/bin/sh

cat NagasakiAff1_snv.txt NagasakiAff1_indel.txt > NagasakiAff1.txt
cat NagasakiAff2_snv.txt NagasakiAff2_indel.txt > NagasakiAff2.txt
cat NagasakiAff3_snv.txt NagasakiAff3_indel.txt > NagasakiAff3.txt
cat NagasakiUnaff1_snv.txt NagasakiUnaff1_indel.txt > NagasakiUnaff1.txt

ruby ./genewise.rb \
    --genedb 26 \
    --genotype 16 \
    --output genewise-variants.txt \
    --summary genewise-summary.txt \
    aff1::NagasakiAff1.txt \
    aff2::NagasakiAff2.txt \
    aff3::NagasakiAff3.txt \
    unaff1::NagasakiUnaff1.txt \
    2> genewise.log
