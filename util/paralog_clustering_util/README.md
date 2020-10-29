# Instructions for computing approximate paralog clusters and simpler blast match clusters for annotating suspicious fusion calls.

## blastn

    blastn -query ref_annot.cdna -db ref_annot.cdna -max_target_seqs 1000 -outfmt 6 -evalue 1e-10 -num_threads 20 -word_size 11  >  blast_pairs.outfmt6


## group segments

    outfmt6_add_percent_match_length.group_segments.pl  blast_pairs.outfmt6 ref_annot.cdna ref_annot.cdna > blast_pairs.outfmt6.grouped

## replace with gene symbols

    blast_outfmt6_replace_trans_id_w_gene_symbol.pl ref_annot.cdna blast_pairs.outfmt6.grouped > blast_pairs.outfmt6.grouped.genesym


# sort by Evalue asc, per_id desc
    
    cat  blast_pairs.outfmt6.grouped.genesym | sort -k4,4g -k3,3gr  > blast_pairs.outfmt6.grouped.genesym.sorted


# get top match for each

    get_top_blast_pairs.pl blast_pairs.outfmt6.grouped.genesym.sorted > blast_pairs.outfmt6.grouped.genesym.sorted.top

# perform Markov clustering

    outfmt6_add_percent_match_length.group_segments.to_Markov_Clustering.pl --outfmt6_grouped blast_pairs.outfmt6.grouped.genesym.sorted.top --min_pct_len 1 --min_per_id 90 --inflation_factor 5

    ln -s dump.out.blast_pairs.outfmt6.grouped.genesym.sorted.top.minLEN_1_pct_len.minPID_90.abc.mci.I50 paralog_clusters.txt


