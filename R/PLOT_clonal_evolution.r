#=====================================PLOT CLONAL EVOLUTION AS FISH PLOT
PLOT_clonal_evolution <- function(package_simulation,vec_time_plot,unit){
#---------------------------------------------Input the clonal evolution
    package_clonal_evolution                        <- package_simulation[[1]]
    evolution_origin                                <- package_clonal_evolution[[11]]
    evolution_traj_time                             <- package_clonal_evolution[[13]]
    evolution_traj_clonal_ID                        <- package_clonal_evolution[[15]]
    evolution_traj_population                       <- package_clonal_evolution[[16]]
#---------------------------------------------Input the clonal phylogeny
    package_sample_phylogeny                        <- package_simulation[[3]]
    package_clone_phylogeny                         <- package_sample_phylogeny[[4]]
    clone_phylogeny_labels                          <- package_clone_phylogeny[[1]]
    clone_phylogeny_genotype                        <- package_clone_phylogeny[[4]]
    clone_hclust_nodes                              <- package_clone_phylogeny[[7]]
    clone_hclust_merge                              <- package_clone_phylogeny[[8]]

    N_clones                                        <- length(clone_phylogeny_labels)





print('PLOT CLONAL EVOLUTION ........')
#----------------------------Build the genotype list for each clone node
    clone_phylogeny_all_genotypes                                       <- vector('list',length=length(clone_phylogeny_genotype))
#   Initialize genotype lists for clone leaves
    for (clone in length(clone_phylogeny_genotype):(length(clone_phylogeny_genotype)-N_clones+1)){
        all_genotypes                                                   <- clone_phylogeny_genotype[clone]
        while (all_genotypes[1]!=0){
            ancestor_genotype                                           <- evolution_origin[all_genotypes[1]]
            all_genotypes                                               <- c(ancestor_genotype,all_genotypes)
        }
        clone_phylogeny_all_genotypes[[clone]]                          <- all_genotypes
    }
#   Update genotype lists with information from clone hclust
    for (clone_hclust_mother_node in 1:nrow(clone_hclust_merge)){
#       Find mother clone node's index in phylogeny our style
        clone_phylogeny_mother_node                                     <- which(is.element(clone_hclust_nodes,clone_hclust_mother_node))
#       Find daughter clone nodes' indices in phylogeny our style
        vec_clone_hclust_daughter_nodes                                 <- clone_hclust_merge[clone_hclust_mother_node,]
        vec_clone_phylogeny_daughter_nodes                              <- which(is.element(clone_hclust_nodes,vec_clone_hclust_daughter_nodes))
#       Update genotype lists for the 3 clone nodes
        clone_phylogeny_daughter_node_1                                 <- vec_clone_phylogeny_daughter_nodes[[1]]
        clone_phylogeny_daughter_node_2                                 <- vec_clone_phylogeny_daughter_nodes[[2]]
        mother_genotypes                                                <- intersect(clone_phylogeny_all_genotypes[[clone_phylogeny_daughter_node_1]],clone_phylogeny_all_genotypes[[clone_phylogeny_daughter_node_2]])
        clone_phylogeny_all_genotypes[[clone_phylogeny_mother_node]]    <- mother_genotypes
        clone_phylogeny_all_genotypes[[clone_phylogeny_daughter_node_1]]<- setdiff(clone_phylogeny_all_genotypes[[clone_phylogeny_daughter_node_1]],mother_genotypes)
        clone_phylogeny_all_genotypes[[clone_phylogeny_daughter_node_2]]<- setdiff(clone_phylogeny_all_genotypes[[clone_phylogeny_daughter_node_2]],mother_genotypes)
    }
#---------------------------------Find clonal populations as time series
    table_clonal_populations                    <- matrix(0,nrow=length(vec_time_plot),ncol=length(clone_phylogeny_all_genotypes))
    for (row in 1:length(vec_time_plot)){
        time                                    <- vec_time_plot[row]
        loc                                     <- which.min(abs(evolution_traj_time-time))
        vec_clonal_ID                           <- evolution_traj_clonal_ID[[loc]]
        vec_clonal_population                   <- evolution_traj_population[[loc]]

print(vec_clonal_ID)

        for (col in 1:length(clone_phylogeny_all_genotypes)){
            vec_loc                             <- which(is.element(vec_clonal_ID,clone_phylogeny_all_genotypes[[col]]))
            if (length(vec_loc)==0){
                next
            }
            table_clonal_populations[row,col]   <- sum(vec_clonal_population[vec_loc])
        }
    }






print(clone_phylogeny_all_genotypes)

print(table_clonal_populations)

# print(clone_hclust_merge)


    # print(clone_phylogeny_genotype)



}
