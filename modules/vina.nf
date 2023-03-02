/*
*  vina module
*/

params.OUTPUT = "$launchDir/vina"

process vina_prepare_receptor {
    publishDir "$params.OUTPUT/prepared_receptors", mode: 'copy'
    container "/scicore/home/schwede/zohixe92/CAMEO/CAMEO_predictors/BaselineCM_AutoDockVina/container_scripts/ADFRsuite.img"
    tag { receptor }

    input:
    tuple val(receptor), path (pdb_H_files)
    
    output:
    tuple val(receptor), path ("*.pdbqt"), emit: preped_receptor
    
    script:
    """
    prepare_receptor -r ${pdb_H_files} -o ${receptor}.pdbqt
    """
}


process vina_prepare_ligand {
    publishDir "$params.OUTPUT/prepared_ligands", mode: 'copy', pattern: "*.pdbqt"
    conda "/scicore/home/schwede/leeman0000/miniconda3/envs/meeko"
    tag { ligand }

    input:
    tuple val (ligand), path (sdf_file)

    output:
    tuple val (ligand), path ("*.pdbqt"), emit: preped_ligand

    script:
    """
    mk_prepare_ligand.py -i ${sdf_file} -o ${ligand}.pdbqt
    """
}


process vina {
    publishDir "$params.OUTPUT/vina_predictions/${complex}/${pocket_nr}", mode: 'copy'
    conda "/scicore/home/schwede/leeman0000/miniconda3/envs/vina"
    tag { complex }
    
    input:
    tuple val (complex), val (ligand), val (receptor), val (pocket_nr), path (receptor_pdbqt), path (ligand_pdbqt), path (vina_box)
    
    output:
    tuple val (complex), val (receptor), val (pocket_nr), path ("${complex}_${pocket_nr}_vina.pdbqt"), emit: vina_result
    path ("${complex}_${pocket_nr}_vina.log"), emit: vina_log
    
    script:
    """
    ${params.vina_tool} --receptor ${receptor_pdbqt} --ligand ${ligand_pdbqt} \
                 --config ${vina_box} --out ${complex}_${pocket_nr}_vina.pdbqt \
                 --exhaustiveness=32 --seed 160490 --cpu ${task.cpus} \
                 > ${complex}_${pocket_nr}_vina.log
    """
}


process pdbtqToSdf {
    publishDir "$launchDir/${tool_name}/${tool_name}_predictions/${complex}/${pocket_nr}", mode: 'copy'
    conda "/scicore/home/schwede/leeman0000/miniconda3/envs/meeko"
    tag { complex }
    
    input:
    tuple val (complex), val (receptor), val (pocket_nr), path (pdbqt)
    val (tool_name)
    
    output:
    tuple val (complex), val (receptor), val (pocket_nr), path ("${complex}_${pocket_nr}_${tool_name}*.sdf")
    
    script:
    """
    csplit --elide-empty-files --prefix="${complex}_${pocket_nr}_${tool_name}_" --suffix-format="%d.pdbqt"  <(echo "ENDMDL"; cat ${pdbqt}) '/ENDMDL/+1' "{*}"
    for line in ${complex}_${pocket_nr}_${tool_name}_*; do if test \$(wc -l < \$line) -eq 1; then rm \$line; fi; done
     
    for file in ${complex}_${pocket_nr}_${tool_name}_*.pdbqt; do mk_export.py \${file} -o \${file%.pdbqt}.sdf; done
    """
}
