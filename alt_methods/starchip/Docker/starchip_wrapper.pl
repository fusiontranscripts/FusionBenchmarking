#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);
use File::Basename;
use FindBin;
use lib ("$FindBin::Bin");
use Pipeliner;


my $help_flag;

my $output_token = "starchip";
my $chim_seg_min = 15;

my $usage = <<__EOUSAGE;

######################################################################################################
#
# Required:

# --left_fq <string>   reads_1.fq.gz
#
# --right_fq <string>  reads_2.fq.gz
#
# --starchip_parameters_file <string>   the starchip parameters file (indicates where the star index is)
#
# --output_dir <string>  output directory
#
# Optional:
#
#  --output_token <string>  token for output files (default: $output_token)
#
#  --chim_seg_min <int>    value for STAR --chimSegmentMin and --chimJunctionOverhangMin  (default: $chim_seg_min)
#
#######################################################################################################

__EOUSAGE

    ;


my $left_fq;
my $right_fq;
my $starchip_parameters_file;
my $output_dir;


&GetOptions ( 'h' => \$help_flag,
              'left_fq=s' => \$left_fq,
              'right_fq=s' => \$right_fq,
              'starchip_parameters_file=s' => \$starchip_parameters_file,
              'chim_seg_min=i' => \$chim_seg_min,
              'output_dir=s' => \$output_dir);


if ($help_flag) {
    die $usage;
}

unless ($left_fq && $right_fq && $starchip_parameters_file && $output_dir) {
    die $usage;
}

$left_fq = Pipeliner::ensure_full_path($left_fq);
$right_fq = Pipeliner::ensure_full_path($right_fq);
$starchip_parameters_file = Pipeliner::ensure_full_path($starchip_parameters_file);
$output_dir = Pipeliner::ensure_full_path($output_dir);



main: {
    
    my $starchip_reference_dirname = dirname($starchip_parameters_file);
     
    my $star_index_dir = "$starchip_reference_dirname/ref_genome.fa.star.idx";
    
    if (! -d $output_dir) {
        &Pipeliner::process_cmd("mkdir -p $output_dir");
    }
    chdir($output_dir) or die "Error, cannot cd to $output_dir";

    &Pipeliner::process_cmd("ln -sf $starchip_reference_dirname");
    
    ## Run STAR:
    my $cmd = "STAR --genomeDir $star_index_dir "
            . " --readFilesIn $left_fq $right_fq "
            . " --outReadsUnmapped Fastx "
            . " --quantMode GeneCounts "
            . " --chimSegmentMin $chim_seg_min "
            . " --chimJunctionOverhangMin $chim_seg_min "
            . " --outSAMstrandField intronMotif "
            . " --readFilesCommand zcat "
            . " --outSAMtype BAM Unsorted ";

    my $chkpt_dir = "__starchip_chkpts";
    my $pipeliner = new Pipeliner( '-checkpoint_dir' => $chkpt_dir );
    
    $pipeliner->add_commands( new Command($cmd, "star_align.ok") );

    ## run STARChip
    
    $cmd = "/usr/local/src/starchip-1.3e/starchip-fusions.pl $output_token Chimeric.out.junction $starchip_reference_dirname/hg19.parameters.txt";
    
    $pipeliner->add_commands( new Command($cmd, "starchip.ok") );

    $pipeliner->run();

    exit(0);

}


    
