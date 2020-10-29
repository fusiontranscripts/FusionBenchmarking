#!/usr/bin/env perl

use strict;
use warnings;


my $usage = "\n\n\tusage: $0 blastn.outfmt6.grouped.geneSym.sorted\n\n** NOTE, MUST BE PRE-SORTED like so:\n"
    . "     cat blastn.outfmt6.grouped.geneSym | sort -k4,4g -k3,3gr > blastn.outfmt6.grouped.geneSym.sorted \n\n\n";

my $input_file = $ARGV[0] or die $usage;


main: {
    

    # m blastn.outfmt6.grouped.geneSym | sort -k4,4g -k3,3gr > blastn.outfmt6.grouped.geneSym.sorted


    my %data;
    
    open (my $fh, $input_file) or die "Error, cannot open file: $input_file";
    while (<$fh>) {
        my $line = $_;
        chomp;
        my @x = split(/\t/);
        my $geneA = $x[0];
        my $geneB = $x[1];
        
        my $token = join("$;", sort ($geneA, $geneB) );

        unless ($data{$token}) {
            $data{$token} = 1;
            print $line;
        }

    }

    exit(0);
}



        
