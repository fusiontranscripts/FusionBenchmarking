#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "\n\n\tusage: $0 preds.collected.wAnnot\n\n";

my $preds_file = $ARGV[0] or die $usage;

open (my $fh, $preds_file) or die "Error, cannot open file $preds_file";
while(<$fh>) {
    my $line = $_;
    my @x = split(/\t/);
    my $fusion_name = $x[2];
    my $annot = $x[7];
    
    if ($fusion_name =~ /HLA/ 
        ||
        ($annot && 
         ($annot =~ /chrM:/i
          ||
          $annot =~ /NEIGHBOR/
          ||
          $annot =~ /BLAST/
          ||
          $annot =~ /GTEx|BodyMap|DGD_PARALOGS|HGNC_GENEFAM|Greger_Normal|Babiceanu_Normal|ConjoinG/
          ||
          $fusion_name =~ /IG[HKL].*--IG[HKL]/   
         )
        )
        ) 
    {
        next;
    }
    print $line;
}

exit(0);

