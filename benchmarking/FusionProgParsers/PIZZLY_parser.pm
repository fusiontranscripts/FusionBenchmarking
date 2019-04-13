package PIZZLY_parser;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use JSON::XS;

=pizzly_format

{
  "genes" : [
    {
      "geneA" : { "id" : "ENSG00000139899.6", "name" : "CBLN3"},
      "geneB" : { "id" : "ENSG00000073067.9", "name" : "CYP2W1"},
      "paircount" : 1,
      "splitcount" : 1,
      "transcripts" : [
        {
          "fasta_record": "ENST00000267406.6_0:771_ENST00000308919.7_500:2304",
          "transcriptA": {"id" : "ENST00000267406.6", "startPos" : 0, "endPos" : 771, "edit" : 0, "strand" : true},
          "transcriptB": {"id" : "ENST00000308919.7", "startPos" : 500, "endPos" : 2304, "edit" : 0, "strand" : true},
          "support" : 2,
          "reads" : [0, 1]
        },
        {
          "fasta_record": "ENST00000267406.6_0:771_ENST00000340150.6_341:2361",
          "transcriptA": {"id" : "ENST00000267406.6", "startPos" : 0, "endPos" : 771, "edit" : 0, "strand" : true},
          "transcriptB": {"id" : "ENST00000340150.6", "startPos" : 341, "endPos" : 2361, "edit" : 0, "strand" : true},
          "support" : 2,
          "reads" : [0, 1]
        }
      ],
      "readpairs" : [
        {
          "type" : "PAIR",
          "read1" : { "name" : "CBLN3--CYP2W1:24806000_0_28245_689_205/1", "seq" : "ATTTGCTGCGGTCCGAAGCCACCACCATGAGCCAGCAGGGGAAACCGGCA", "splitpos" : -1, "direction" : "true", "kmerpos" : { "start" : 0, "stop" : 19}},
          "read2" : { "name" : "CBLN3--CYP2W1:24806000_0_28245_689_205/2", "seq" : "CATCGATGAGACCCAGCAGGGACACAAACACGGGGTCCCGGTAGTCAAAT", "splitpos" : -1, "direction" : "false", "kmerpos" : { "start" : 0, "stop" : 19}}
        },
        {
          "type" : "SPLIT",
          "read1" : { "name" : "CBLN3--CYP2W1:29770225_0_28245_727_215/1", "seq" : "GGGAAACCGGCAATGGCACCAGTGGGGCCATCTACTTCGACCAGGCCGGC", "splitpos" : 42, "direction" : "true", "kmerpos" : { "start" : 0, "stop" : 14}},
          "read2" : { "name" : "CBLN3--CYP2W1:29770225_0_28245_727_215/2", "seq" : "AGACGTTGAACAGCTGCAGGCCAGGGGACCCCAAGAGGACCATGACCTCA", "splitpos" : -1, "direction" : "false", "kmerpos" : { "start" : 0, "stop" : 19}}
        }
      ]
    },
   
    ...

}

=cut


      
      
sub parse_fusion_result_file {
    my ($pizzly_json_file) = @_;

    #print STDERR "-parsing $pizzly_json_file\n";
    
    #my $JSON_DECODER = JSON::XS->new();
    #my $pizzly_json = `cat $pizzly_json_file`;

    #print STDERR $pizzly_json;

    #print STDERR "-decoding pizzly\n";

    #my $json_hash = $JSON_DECODER->decode($pizzly_json);

    #print STDERR "-done decoding\n";
    
    my @fusions;

    #use Data::Dumper;
    #print STDERR Dumper($json_hash);


    my $fh;
    if ($pizzly_json_file =~ /.gz$/) {
        open($fh, "gunzip -c $pizzly_json_file | ") or die "Error, cannot open file $pizzly_json_file";
    }
    else {
        open($fh, $pizzly_json_file) or die "Error, cannot open file: $pizzly_json_file";
    }
    
    while(<$fh>) {
        s/^\s+//;
        
        #  "geneA" : { "id" : "ENSG00000139899.6", "name" : "CBLN3"},
        #  "geneB" : { "id" : "ENSG00000073067.9", "name" : "CYP2W1"},
        #  "paircount" : 1,
        #  "splitcount" : 1,
           
        if (/^"geneA"/) {
            my $line = $_;

            for (1..3) {
                my $next_line = <$fh>;
                $line .= $next_line;
            }

            if ($line =~ /\"geneA\" .*\"name\" : \"([^\"]+)\".*\"geneB\" .*\"name\" : \"([^\"]+)\".*\"paircount\" : (\d+),.*\"splitcount\" : (\d+)/ms) {
                my $geneA = $1;
                my $geneB = $2;
                my $paircount = $3;
                my $splitcount = $4;

                push (@fusions, { geneA => $geneA,
                                  geneB => $geneB,
                                  span_reads => $paircount,
                                  junc_reads => $splitcount,
                      } );
            }
        }
    }
    close $fh;

    #print STDERR Dumper(\@fusions);
    
    return(@fusions);
    
    
}

1; #EOM


__END__


    open (my $fh, $defuse_out_file) or die "Error, cannot open file $defuse_out_file";
    my $header = <$fh>;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);

        my $geneA = $x[30];
        my $geneB = $x[31];

        my $junction_count = $x[2]; # splitr_count
        unless ($junction_count =~ /\w/) {
            $junction_count = 0;
        }

        my $spanning_count = $x[56]; # span_count
        unless ($spanning_count =~ /\w/) {
            $spanning_count = 0;
        }

        my $chrA = $x[24];
        my $brkpt_A = $x[37];
        my $chrB = $x[25];
        my $brkpt_B = $x[38];

        my $struct = {

            geneA => $geneA,
            chrA => $chrA,
            coordA => $brkpt_A,

            geneB => $geneB,
            chrB => $chrB,
            coordB => $brkpt_B,

            span_reads => $spanning_count,
            junc_reads => $junction_count,
        };

        push (@fusions, $struct);
    }

    return(@fusions);
}

1; #EOM

