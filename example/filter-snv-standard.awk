#!/bin/awk
BEGIN {
    cnum["key"]=1
    cnum["av_chr"]=2
    cnum["av_start"]=3
    cnum["av_end"]=4
    cnum["av_ref"]=5
    cnum["av_alt"]=6
    cnum["CHROM"]=7
    cnum["POS"]=8
    cnum["ID"]=9
    cnum["REF"]=10
    cnum["ALT"]=11
    cnum["QUAL"]=12
    cnum["FILTER"]=13
    cnum["INFO"]=14
    cnum["FORMAT"]=15
    cnum["sample"]=16
    cnum["CytoBand"]=17
    cnum["RefGene_vf1"]=18
    cnum["RefGene_vf2"]=19
    cnum["RefGene_evf1"]=20
    cnum["RefGene_evf2"]=21
    cnum["EnsGene_vf1"]=22
    cnum["EnsGene_vf2"]=23
    cnum["EnsGene_evf1"]=24
    cnum["EnsGene_evf2"]=25
    cnum["GENCODE_basicV7_vf1"]=26
    cnum["GENCODE_basicV7_vf2"]=27
    cnum["GENCODE_basicV7_evf1"]=28
    cnum["GENCODE_basicV7_evf2"]=29
    cnum["miRNA"]=30
    cnum["miRNAtarget"]=31
    cnum["SegDup"]=32
    cnum["DGV"]=33
    cnum["dbSNP135"]=34
    cnum["CG69"]=35
    cnum["ESP6500_all"]=36
    cnum["1000g2012Feb_all"]=37
    #
    AAFREQ = 0.005
}


function is_qualified(cols, cnum) {
    if (					\
	(cols[cnum["QUAL"]] > 100) &&		\
	(cols[cnum["FILTER"]] == "PASS")	\
	) {
	return(1)
    } else {
	return(0)
    }
}	     

function is_polymorphic(cols, cnum) {
    if (								\
	(cols[cnum["CG69"]] != "none" &&				\
	 cols[cnum["CG69"]] > AAFREQ)					\
	|| 								\
	(cols[cnum["ESP6500_all"]] != "none" &&				\
	 cols[cnum["ESP6500_all"]] > AAREQ)				\
	||								\
	(cols[cnum["1000g2012Feb_all"]] != "none" &&			\
	 cols[cnum["1000g2012Feb_all"]] > AAFREQ)			\
	) {
	return(1)
    } else {
	return(0)
    }
}

function is_any_gene_malignant(cols, cnum) {
    if	(								\
	(cols[cnum["RefGene_vf1"]] ~ /splicing/ ||			\
	 cols[cnum["RefGene_evf1"]] ~ /nonsynonymous/ ||		\
	 cols[cnum["RefGene_evf1"]] ~ /stop/ ||				\
	 cols[cnum["EnsGene_vf1"]] ~ /splicing/ ||			\
	 cols[cnum["EnsGene_evf1"]] ~ /nonsynonymous/ ||		\
	 cols[cnum["EnsGene_evf1"]] ~ /stop/ ||				\
	 cols[cnum["GENCODE_basicV7_vf1"]] ~ /splicing/ ||		\
	 cols[cnum["GENCODE_basicV7_evf1"]] ~ /nonsynonymous/ ||	\
	 cols[cnum["GENCODE_basicV7_evf1"]] ~ /stop/)			\
	||								\
	(cols[cnum["RefGene_evf1"]] ~ /unkwnown/ &&			\
	 cols[cnum["EnsGene_evf1"]] ~ /unkwnown/ &&			\
	 cols[cnum["GENCODE_basicV7_evf1"]] ~ /unkwnown/)		\
	) {
	return(1)
    } else {
	return(0)
    }
}

function is_validatable(cols, cnum) {
    if (cols[cnum["SegDup"]] ~ /none/)
    {
	return(1)
    } else {
	return(0)
    }
}

### main loop
{ split($0,cols,"\t") }
/^\#/ { print; next }

{
    if (					\
	is_qualified(cols,cnum) &&		\
	!is_polymorphic(cols,cnum) &&		\
	is_any_gene_malignant(cols, cnum) &&	\
	is_validatable(cols, cnum)		\
	) {
	print
    }
}
