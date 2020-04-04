#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");


my $usage = "usage: $0 fusion_result_file_listing.dat\n\n";

my $fusion_result_file_listing = $ARGV[0] or die $usage;

my $fusion_prog_parser_lib_dir = "$FindBin::Bin/FusionProgParsers";

my %prog_type_to_file_parser = ( 
    'ChimPipe' => 'ChimPipe_parser',
    'ChimeraScan' => 'ChimeraScan_parser',
    'deFuse' => 'DEFUSE_parser',
    'EricScript' => 'EricScript_parser',

    'Fusion.*Catcher' => 'FusionCatcher_parser',
    'FC_V0997c' => 'FusionCatcher_parser',
    
    'FusionHunter' => 'FusionHunter_parser',

    'FusionInspector' => 'FusionInspector_parser',
        
    'InFusion' => 'InFusion_parser', 

    'JAFFA-Assembly' => 'JAFFA_parser',
    'JAFFA-Direct' => 'JAFFA_parser',
    'JAFFA-Hybrid' => 'JAFFA_parser',

    'MapSplice' => 'MapSplice_parser',

    'nFuse' => 'NFuse_parser',

    'PRADA' => 'PRADA_parser',

    'SOAP-fuse' => 'SOAPfuse_parser',

    'STAR_FUSION' => 'STARFusion_parser',
    
    'TopHat-Fusion' => 'TopHatFusion_parser',

    'PIZZLY' => 'PIZZLY_parser',

    'ARRIBA' => 'ARRIBA_parser',
    'ARRIBA_hc' => 'ARRIBA_hc_parser',
    
    'STARCHIP' => 'STARCHIP_parser',
    'STARChip_csm10' => 'STARCHIP_parser',
    'STARCHIP_csm10' => 'STARCHIP_parser',
    'STARCHIP_csm10_pG_Apr302019' => 'STARCHIP_parser',
    'STARCHIP_csm10_pGm2_May012019' => 'STARCHIP_parser',
    
    #'TrinityFusion' => 'TrinityFusion_parser',
    #'TrinityFusion-D' => 'TrinityFusion_parser',
    #'TrinityFusion-C' => 'TrinityFusion_parser',
    #'TrinityFusion-UC' => 'TrinityFusion_parser',
    'TRINITY.*FUSION' => 'TrinityFusion_parser',
    
    'STARSEQR' => 'STARSEQR_parser'
    
    );



foreach my $module (values %prog_type_to_file_parser) {
    my $module_path = "$fusion_prog_parser_lib_dir/$module.pm";

    require($module_path);

}


main: {


    # print header
    print join("\t", "sample", "prog", "fusion", "J", "S") . "\n";
    
    open(my $fh, $fusion_result_file_listing) or die "Error, cannot open file $fusion_result_file_listing";
    while (<$fh>) {
        chomp;
        my ($sample_name, $prog_name, $result_file) = split(/\t/);



        my $parser_module;

        if (exists $prog_type_to_file_parser{$prog_name}) {
            $parser_module = $prog_type_to_file_parser{$prog_name};
        }
        else {
            ## use regex to find parser
            foreach my $name (keys %prog_type_to_file_parser) {
                if ($prog_name =~ /$name/i) {
                    $parser_module = $prog_type_to_file_parser{$name};
                    last;
                }
            }
        }

        unless (defined $parser_module) {

            die "Error, no parser for prog [$prog_name] ";
        }
        
        my $parser_function = $parser_module . "::" . "parse_fusion_result_file";
        
        no strict 'refs';
        my @fusions = &$parser_function($result_file);

        &add_sum_fusions(\@fusions);
        
        @fusions = reverse sort { $a->{sum_frags} <=> $b->{sum_frags} } @fusions;
        
        foreach my $fusion (@fusions) {

            my $fusion_name = join("--", $fusion->{geneA}, $fusion->{geneB});

            my $junc_count = $fusion->{junc_reads};
            my $span_count = $fusion->{span_reads};


            print join("\t", $sample_name, $prog_name, $fusion_name, $junc_count, $span_count) . "\n";
        }
                    
    }
    close $fh;


    exit(0);
}

####
sub add_sum_fusions {
    my ($fusions_aref) = @_;

    foreach my $fusion (@$fusions_aref) {

        $fusion->{sum_frags} = $fusion->{junc_reads} + $fusion->{span_reads};

    }

}
