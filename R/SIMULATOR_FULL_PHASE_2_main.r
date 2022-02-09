#==============================================PHASE 2: SAMPLE PHYLOGENY
SIMULATOR_FULL_PHASE_2_main <- function(package_clonal_evolution) {
#---------------------------------------------Input the clonal evolution
    T_current                       <- package_clonal_evolution[[1]]
    N_clones                        <- package_clonal_evolution[[4]]
    genotype_list_ploidy_chrom      <- package_clonal_evolution[[5]]
    genotype_list_ploidy_block      <- package_clonal_evolution[[6]]
    genotype_list_ploidy_allele     <- package_clonal_evolution[[7]]
    evolution_traj_time             <- package_clonal_evolution[[13]]
    evolution_traj_divisions        <- package_clonal_evolution[[14]]
    evolution_traj_clonal_ID        <- package_clonal_evolution[[15]]
    evolution_traj_population       <- package_clonal_evolution[[16]]
#----------------------------------------Initialize the phylogeny record
    phylogeny_origin                <- rep(0,length=2*N_sample-1)
    phylogeny_elapsed_gens          <- rep(0,length=2*N_sample-1)
    phylogeny_elapsed_genotypes     <- vector("list",length=2*N_sample-1)
    phylogeny_genotype              <- rep(0,length=2*N_sample-1)
    phylogeny_birthtime             <- rep(0,length=2*N_sample-1)
    phylogeny_deathtime             <- rep(0,length=2*N_sample-1)
#-------------------------------Find a random sample of final population
#   Initialize the current list of nodes in the sample phylogeny
    node_list_current               <- N_sample:(2*N_sample-1)
#   Initialize the current list of genoytpes of the nodes
    final_clonal_ID                 <- tail(evolution_traj_clonal_ID,1) # last entry of evolution_traj_clonal_ID
    final_clonal_population         <- tail(evolution_traj_population,1)
    final_population                <- c()
    for (i in 1:length(final_clonal_ID)) {
        clone                       <- final_clonal_ID[i]
        clonal_population           <- final_clonal_population[i]
        final_population            <- c(final_population,clone) # append clone to final_population
    }
#    node_genotype_current           = datasample(final_population,N_sample,'Replace',false);
    node_genotype_current           <- sample(x=final_population,size=N_sample,replace=TRUE);
#   Initialize data for leaves of sample phylogeny
    phylogeny_elapsed_gens[node_list_current]   <- 1
    for (node in N_sample:2*N_sample-1) {
        phylogeny_elapsed_genotypes[[node]]     <- node_genotype_current[node-N_sample+1]
    }
    phylogeny_genotype[node_list_current]       <- node_genotype_current
    phylogeny_deathtime[node_list_current]      <- T_current



#---------------------------------Create CN object for the sampled cells
    sample_genotype                 <- phylogeny_genotype[N_sample:2*N_sample-1]



print(N_sample)
# print(genotype_list_ploidy_block[[1]])
# print(genotype_list_ploidy_allele[[1]])


}
