#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "\n\n\tusage: $0 fusion_preds.collected progs_to_consider.txt\n\n";

my $preds_file = $ARGV[0] or die $usage;
my $progs_to_consider_file = $ARGV[1] or die $usage;

main: {

    my %progs_to_consider;
    {
        open(my $fh, $progs_to_consider_file) or die "Error, cannot open file $progs_to_consider_file";
        while (<$fh>) {
            s/^\s+|\s+$//g;
            my $prog = $_;
            $progs_to_consider{$prog} = 1;
        }
        close $fh;
    }
    
    my %fusion_to_prog;

    open (my $fh, $preds_file) or die "Error, cannot open file $preds_file";
    my $header = <$fh>;
    unless ($header =~ /^sample\tprog/) {
        die "Error, missing expected header in $preds_file";
    }
    while (<$fh>) {
        chomp;
        my ($sample_name, $prog, $fusion_name, $junc_support, $frag_support) = split(/\t/);

        unless ($progs_to_consider{$prog}) { next; }

        $fusion_name = uc $fusion_name;

        my ($genesA, $genesB) = split(/--/, $fusion_name);

        foreach my $geneA (split(/,/, $genesA)) {
            foreach my $geneB (split(/,/, $genesB)) {
                
                my $fusion_name_use = join("--", $geneA, $geneB);
                $fusion_name = "$sample_name|$fusion_name_use";
                
                $fusion_to_prog{$fusion_name}->{$prog} = 1;
            }
        }
    }
    close $fh;
    
    my @fusion_structs;
    foreach my $fusion_name (keys %fusion_to_prog) {
        my $progs_href = $fusion_to_prog{$fusion_name};
        
        my @prognames = sort keys %$progs_href;
        my $num_progs = scalar(@prognames);
        
        push (@fusion_structs, { fusion_name => $fusion_name,
                                 prognames => \@prognames,
                                 count => $num_progs,
              } );

    }

    @fusion_structs = reverse sort {$a->{count} <=> $b->{count} } @fusion_structs;

    foreach my $fusion_struct (@fusion_structs) {
        print join("\t", $fusion_struct->{fusion_name}, 
                   join(",", @{$fusion_struct->{prognames}}),
                   $fusion_struct->{count},
            ) . "\n";
    }

    exit(0);
}

