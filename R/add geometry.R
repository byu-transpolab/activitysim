library(tidyverse)
library(magrittr)
library(sf)
library(wellknown)

taz <- read_sf("UTA_TAZ/UTA_TAZ.shp")
landUse <- read_csv("wfrc_asim_scenario/data/land_use_taz.csv")

taz %<>% st_transform(crs = 26912)

tazGeom <- tibble(
  ID = taz$TAZID,
  geometry = sf_convert(taz)
)

landUseGeom <- full_join(
  landUse, tazGeom,
  by = c("ZONE" = "ID")
)

write_csv(landUseGeom, "wfrc_asim_scenario/data/land_use_taz_geom.csv")