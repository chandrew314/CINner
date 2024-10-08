#' @export
SIMULATOR_FULL_PHASE_1_main <- function(option_lite_memory, report_progress) {
    #----------------------------Set up execution mode of CNA mechanisms
    mode_CN_WGD <<- sub(":.*", "", formula_CN_whole_genome_duplication)
    mode_CN_misseg <<- sub(":.*", "", formula_CN_missegregation)
    mode_CN_arm_misseg <<- sub(":.*", "", formula_CN_chrom_arm_missegregation)
    mode_CN_foc_amp <<- sub(":.*", "", formula_CN_focal_amplification)
    mode_CN_foc_del <<- sub(":.*", "", formula_CN_focal_deletion)
    mode_CN_cnloh_i <<- sub(":.*", "", formula_CN_cnloh_interstitial)
    mode_CN_cnloh_t <<- sub(":.*", "", formula_CN_cnloh_terminal)
    #--------------------------------Set up the initial clonal genotypes
    #   Set up the strand count for each chromosome for each clone
    genotype_list_ploidy_chrom <<- initial_ploidy_chrom
    assign("genotype_list_ploidy_chrom", genotype_list_ploidy_chrom, envir = .GlobalEnv)
    #   Set up the CN count for each chrosomome strand for each clone
    genotype_list_ploidy_block <<- initial_ploidy_block
    assign("genotype_list_ploidy_block", genotype_list_ploidy_block, envir = .GlobalEnv)
    #   Set up the CN allele info for each chromosome strand for each clone
    genotype_list_ploidy_allele <<- initial_ploidy_allele
    assign("genotype_list_ploidy_allele", genotype_list_ploidy_allele, envir = .GlobalEnv)
    #   Set up the WGD count for each clone
    genotype_list_WGD_count <<- initial_WGD_count
    assign("genotype_list_WGD_count", genotype_list_WGD_count, envir = .GlobalEnv)
    #   Set up the driver count for each clone
    genotype_list_driver_count <<- initial_driver_count
    assign("genotype_list_driver_count", genotype_list_driver_count, envir = .GlobalEnv)
    #   Set up the driver map for each clone
    genotype_list_driver_map <<- initial_driver_map
    assign("genotype_list_driver_map", genotype_list_driver_map, envir = .GlobalEnv)
    #   Set up properties of daughter cells
    genotype_list_selection_rate <<- rep(0, initial_N_clones)
    genotype_list_DNA_length <<- vector("list", initial_N_clones)
    genotype_list_prob_new_drivers <<- rep(0, initial_N_clones)
    genotype_list_prob_CNAs <<- vector("list", initial_N_clones)
    if (mode_CN_misseg == "per_homolog") genotype_list_prob_CN_misseg_homolog <<- rep(0, initial_N_clones)
    if (mode_CN_arm_misseg == "per_homolog") genotype_list_prob_CN_arm_misseg_homolog <<- rep(0, initial_N_clones)
    for (clone in 1:initial_N_clones) SIMULATOR_FULL_PHASE_1_genotype_update(genotype = clone, time = T_start_time)
    #---------------------------------Set up the clonal evolution record
    N_clones <<- initial_N_clones
    assign("N_clones", N_clones, envir = .GlobalEnv)
    #   Set up the record for current clonal populations
    clonal_ID_current <<- initial_clonal_ID
    clonal_population_current <<- initial_population
    clonal_population_next <<- clonal_population_current
    assign("clonal_ID_current", clonal_ID_current, envir = .GlobalEnv)
    assign("clonal_population_current", clonal_population_current, envir = .GlobalEnv)
    assign("clonal_population_next", clonal_population_next, envir = .GlobalEnv)
    #   Set up the record for the clonal evolution
    evolution_traj_count <- 1
    evolution_origin <<- rep(0, length(initial_clonal_ID))
    evolution_genotype_changes <<- vector("list", length = length(initial_clonal_ID))
    evolution_traj_time <- c(T_start_time)
    evolution_traj_clonal_ID <- list(clonal_ID_current)
    evolution_traj_population <- list(clonal_population_current)
    evolution_traj_divisions <- list()
    assign("evolution_origin", evolution_origin, envir = .GlobalEnv)
    assign("evolution_genotype_changes", evolution_genotype_changes, envir = .GlobalEnv)
    #----------------------------------Set up counts for the simulations
    #   Current time
    T_current <- T_start_time
    T_end_simulation <- T_end_time
    #   Count of cells still alive at current time
    N_cells_current <- sum(clonal_population_current)
    #   Count of events
    N_events_current <- 0
    #-------------------------------------------------Simulation process
    if (report_progress == TRUE) {
        pb <- txtProgressBar(
            min = T_start_time, max = T_end_simulation,
            style = 3, width = 50, char = "="
        )
    }
    while ((T_current < T_end_simulation) && (N_cells_current < Max_cell_count) && (N_events_current < Max_events)) {
        if (report_progress == TRUE) {
            setTxtProgressBar(pb, T_current)
        }
        #   Find the Poisson propensities of event count for all clones
        rate_base_lifetime <- func_event_rate(T_current)
        all_propensity <- T_tau_step * rate_base_lifetime * clonal_population_current
        #   Find the probability of division for all clones
        clonal_portion <- genotype_list_selection_rate[clonal_ID_current]
        if (!is.na(cell_prob_division)) {
            all_prob_division <- rep(cell_prob_division, length(clonal_portion))
        } else {
            all_prob_division <- func_expected_population(T_current) / (func_expected_population(T_current) + N_cells_current) * sum(clonal_population_current) * clonal_portion / sum(clonal_portion * clonal_population_current)
        }
        all_prob_division[which(all_prob_division > 1)] <- 1
        #   Find next time step and initiate next clonal population vector
        T_next <- T_current + T_tau_step
        clonal_population_next <<- clonal_population_current
        if ((N_cells_current <= 0) || (is.null(N_cells_current))) {
            flag_success <- 0
            break
        } else if (T_next >= T_end_time) {
            flag_success <- 1
            T_current <- T_end_time
            break
        }
        #   Initialize the matrix of divisions for this step
        mat_divisions <- c()
        #   Find all existing clones
        all_existing_clones <- clonal_ID_current
        #   For every existing clones...
        if (length(all_existing_clones) >= 1) {
            for (i in 1:length(all_existing_clones)) {
                #   Find clone ID
                position_to_react <- i
                clone_to_react <- all_existing_clones[i]
                genotype_to_react <- clone_to_react
                #   Find current clonal population
                clone_population <- clonal_population_current[i]
                #   Find probability of division
                prob_division <- all_prob_division[i]
                #   Find probabilities of new driver mutations & CNAs
                prob_new_drivers <- genotype_list_prob_new_drivers[clone_to_react]
                prob_CN_WGD <- genotype_list_prob_CNAs[[clone_to_react]][1]
                prob_CN_misseg <- genotype_list_prob_CNAs[[clone_to_react]][2]
                prob_CN_arm_misseg <- genotype_list_prob_CNAs[[clone_to_react]][3]
                prob_CN_foc_amp <- genotype_list_prob_CNAs[[clone_to_react]][4]
                prob_CN_foc_del <- genotype_list_prob_CNAs[[clone_to_react]][5]
                prob_CN_cnloh_i <- genotype_list_prob_CNAs[[clone_to_react]][6]
                prob_CN_cnloh_t <- genotype_list_prob_CNAs[[clone_to_react]][7]
                #   Find probability of new genotypes
                prob_new_genotype <- 1 - (1 - prob_new_drivers) * (1 - prob_CN_WGD) * (1 - prob_CN_misseg) * (1 - prob_CN_arm_misseg) * (1 - prob_CN_foc_amp) * (1 - prob_CN_foc_del) * (1 - prob_CN_cnloh_i) * (1 - prob_CN_cnloh_t)
                #   Find number of events
                prop <- all_propensity[i]
                count_new_events <- Inf
                while ((count_new_events > clone_population) || (count_new_events < 0)) {
                    if (prop > 1000) {
                        count_new_events <- round(rnorm(n = 1, mean = prop, sd = sqrt(prop)))
                    } else {
                        count_new_events <- rpois(n = 1, lambda = prop)
                    }
                }
                N_events_current <- N_events_current + count_new_events
                count_event_types <- rmultinom(n = 1, size = count_new_events, prob = c((1 - prob_division), prob_division * (1 - prob_new_genotype), prob_division * prob_new_genotype))
                count_deaths <- count_event_types[1]
                count_div_old <- count_event_types[2]
                count_div_new_tmp <- count_event_types[3]
                count_div_new <- count_div_new_tmp
                #---Perform death events
                clonal_population_next[i] <<- clonal_population_next[i] - count_deaths
                #---Perform division events with no new genotype
                clonal_population_next[i] <<- clonal_population_next[i] + count_div_old
                #---Perform division events with new genotype
                if (count_div_new_tmp >= 1) {
                    for (j in 1:count_div_new_tmp) {
                        #   Find what events lead to the new genotype
                        flag_drivers <- 0
                        flag_whole_genome_duplication <- 0
                        flag_missegregation <- 0
                        flag_chrom_arm_missegregation <- 0
                        flag_amplification <- 0
                        flag_deletion <- 0
                        flag_cnloh_interstitial <- 0
                        flag_cnloh_terminal <- 0
                        vec_flag <- c(flag_drivers, flag_whole_genome_duplication, flag_missegregation, flag_chrom_arm_missegregation, flag_amplification, flag_deletion, flag_cnloh_interstitial, flag_cnloh_terminal)
                        while (max(vec_flag) == 0) {
                            flag_drivers <- as.numeric(runif(1) < (prob_new_drivers / prob_new_genotype))
                            flag_whole_genome_duplication <- as.numeric(runif(1) < (prob_CN_WGD / prob_new_genotype))
                            flag_missegregation <- as.numeric(runif(1) < (prob_CN_misseg / prob_new_genotype))
                            flag_chrom_arm_missegregation <- as.numeric(runif(1) < (prob_CN_arm_misseg / prob_new_genotype))
                            flag_amplification <- as.numeric(runif(1) < (prob_CN_foc_amp / prob_new_genotype))
                            flag_deletion <- as.numeric(runif(1) < (prob_CN_foc_del / prob_new_genotype))
                            flag_cnloh_interstitial <- as.numeric(runif(1) < (prob_CN_cnloh_i / prob_new_genotype))
                            flag_cnloh_terminal <- as.numeric(runif(1) < (prob_CN_cnloh_t / prob_new_genotype))
                            vec_flag <- c(flag_drivers, flag_whole_genome_duplication, flag_missegregation, flag_chrom_arm_missegregation, flag_amplification, flag_deletion, flag_cnloh_interstitial, flag_cnloh_terminal)
                        }
                        #   Initiate the two new genotypes
                        output <- SIMULATOR_FULL_PHASE_1_genotype_initiation(genotype_to_react)
                        genotype_daughter_1 <- output[[1]]
                        position_daughter_1 <- output[[2]]
                        genotype_daughter_2 <- output[[3]]
                        position_daughter_2 <- output[[4]]
                        #   Simulate new driver event
                        if (flag_drivers == 1) {
                            SIMULATOR_FULL_PHASE_1_drivers(
                                genotype_to_react = genotype_to_react,
                                genotype_daughter_1 = genotype_daughter_1,
                                genotype_daughter_2 = genotype_daughter_2
                            )
                        }
                        #   Simulate whole genome duplication event
                        if (flag_whole_genome_duplication == 1) {
                            if (genotype_list_WGD_count[genotype_to_react] < bound_WGD) {
                                SIMULATOR_FULL_PHASE_1_CN_whole_genome_duplication(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter_1 = genotype_daughter_1,
                                    genotype_daughter_2 = genotype_daughter_2
                                )
                            }
                        }
                        #   Simulate missegregation event
                        if (flag_missegregation == 1) {
                            if (mode_CN_misseg == "per_division") {
                                N_events <- 1
                            } else if (mode_CN_misseg == "per_homolog") {
                                prob_CN_misseg_homolog <- genotype_list_prob_CN_misseg_homolog[genotype_to_react]
                                chrom_ploidy <- genotype_list_ploidy_chrom[[genotype_to_react]]
                                N_events_prob <- dbinom(1:sum(chrom_ploidy), sum(chrom_ploidy), prob_CN_misseg_homolog)
                                N_events_prob <- N_events_prob / sum(N_events_prob)
                                N_events <- sample.int(sum(chrom_ploidy), size = 1, prob = N_events_prob)
                            }
                            for (i_event in 1:N_events) {
                                SIMULATOR_FULL_PHASE_1_CN_missegregation(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter_1 = genotype_daughter_1,
                                    genotype_daughter_2 = genotype_daughter_2
                                )
                            }
                        }
                        #   Simulate chromosome-arm missegregation event
                        if (flag_chrom_arm_missegregation == 1) {
                            if (mode_CN_arm_misseg == "per_division") {
                                N_events <- 1
                            } else if (mode_CN_arm_misseg == "per_homolog") {
                                prob_CN_arm_misseg_homolog <- genotype_list_prob_CN_arm_misseg_homolog[genotype_to_react]
                                chrom_ploidy <- genotype_list_ploidy_chrom[[genotype_to_react]]
                                N_events_prob <- dbinom(1:sum(chrom_ploidy), sum(chrom_ploidy), prob_CN_arm_misseg_homolog)
                                N_events_prob <- N_events_prob / sum(N_events_prob)
                                N_events <- sample.int(sum(chrom_ploidy), size = 1, prob = N_events_prob)
                            }
                            for (i_event in 1:N_events) {
                                SIMULATOR_FULL_PHASE_1_CN_chrom_arm_missegregation(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter_1 = genotype_daughter_1,
                                    genotype_daughter_2 = genotype_daughter_2
                                )
                            }
                        }
                        #   Simulate focal amplification event
                        if (flag_amplification == 1) {
                            if (sample.int(2, size = 1) == 1) {
                                SIMULATOR_FULL_PHASE_1_CN_focal_amplification(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter = genotype_daughter_1
                                )
                            } else {
                                SIMULATOR_FULL_PHASE_1_CN_focal_amplification(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter = genotype_daughter_2
                                )
                            }
                        }
                        #   Simulate focal deletion event
                        if (flag_deletion == 1) {
                            if (sample.int(2, size = 1) == 1) {
                                SIMULATOR_FULL_PHASE_1_CN_focal_deletion(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter = genotype_daughter_1
                                )
                            } else {
                                SIMULATOR_FULL_PHASE_1_CN_focal_deletion(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter = genotype_daughter_2
                                )
                            }
                        }
                        #   Simulate interstitial CN-LOH event
                        if (flag_cnloh_interstitial == 1) {
                            if (sample.int(2, size = 1) == 1) {
                                SIMULATOR_FULL_PHASE_1_CN_cnloh_interstitial(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter = genotype_daughter_1
                                )
                            } else {
                                SIMULATOR_FULL_PHASE_1_CN_cnloh_interstitial(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter = genotype_daughter_2
                                )
                            }
                        }
                        #   Simulate terminal CN-LOH event
                        if (flag_cnloh_terminal == 1) {
                            if (sample.int(2, size = 1) == 1) {
                                SIMULATOR_FULL_PHASE_1_CN_cnloh_terminal(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter = genotype_daughter_1
                                )
                            } else {
                                SIMULATOR_FULL_PHASE_1_CN_cnloh_terminal(
                                    genotype_to_react = genotype_to_react,
                                    genotype_daughter = genotype_daughter_2
                                )
                            }
                        }
                        #   Update properties of daughter cells
                        SIMULATOR_FULL_PHASE_1_genotype_update(genotype = genotype_daughter_1, time = T_current)
                        SIMULATOR_FULL_PHASE_1_genotype_update(genotype = genotype_daughter_2, time = T_current)
                        #   Check if either daughter cell did not create a new clone
                        output <- SIMULATOR_FULL_PHASE_1_genotype_cleaning(genotype_to_react, genotype_daughter_1, genotype_daughter_2, position_to_react, position_daughter_1, position_daughter_2)
                        genotype_to_react <- output[[1]]
                        genotype_daughter_1 <- output[[2]]
                        genotype_daughter_2 <- output[[3]]
                        position_to_react <- output[[4]]
                        position_daughter_1 <- output[[5]]
                        position_daughter_2 <- output[[6]]
                        #   Adjust the event count accordingly, and add event to
                        #   matrix of divisions
                        if ((genotype_daughter_1 == genotype_to_react) && (genotype_daughter_2 == genotype_to_react)) {
                            count_div_new <- count_div_new - 1
                            count_div_old <- count_div_old + 1
                        } else {
                            mat_divisions <- rbind(mat_divisions, c(1, genotype_to_react, genotype_daughter_1, genotype_daughter_2))
                        }
                        #   Update the clonal population according to what happens
                        clonal_population_next[position_to_react] <<- clonal_population_next[position_to_react] - 1
                        clonal_population_next[position_daughter_1] <<- clonal_population_next[position_daughter_1] + 1
                        clonal_population_next[position_daughter_2] <<- clonal_population_next[position_daughter_2] + 1
                    }
                }
                #   Add the divisions with old genotype to the matrix of divisions
                if (count_div_old > 0) {
                    mat_divisions <- rbind(mat_divisions, c(count_div_old, genotype_to_react, genotype_to_react, genotype_to_react))
                }
            }
        }
        #   Clean clonal populations
        SIMULATOR_FULL_PHASE_1_clonal_population_cleaning(option_lite_memory)
        #   Update clonal populations
        clonal_population_current <<- clonal_population_next
        #   Update time
        T_current <- T_next
        #   Update count of cells
        N_cells_current <- sum(clonal_population_current)
        #   Update record of clonal evolution over time
        evolution_traj_count <- evolution_traj_count + 1

        evolution_traj_time[evolution_traj_count] <- T_current
        evolution_traj_clonal_ID[[evolution_traj_count]] <- clonal_ID_current
        evolution_traj_population[[evolution_traj_count]] <- clonal_population_current
        evolution_traj_divisions[[evolution_traj_count - 1]] <- mat_divisions
    }
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # get_clonal_stats <- function(genotype_list_ploidy_chrom,
    #                              genotype_list_ploidy_block,
    #                              genotype_list_ploidy_allele,
    #                              clone_ID) {
    #     ploidy_normalization <- TRUE
    #     plotcol <- "state"
    #     fillna <- TRUE
    #     state_mode <- NULL
    #     #   Find total CN profile
    #     tmp <- list()
    #     tmp$genotype_list_ploidy_chrom <- genotype_list_ploidy_chrom
    #     tmp$genotype_list_ploidy_block <- genotype_list_ploidy_block
    #     tmp$genotype_list_ploidy_allele <- genotype_list_ploidy_allele
    #     CNbins_sims <- get_cn_profile(tmp, clone_ID)
    #     CNbins_sims$cell_id <- paste0("SIMULATION1-Library-1-1")
    #     class(CNbins_sims) <- "data.frame"
    #     copynumber_sims <- createCNmatrix(CNbins_sims,
    #         field = plotcol, wholegenome = FALSE,
    #         fillnaplot = fillna, centromere = FALSE
    #     )
    #     if (ploidy_normalization == TRUE) {
    #         copynumber_sims <- normalize_cell_ploidy(copynumber_sims, state_mode)
    #     }
    #     #   Statistics - FGA
    #     sample_CN <- copynumber_sims[[paste0("SIMULATION1-Library-1-1")]]
    #     FGA <- length(which(sample_CN != 2)) / length(sample_CN)
    #     #   Output statistics
    #     stat <- list()
    #     stat$FGA <- FGA
    #     return(stat)
    # }
    # best_clone <- clonal_ID_current[which(clonal_population_current == max(clonal_population_current))][1]
    # print(best_clone)
    # WGD_status <- 0
    # clone <- best_clone
    # while (clone > 0) {
    #     if (length(evolution_genotype_changes[[clone]]) > 0) {
    #         for (j in 1:length(evolution_genotype_changes[[clone]])) {
    #             if (evolution_genotype_changes[[clone]][[j]][1] == "whole-genome-duplication") WGD_status <- 1
    #         }
    #     }
    #     clone <- evolution_origin[clone]
    # }
    # cat(paste0("\n\n\nBEST CLONE:\n"))
    # if (WGD_status == 0) {
    #     cat(paste0("WGD status:     Non-WGD\n"))
    # } else {
    #     cat(paste0("WGD status:     WGD\n"))
    # }
    # stats <- get_clonal_stats(
    #     genotype_list_ploidy_chrom,
    #     genotype_list_ploidy_block,
    #     genotype_list_ploidy_allele,
    #     best_clone
    # )
    # cat(paste0("FGA:            ", stats$FGA, "\n"))
    # # TMPTMP <<- 1
    # # driver_count <- genotype_list_driver_count[best_clone]
    # # driver_map <- genotype_list_driver_map[[best_clone]]
    # # ploidy_chrom <- genotype_list_ploidy_chrom[[best_clone]]
    # # ploidy_block <- genotype_list_ploidy_block[[best_clone]]
    # # ploidy_allele <- genotype_list_ploidy_allele[[best_clone]]
    # # SIMULATOR_FULL_PHASE_1_selection_rate(driver_count, driver_map, ploidy_chrom, ploidy_block, ploidy_allele)
    # # TMPTMP <<- 0
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    # ################################################################
    if (report_progress == TRUE) {
        cat("\n")
    }
    if (T_end_simulation > evolution_traj_time[length(evolution_traj_time)]) {
        evolution_traj_count <- evolution_traj_count + 1

        evolution_traj_time[evolution_traj_count] <- T_end_simulation
        evolution_traj_clonal_ID[[evolution_traj_count]] <- evolution_traj_clonal_ID[[evolution_traj_count - 1]]
        evolution_traj_population[[evolution_traj_count]] <- evolution_traj_population[[evolution_traj_count - 1]]
        evolution_traj_divisions[[evolution_traj_count - 1]] <- c()
    }
    #-----------------------------Output package of data from simulation
    if (is.null(N_cells_current) | (N_cells_current < Min_cell_count)) {
        flag_success <- 0
    }
    package_clonal_evolution <- list()
    package_clonal_evolution$T_current <- T_current
    package_clonal_evolution$N_cells_current <- N_cells_current
    package_clonal_evolution$N_events_current <- N_events_current
    package_clonal_evolution$N_clones <- N_clones
    package_clonal_evolution$genotype_list_ploidy_chrom <- genotype_list_ploidy_chrom
    package_clonal_evolution$genotype_list_ploidy_block <- genotype_list_ploidy_block
    package_clonal_evolution$genotype_list_ploidy_allele <- genotype_list_ploidy_allele
    package_clonal_evolution$genotype_list_WGD_count <- genotype_list_WGD_count
    package_clonal_evolution$genotype_list_driver_count <- genotype_list_driver_count
    package_clonal_evolution$genotype_list_driver_map <- genotype_list_driver_map
    package_clonal_evolution$genotype_list_selection_rate <- genotype_list_selection_rate
    package_clonal_evolution$evolution_origin <- evolution_origin
    package_clonal_evolution$evolution_genotype_changes <- evolution_genotype_changes
    package_clonal_evolution$evolution_traj_time <- evolution_traj_time
    package_clonal_evolution$evolution_traj_divisions <- evolution_traj_divisions
    package_clonal_evolution$evolution_traj_clonal_ID <- evolution_traj_clonal_ID
    package_clonal_evolution$evolution_traj_population <- evolution_traj_population

    output <- list()
    output$flag_success <- flag_success
    output$package_clonal_evolution <- package_clonal_evolution

    return(output)
}
