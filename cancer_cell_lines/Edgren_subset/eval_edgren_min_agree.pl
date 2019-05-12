#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 preds.collected.gencode_mapped.wAnnot.filt.edgren min_agree\n\n";

my $input_file = $ARGV[0] or die $usage;
my $min_agree = $ARGV[1] or die $usage;

main: {

    my @progs_to_count = `cat ../progs_select.txt`;
    chomp @progs_to_count;
    
    my %progs_to_count = map { + $_ => 1 } @progs_to_count;
    
    
    open(my $fh, $input_file) or die $!;

    my %fusion_to_prog;
    my %orig_fusion_call;
    my %prognames;

    my $header = <$fh>;
    while(<$fh>) {
        chomp;
        my @x = split(/\t/);
        my $sample_name = $x[0];
        my $progname = $x[1];
        my $fusion_name = $x[2];

        my ($left_fusion_name, $right_fusion_name) = split(/--/, $fusion_name);
        
        $fusion_name = "$sample_name|$fusion_name";
        
        $prognames{$progname}++;
        
        my $alt_fusion_names_left = $x[5];
        my $alt_fusion_names_right = $x[6];

        my @left_entries = split(/,/, $alt_fusion_names_left);
        my @right_entries = split(/,/, $alt_fusion_names_right);

        @left_entries = grep { defined($_) } @left_entries;
        @right_entries = grep { defined($_) } @right_entries;
        
        
        
        unless (grep {/^$left_fusion_name$/} @left_entries) {
            push (@left_entries, $left_fusion_name);
        }
        unless (grep {/^$right_fusion_name$/} @right_entries) {
            push (@right_entries, $right_fusion_name);
        }
        
        
        foreach my $left_entry (@left_entries) {
            foreach my $right_entry (@right_entries) {
                
                my $alt_fusion_name = "$sample_name|$left_entry--$right_entry";
                $orig_fusion_call{$alt_fusion_name}->{$fusion_name}++;
                $fusion_to_prog{$alt_fusion_name}->{$progname}++;
                
                $alt_fusion_name = "$sample_name|$right_entry--$left_entry";
                $orig_fusion_call{$alt_fusion_name}->{$fusion_name}++;
                $fusion_to_prog{$alt_fusion_name}->{$progname}++;
                
            }
        }
        
    }
    
    ## capture those fusions that meet the min prog criteria

    my %fusions_meet_min_prog_count;

    foreach my $fusion_name (keys %fusion_to_prog) {
        
        my $orig_fusion_names_href = $orig_fusion_call{$fusion_name};
        my @orig_fusion_cand_names = sort {$orig_fusion_names_href->{$b}<=>$orig_fusion_names_href->{$a}} keys %$orig_fusion_names_href;

        my $orig_fusion_name = $orig_fusion_cand_names[0];
                
        my $prog_count = scalar(grep { $progs_to_count{$_} } keys %{$fusion_to_prog{$fusion_name}});
        
        #print "$fusion_name\t$orig_fusion_name\t$prog_count\n";

        if ($prog_count >= $min_agree) {
            $fusions_meet_min_prog_count{$orig_fusion_name} = 1;
        }
    }

    

    ## generate report
    my @prognames = sort keys %prognames;

    print "\t" . join("\t", @prognames) . "\n";

    my @final_fusions = sort keys %fusions_meet_min_prog_count; 
    
    foreach my $fusion (@final_fusions) {
        
        my @vals = ($fusion);
        foreach my $progname (@prognames) {
            my $found = (exists $fusion_to_prog{$fusion}->{$progname}) ? 1 : 0;
            push (@vals, $found);
        }

        print join("\t", @vals) . "\n";
    }

    exit(0);
    
}
