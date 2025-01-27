/*
*  gnina module
*/

params.OUTPUT = "$launchDir/predictions/gnina"

process gnina {
    publishDir "$params.OUTPUT/${complex}/${pocket_nr}", mode: 'copy'
    container "${params.gnina_sing}"
    tag { "${complex}_${pocket_nr}" }
    
    input:
    tuple val (complex), val (ligand), val (receptor), val (pocket_nr), path (receptor_pdbqt), path (ligand_pdbqt), path (vina_box)
    
    output:
    tuple val (complex), val (receptor), val (pocket_nr), path ("${complex}_${pocket_nr}_gnina.pdbqt"), emit: gnina_result
    path ("${complex}_${pocket_nr}_gnina.log"), emit: gnina_log
    
    script:
    """
    gnina -r ${receptor_pdbqt} -l ${ligand_pdbqt} --config ${vina_box} \
          -o ${complex}_${pocket_nr}_gnina.pdbqt \
          --log ${complex}_${pocket_nr}_gnina.log \
          ${params.gnina_params}
    """
}


process gnina_sdf {
    publishDir "$params.OUTPUT/${complex}/${pocket_nr}", mode: 'copy'
    container "${params.gnina_sing}"
    tag { "${complex}_${pocket_nr}" }

    input:
    tuple val (complex), val (ligand), val (receptor), val (pocket_nr), path (receptor_pdb), path (ligand_sdf), path (vina_box)

    output:
    tuple val (complex), val (receptor), val (pocket_nr), path ("${complex}_${pocket_nr}_gnina_*.sdf"), emit: gnina_sdf
    path ("${complex}_${pocket_nr}_gnina.log"), emit: gnina_log

    script:
    """
    gnina -r ${receptor_pdb} -l ${ligand_sdf} --config ${vina_box} \
          -o ${complex}_${pocket_nr}_gnina.sdf \
          --log ${complex}_${pocket_nr}_gnina.log \
          ${params.gnina_params}

    split_pat='\$\$\$\$'
    csplit --elide-empty-files --prefix="${complex}_${pocket_nr}_gnina_" --suffix-format="%d.sdf"  <(echo \$split_pat; cat "${complex}_${pocket_nr}_gnina.sdf") '/\$\$\$\$/+1' "{*}"
    for line in ${complex}_${pocket_nr}_gnina_*; do if test \$(wc -l < \$line) -eq 1; then rm \$line; fi; done
    """
}
