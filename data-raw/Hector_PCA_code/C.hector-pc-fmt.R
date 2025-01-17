#### Compute principal components from ensembles of hector runs

library(assertthat)
library(foreach)


outdir <- 'PCA-data'

### Get principal components for the concentration-driven runs.
conc_files <- list.files('PCA-data', '^concen-', full.names=TRUE)
conc_scenlist <- lapply(conc_files, readRDS)
conc_expts <- sapply(conc_scenlist, function(d){d$experiment[1]})
## We want to do all combinations of these scenarios.  There are 31 possible
## combinations (not counting the degenerate case where none of them are
## included).  Number them from 1-15 and use the bit patterns to figure out
## which scenarios should be included.
doParallel::registerDoParallel(cores=8)
conc_vars <- 'tas'
emiss_vars <- c('tas','co2')
conc_hflux_vars <- c('tas', 'heatflux')
emiss_hflux_vars <- c('tas', 'co2', 'heatflux')

pca_all_combos <- function(name_stem, vars) {
    pcas <- foreach(i=1:31) %dopar% {
        expts_l <- as.logical(c(bitwAnd(i,1), bitwAnd(i,2), bitwAnd(i,4), bitwAnd(i,8), bitwAnd(i,16)))
        expts <- conc_expts[expts_l]
        scenlist <- conc_scenlist[expts_l]

        hectorcal::compute_pc(scenlist, expts, vars, 2006:2100, 1861:2005)
    }
    for(pca in pcas) {
        filename <- paste0(name_stem,paste0(pca$meta_data$experiment,
                                            collapse='-'), '.rds')
        saveRDS(pca, file.path(outdir, filename))
    }
    invisible(NULL)
}

## Concentration runs without heat flux
pca_all_combos('pc-conc-', conc_vars)

## Concentration runs with heat flux
pca_all_combos('pc-conc-hflux-', conc_hflux_vars)


## For the emissions run we really only want the rcp85 and historical runs for now
emiss_files <- c('PCA-data/emissCC-esmrcp85.rds', 'PCA-data/emissCC-esmHistorical.rds')
emiss_scenlist <- lapply(emiss_files, readRDS)
emiss_pca <- hectorcal::compute_pc(emiss_scenlist, c('esmrcp85', 'esmHistorical'), emiss_vars , 2006:2100, 1861:2005)
saveRDS(emiss_pca, file.path(outdir, 'pc-emissCC-esmHistorical-esmrcp85.rds'))

## Also run with heat flux included
emiss_hflux_pca <- hectorcal::compute_pc(emiss_scenlist, c('esmrcp85', 'esmHistorical'),
                                         emiss_hflux_vars, 2006:2100, 1861:2005)
saveRDS(emiss_hflux_pca, file.path(outdir,
                                   'pc-emissCC-hflux-esmHistorical-esmrcp85.rds'))
