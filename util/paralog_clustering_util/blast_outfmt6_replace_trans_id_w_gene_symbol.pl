#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "\n\n\tusage: $0 search_db.fasta  blast_results.outfmt6\n\n";

my $search_db = $ARGV[0] or die $usage;
my $blast_outfmt6 = $ARGV[1] or die $usage;


main: {

    my %trans_to_gene_symbol = &parse_headers($search_db);


    open (my $fh, $blast_outfmt6) or die "Error, cannot open file $blast_outfmt6";
    while (<$fh>) {
        if (/^\#/) { next; }
        chomp;
        my @x = split(/\t/);
        my $transA = $x[0];
        my $geneA = $trans_to_gene_symbol{$transA} or die "Error, no gene for $transA";
        my $transB = $x[1];
        my $geneB = $trans_to_gene_symbol{$transB} or die "Error, no gene for $transB";
        
        $x[0] = $geneA;
        $x[1] = $geneB;

        if ($geneA ne $geneB) {
            print join("\t", @x) . "\n";
        }
    }
    close $fh;

    exit(0);


}


####
sub parse_headers {
    my ($search_db) = @_;

    my %trans_to_sym;

    open (my $fh, $search_db) or die "Error, cannot open file $search_db";
    while (<$fh>) {
        chomp;
        if (/^>/) {
            s/>//;
            my ($trans_id, $gene_id, $gene_sym) = split(/\s+/);
            
            unless (defined $gene_sym) {
                $gene_sym = $gene_id;
            }
            
            $trans_to_sym{$trans_id} = $gene_sym;
        }
    }

    close $fh;


    return(%trans_to_sym);
}
