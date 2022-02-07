%======================================SIMULATE WHOLE GENOME DUPLICATION
function SIMULATOR_FULL_PHASE_1_CN_whole_genome_duplication(genotype_to_react,genotype_daughter_1,genotype_daughter_2)
    global genotype_list_ploidy_chrom genotype_list_ploidy_allele genotype_list_ploidy_block
    global genotype_list_driver_count genotype_list_driver_map genotype_list_DNA_length genotype_list_selection_rate
    global N_clones evolution_origin evolution_genotype_changes clonal_population_current evolution_traj_population

    global N_chromosomes size_CN_block_DNA vec_CN_block_no
    global growth_model bound_driver
    global driver_library
%------------------------------------Find the new CN and driver profiles
    % fprintf('\n=========================================================\nWHOLE GENOME DUPLICATION\n');
%   Find the daughter cells' current CN and driver profiles
    ploidy_chrom_1      = genotype_list_ploidy_chrom{genotype_daughter_1};
    ploidy_allele_1     = genotype_list_ploidy_allele{genotype_daughter_1};
    ploidy_block_1      = genotype_list_ploidy_block{genotype_daughter_1};
    driver_count_1      = genotype_list_driver_count(genotype_daughter_1);
    driver_map_1        = genotype_list_driver_map{genotype_daughter_1};

    ploidy_chrom_2      = genotype_list_ploidy_chrom{genotype_daughter_2};
    ploidy_allele_2     = genotype_list_ploidy_allele{genotype_daughter_2};
    ploidy_block_2      = genotype_list_ploidy_block{genotype_daughter_2};
    driver_count_2      = genotype_list_driver_count(genotype_daughter_2);
    driver_map_2        = genotype_list_driver_map{genotype_daughter_2};
%   Change the chromosome ploidy of daughter cells
    ploidy_chrom_1      = 2*ploidy_chrom_1;
    ploidy_chrom_2      = 2*ploidy_chrom_2;
%   Update the chromosome strand allele identities of daughter cells
    ploidy_allele_1     = [ploidy_allele_1;zeros(size(ploidy_allele_1,1),N_chromosomes)];
    for chrom=1:N_chromosomes
        chrom_ploidy    = ploidy_chrom_1(chrom);
        ploidy_allele_1(chrom_ploidy/2+1:chrom_ploidy,chrom)    = ploidy_allele_1(1:chrom_ploidy/2,chrom);
    end
    ploidy_allele_2     = [ploidy_allele_2;zeros(size(ploidy_allele_2,1),N_chromosomes)];
    for chrom=1:N_chromosomes
        chrom_ploidy    = ploidy_chrom_2(chrom);
        ploidy_allele_2(chrom_ploidy/2+1:chrom_ploidy,chrom)    = ploidy_allele_2(1:chrom_ploidy/2,chrom);
    end
%   Multiply the chromosome strands in each daughter cell
    for chrom=1:N_chromosomes
        chrom_ploidy    = ploidy_chrom_1(chrom);
        for strand=1:chrom_ploidy/2
            ploidy_block_1{chrom,chrom_ploidy/2+strand} = ploidy_block_1{chrom,strand};
        end
        chrom_ploidy    = ploidy_chrom_2(chrom);
        for strand=1:chrom_ploidy/2
            ploidy_block_2{chrom,chrom_ploidy/2+strand} = ploidy_block_2{chrom,strand};
        end
    end
%   Change the driver count in each daughter cell
    driver_count_1      = 2*driver_count_1;
    driver_count_2      = 2*driver_count_2;
%   Multiply the drivers in each daughter cell
    driver_map_1(driver_count_1/2+1:driver_count_1,:)   = driver_map_1(1:driver_count_1/2,:);
    for driver=size(driver_map_1,1)/2+1:size(driver_map_1,1)
        chrom                           = driver_map_1(driver,2);
        chrom_ploidy                    = ploidy_chrom_1(chrom);
        driver_map_1(driver,3)          = driver_map_1(driver,3)+chrom_ploidy;
    end
    driver_map_2(driver_count_2/2+1:driver_count_2,:)   = driver_map_2(1:driver_count_2/2,:);
    for driver=size(driver_map_2,1)/2+1:size(driver_map_2,1)
        chrom                           = driver_map_2(driver,2);
        chrom_ploidy                    = ploidy_chrom_2(chrom);
        driver_map_2(driver,3)          = driver_map_2(driver,3)+chrom_ploidy;
    end
%-----------------------------------------------Output the new genotypes
    genotype_list_ploidy_chrom{genotype_daughter_1}         = ploidy_chrom_1;
    genotype_list_ploidy_allele{genotype_daughter_1}        = ploidy_allele_1;
    genotype_list_ploidy_block{genotype_daughter_1}         = ploidy_block_1;
    genotype_list_driver_count(genotype_daughter_1)         = driver_count_1;
    genotype_list_driver_map{genotype_daughter_1}           = driver_map_1;
    evolution_genotype_changes{genotype_daughter_1}{end+1}  = {'whole-genome-duplication'};

    genotype_list_ploidy_chrom{genotype_daughter_2}         = ploidy_chrom_2;
    genotype_list_ploidy_allele{genotype_daughter_2}        = ploidy_allele_2;
    genotype_list_ploidy_block{genotype_daughter_2}         = ploidy_block_2;
    genotype_list_driver_count(genotype_daughter_2)         = driver_count_2;
    genotype_list_driver_map{genotype_daughter_2}           = driver_map_2;
    evolution_genotype_changes{genotype_daughter_2}{end+1}  = {'whole-genome-duplication'};
end
