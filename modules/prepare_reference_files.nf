/*
*  prepare_reference_files module 
*/

params.OUTPUT = "$launchDir/data"

process prepare_reference_files {
    publishDir(params.OUTPUT, mode: 'copy')
    conda '/scicore/home/schwede/leeman0000/miniconda3/envs/spyrmsd'

    input:
    path (dataset)

    output:
    path ("${params.pdb_sdf_dir}/*.pdb"), emit: pdb_files
    path ("${params.pdb_sdf_dir}/*.sdf"), emit: sdf_files
    path ("${params.pdb_sdf_dir}/protein_ligand.csv"), emit: protein_ligand_csv

    script:
    """
    mkdir -p ${params.pdb_sdf_dir}
    
    prepare_reference_files.py ${dataset} ${params.pdb_sdf_dir}
    """
}