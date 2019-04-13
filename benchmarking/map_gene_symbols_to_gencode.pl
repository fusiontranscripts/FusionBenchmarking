#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use FindBin;
use Data::Dumper;
use Set::IntervalTree;


my $usage = "\n\n\tusage: $0 preds.collected genes.coords.gz genes.aliases\n\n";

my $preds_collected_file = $ARGV[0] or die $usage;
my $genes_coords_file = $ARGV[1] or die $usage;
my $genes_aliases_file = $ARGV[2] or die $usage;

###############################################################################
### a few handy globals ;-)

my %GENE_ID_TO_GENE_STRUCTS;  # Gene_id returns list of all structs w/ that id

my $FEATURE_COUNTER;
my %FEATURE_ID_TO_GENE_STRUCT; # FEATURE_ID is uniqely assigned internally

our %CHR_TO_ITREE;

my $EXCLUDE_LIST = "^(Y_RNA|snoU13)\$"; ## make regex, include | separated entries

my $MAX_GENE_ALIASES = 5;
my $MAX_GENE_RANGE_SEARCH = 2e6;

my %PRIMARY_TARGET_ACCS;

my %GENE_ALIASES;

my %TRUTH_FUSION_PARTNERS;

##############################################################################



main: {

    &init_interval_trees($genes_coords_file, \%PRIMARY_TARGET_ACCS);
    
    &init_aliases($genes_aliases_file, \%GENE_ALIASES);

    
    open (my $fh, $preds_collected_file) or die "Error, cannot read file $preds_collected_file";
    my $header = <$fh>;
    chomp $header;
    # header
    print join("\t", $header, "mapped_gencode_A_gene_list", "mapped_gencode_B_gene_list") . "\n";
    
    while (my $line = <$fh>) {
        #print STDERR $line;
        
        chomp $line;
        
        my @x = split(/\t/, $line);
        my $fusion = $x[2];
        my ($geneA, $geneB) = split(/--/, $fusion);
        
        my $fusion_name = "$geneA--$geneB";

        #print STDERR "\t** fusion: [$fusion]  \n";
        my $gencode_A_genes = &get_gencode_overlapping_genes($geneA);
        my $gencode_B_genes = &get_gencode_overlapping_genes($geneB);
        

        if ($fusion =~ /ENSG/) {

            if ($geneA =~ /ENSG/) {
                if (my $alias = $GENE_ALIASES{$geneA}) {
                    $geneA = $alias;
                }
            }
            if ($geneB =~ /ENSG/) {
                if (my $alias = $GENE_ALIASES{$geneB}) {
                    $geneB = $alias;
                }
            }

            # replace fusion name w/ the ENSG-vals replaced w/ gene symbols
            $x[2] = "$geneA--$geneB";
        }
                
        print join("\t", @x, $gencode_A_genes, $gencode_B_genes) . "\n";
        
    }
    close $fh;    
    
    
    exit(0);
}


####
sub process_cmd {
    my ($cmd) = @_;
    
    print STDERR "CMD: $cmd\n";

    my $ret = system($cmd);
    if ($ret) {
        die "Error, cmd $cmd died with ret $ret";
    }

    return;
}


####
sub get_gencode_overlapping_genes {
    my ($gene_id) = @_;

    my @gencode_overlapping_genes = &find_overlapping_gencode_genes($gene_id);
    
    my $gencode_genes_text = (@gencode_overlapping_genes) ? join(",", sort @gencode_overlapping_genes) : ".";
    
    return($gencode_genes_text);
    
}

####
sub find_overlapping_gencode_genes {
    my ($gene_id_listing) = @_;

    $gene_id_listing =~ s/,\s*$//; # remove trailing comma as seen in some entries

    my %gencode_genes;

    foreach my $gene_id (split(/,/, $gene_id_listing) ) {

        unless ($gene_id =~ /\w/) { next; }
        
        # retain original gene_id if recognized as primary
        if ($PRIMARY_TARGET_ACCS{$gene_id}) {
            $gencode_genes{$gene_id} = 1;
        }
        
        # retain if we identify and recognize an alias for the id 
        my $alias = $GENE_ALIASES{$gene_id};
        if ($alias && $PRIMARY_TARGET_ACCS{$alias}) {
            $gencode_genes{$alias} = 1;
        }
                
        my @mapped_genes = &__map_genes($gene_id);
        
        foreach my $mapped_gene_id (@mapped_genes) {
            $gencode_genes{$mapped_gene_id} = 1;
        }
    }


    my @candidate_gencode_genes = keys %gencode_genes;

    return(@candidate_gencode_genes);
    
}


my %reported_missing_gene;

sub __map_genes {
    my ($gene_id) = @_;

    my $gene_structs_aref = $GENE_ID_TO_GENE_STRUCTS{$gene_id} || $GENE_ID_TO_GENE_STRUCTS{ lc $gene_id};

    
    #unless ($gene_structs_aref) {
    #    # try again, removing any trailing version number
    #    $gene_id =~ s/\.\d+$//;
    #    $gene_structs_aref = $GENE_ID_TO_GENE_STRUCTS{$gene_id} || $GENE_ID_TO_GENE_STRUCTS{ lc $gene_id};
    #}
    
    unless (ref $gene_structs_aref) {
        unless ($reported_missing_gene{$gene_id}) {
            print STDERR "-warning, no gene stored for identifier: [$gene_id]\n";
            $reported_missing_gene{$gene_id} = 1;
        }
        return ();
    }
    

    my %overlapping_genes;
    
    foreach my $gene_struct (@$gene_structs_aref) {

        my $chr = $gene_struct->{chr};
        my $lend = $gene_struct->{lend};
        my $rend = $gene_struct->{rend};

        my $search_dist = $rend - $lend + 1;
        if ($search_dist > $MAX_GENE_RANGE_SEARCH) {
            next;
        }

        my $itree = $CHR_TO_ITREE{$chr} or die "Error, no itree for chr [$chr], " . Dumper($gene_struct);

        my $overlaps_aref = $itree->fetch($lend, $rend);

        foreach my $feature_id_aref (@$overlaps_aref) {
            my $feature_id = $feature_id_aref->[0];
            my $struct = $FEATURE_ID_TO_GENE_STRUCT{$feature_id};
            unless($struct) {
                die "Error, no struct returned for feature_id: $feature_id";
            }

            my $overlap_gene_id = $struct->{gene_id};
            $overlapping_genes{$overlap_gene_id} = 1;
        }

    }

    return(keys %overlapping_genes);
}


####
sub add_gene_struct {
    my ($struct, $is_target) = @_;

    my $gene_id = $struct->{gene_id};
    my $chr = $struct->{chr};
    my $lend = $struct->{lend};
    my $rend = $struct->{rend};

    ($lend, $rend) = sort {$a<=>$b} ($lend, $rend); # just to be safe

    if ($EXCLUDE_LIST) {
        if ($gene_id =~ /$EXCLUDE_LIST/) { return; }
    }


    $FEATURE_COUNTER++;

    $struct->{FEATURE_COUNTER} = $FEATURE_COUNTER;

    unless ($chr =~ /chr/) {
        $chr = "chr$chr";
    }

    my $itree = $CHR_TO_ITREE{$chr};
    unless ($itree) {
        $itree = $CHR_TO_ITREE{$chr} = Set::IntervalTree->new;
    }

    #$itree->insert($FEATURE_COUNTER, $lend, $rend);

    if ($is_target) {
        $itree->insert([$FEATURE_COUNTER], $lend, $rend);
    }

    $FEATURE_ID_TO_GENE_STRUCT{$FEATURE_COUNTER} = $struct;

    push (@{$GENE_ID_TO_GENE_STRUCTS{$gene_id}}, $struct);


    return;
}

####
sub init_interval_trees {
    my ($gene_coords_file, $primary_target_accs_href) = @_;
    
    print STDERR "-parsing annotation gene spans\n";

    unless ($gene_coords_file =~ /\.gz$/) {
        die "Error, gene_coords file $gene_coords_file is supposed to be gzipped";
    }
    
    open(my $fh, "gunzip -c $gene_coords_file | ") or die "Error, cannot open file: $gene_coords_file";
    my $header_line = <$fh>;
    unless ($header_line =~ /^gene_id/) {
        croak "Error, didn't parse header from $gene_coords_file";
    }
    while (<$fh>) {
        chomp;
        my ($gene_id, $chr, $lend, $rend, $file, $primary_target) = split(/\t/);

        if ($primary_target) {
            $primary_target_accs_href->{$primary_target} = 1;
        }

        
        ($lend, $rend) = sort {$a<=>$b} ($lend, $rend); # just to be sure.

        my $struct = { chr => $chr,
                       lend => $lend,
                       rend => $rend,
                       gene_id => $gene_id,
                       file => $file,
        };

        &add_gene_struct($struct, $primary_target);

        # in case gene ids are presented in different case from the annotations
        if ( (! $primary_target) && lc($gene_id) ne $gene_id) {
            
            my $struct = { chr => $chr,
                           lend => $lend,
                           rend => $rend,
                           gene_id => lc($gene_id),
                           file => $file,
            };
            
        
            &add_gene_struct($struct, $primary_target);
            
        }
    }
    
    return;
}


####
sub overlaps {
    my ($struct_A, $struct_B) = @_;

    if ($struct_A->{lend} < $struct_B->{rend}
        &&
        $struct_A->{rend} > $struct_B->{lend}) {
        return(1);
    }
    else {
        return(0);
    }

}

####
sub init_aliases {
    my ($gene_aliases_file, $gene_aliases_href) = @_;

    open(my $fh, $gene_aliases_file) or die "Error, cannot open file $gene_aliases_file";
    while (<$fh>) {
        chomp;
        my ($gene_symbol, $gene_id) = split(/\t/);
        $gene_aliases_href->{$gene_id} = $gene_symbol;
    }
    close $fh;

    return;
}
