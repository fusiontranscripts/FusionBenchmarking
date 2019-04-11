#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);
use FindBin;
use lib ("$FindBin::Bin/../../PerlLib");
use Process_cmd;


my $usage = <<__EOUSAGE__;

#########################################################################
#
# Required:
#
# --left_reads <string>               left reads file (reads1.fastq.gz)
# --right_reads <string>              right reads file (reads2.fastq.gz)
# --arriba_singularity_img <string>   arriba singularity img
# --arriba_references_dir <string>    arriba references directory
# --output_dir <string>               output directory
#
# Optional:
#
# --mount <string>                    dirctory to mount
#
########################################################################

__EOUSAGE__


    ;


    
my $help_flag;
my $left_reads;
my $right_reads;
my $arriba_singularity_img;
my $arriba_references_dir;
my $output_dir;
my $mount = "";

&GetOptions ( 'h' => \$help_flag,

              ## all required
              'left_reads=s' => \$left_reads,
              'right_reads=s' => \$right_reads,
              'arriba_singularity_img=s' => \$arriba_singularity_img,
              'arriba_references_dir=s' => \$arriba_references_dir,
              'output_dir=s' => \$output_dir,

              # optional
              'mount=s' => \$mount,
    );


if ($help_flag) {
    die $usage;
}

unless($left_reads && $right_reads && $arriba_singularity_img && $arriba_references_dir && $output_dir) {
    die $usage;
}

if ($mount) {
    $mount = &ensure_full_path($mount);
    $mount = " -B $mount ";
}

$left_reads = &ensure_full_path($left_reads);
$right_reads = &ensure_full_path($right_reads);
$arriba_singularity_img = &ensure_full_path($arriba_singularity_img);
$arriba_references_dir = &ensure_full_path($arriba_references_dir);
$output_dir = &ensure_full_path($output_dir);


main: {

    unless (-d $output_dir) {
        &process_cmd("mkdir -p $output_dir");
    }
    
    my $cmd = "singularity exec -e $mount"
            . " -B $output_dir:/output "
            . " -B $arriba_references_dir:/references:ro "
            . " -B $left_reads:/read1.fastq.gz:ro "
            . " -B $right_reads:/read2.fastq.gz:ro "
            . " $arriba_singularity_img arriba.sh ";
    
    &process_cmd($cmd);
    
}

