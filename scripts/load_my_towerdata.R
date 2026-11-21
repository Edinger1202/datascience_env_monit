#--------------------- Load packages -------------------------------------------
packages_needed <- c("dplyr", "readr", "ggplot2", "tidyverse")

missing <- packages_needed[!packages_needed %in% installed.packages()]

if(length(missing) > 0){
  install.packages(missing)
}

invisible(lapply(packages_needed, library, character.only =T))

#---------------- Define which columns of tower data to keep ------------------

keep <- c("TIMESTAMP_START", "TIMESTAMP_END", "TA_F", "SW_IN_F", "VPD_F", "P_F",
          "NETRAD", "G_F_MDS", "H_F_MDS", "H_F_MDS_QC", "LE_F_MDS", "LE_F_MDS_QC",
          "NEE_VUT_REF", "NEE_VUT_REF_QC", "GPP_NT_VUT_REF", "RECO_NT_VUT_REF")

#---------------- Define Function to load tower data ---------------------------

read_hh <- function(zip_dir = "data/raw",
                    keep,
                    out_dir = file.path(zip_dir, "unzipped")) {
  
  # zips im angegebenen Ordner finden
  zip_paths <- list.files(zip_dir, pattern = "\\.zip$", full.names = TRUE)
  if (length(zip_paths) == 0) stop("Keine zip-Dateien gefunden in: ", zip_dir)
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  data_list <- list()
  
  for (i in seq_along(zip_paths)) {
    zip_path <- zip_paths[i]
    
    hh_file  <- grep("FLUXMET_HH", unzip(zip_path, list = TRUE)$Name, value = TRUE)
    site     <- sub("^[^_]+_([^_]+)_.*", "\\1", basename(zip_path))
    csv_path <- file.path(out_dir, basename(hh_file))
    
    if (!file.exists(csv_path)) {
      unzip(zip_path, files = hh_file, exdir = out_dir, junkpaths = TRUE)
    }
    
    hh <- read_csv(csv_path, na = "-9999",
                   col_select = all_of(keep),
                   col_types = cols(TIMESTAMP_START = "c", TIMESTAMP_END = "c",
                                    .default = "d")) |>
      mutate(time = as.POSIXct(TIMESTAMP_START, format = "%Y%m%d%H%M", tz = "UTC"),
             site = site)
    
    data_list[[i]] <- hh
    message("Eingelesen: ", site, " -> ", basename(hh_file))
  }
  
  bind_rows(data_list)
}

