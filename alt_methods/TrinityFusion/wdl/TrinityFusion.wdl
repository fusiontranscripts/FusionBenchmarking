
task TRINITY_FUSION_UC_TASK {

	String sample_name
	File left_fq
    File right_fq
	File genome_lib_tar
	File chimeric_junctions_file
	File aligned_bam

	command <<<

    set -e

    # untar the genome lib
    tar xvf ${genome_lib_tar}
	rm ${genome_lib_tar}
	
	# TrinityFusion

    /usr/local/src/TrinityFusion/TrinityFusion \
         --left_fq ${left_fq} \
         --right_fq ${right_fq} \
         --chimeric_junctions ${chimeric_junctions_file} \
         --aligned_bam ${aligned_bam} \
         --CPU 10 \
         --genome_lib_dir ctat_genome_lib_build_dir \
         --output_dir ${sample_name}
     
     
    cp ${sample_name}/TrinityFusion-UC.fusion_predictions.tsv ${sample_name}.TrinityFusion-UC.fusion_predictions.tsv

    gzip ${sample_name}.TrinityFusion-UC.fusion_predictions.tsv
    
    >>>
    
    output {
      File TrinityFusion_UC="${sample_name}.TrinityFusion-UC.fusion_predictions.tsv.gz"
    }
    

    runtime {
            docker: "trinityctat/trinityfusion:0.2.0"
            disks: "local-disk 500 SSD"
            memory: "30G"
            cpu: "10"
            preemptible: 0
            maxRetries: 0
    }
}


task TRINITY_FUSION_D_TASK {

	String sample_name
	File left_fq
    File right_fq
	File genome_lib_tar


	command <<<

    set -e

    # untar the genome lib
    tar xvf ${genome_lib_tar}
	rm ${genome_lib_tar}
	
	# TrinityFusion

    /usr/local/src/TrinityFusion/TrinityFusion \
         --left_fq ${left_fq} \
         --right_fq ${right_fq} \
         --CPU 10 \
         --genome_lib_dir ctat_genome_lib_build_dir \
         --output_dir ${sample_name}
     
     
    cp ${sample_name}/TrinityFusion-D.fusion_predictions.tsv ${sample_name}.TrinityFusion-D.fusion_predictions.tsv

    gzip ${sample_name}.TrinityFusion-D.fusion_predictions.tsv
    
    >>>
    
    output {
      File TrinityFusion_D="${sample_name}.TrinityFusion-D.fusion_predictions.tsv.gz"
    }
    

    runtime {
            docker: "trinityctat/trinityfusion:0.2.0"
            disks: "local-disk 500 SSD"
            memory: "30G"
            cpu: "10"
            preemptible: 0
            maxRetries: 0
    }
}



workflow trinity_fusion_wf {
	Boolean? TrinityFusion_C
    Boolean? TrinityFusion_UC
    Boolean? TrinityFusion_D
    
	String sample_name
	File left_fq
    File right_fq
	File genome_lib_tar

	File? chimeric_junctions_file
	File? star_aligned_bam


	if (defined(TrinityFusion_UC)) {
    	call TRINITY_FUSION_UC_TASK {
          input:
        	sample_name=sample_name,
            left_fq=left_fq,
            right_fq=right_fq,
            genome_lib_tar=genome_lib_tar,
            chimeric_junctions_file=chimeric_junctions_file,
			aligned_bam=star_aligned_bam
        }
	}

	if (defined(TrinityFusion_D)) {
    	call TRINITY_FUSION_D_TASK {
          input:
        	sample_name=sample_name,
            left_fq=left_fq,
            right_fq=right_fq,
            genome_lib_tar=genome_lib_tar
        }
	}

}

