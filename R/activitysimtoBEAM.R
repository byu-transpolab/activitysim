library(tidyverse)
library(xml2)
library(magrittr)
# library(modeest)

#### Set paths ####

hh_path <- "R/test/inputs/final_households.csv"
persons_path <- "R/test/inputs/final_persons.csv"
plans_path <- "R/test/inputs/final_plans.csv"
hhcoords_path <- "R/test/inputs/hhcoord.csv"


#Read in activitysim outputs

hh <- read_csv(hh_path) %>% 
  select(household_id, TAZ, income, hhsize, auto_ownership) %>%
  arrange(household_id)
persons <- read_csv(persons_path) %>% 
  select(person_id, household_id, age, sex) %>% 
  arrange(household_id, person_id)
plans <- read_csv(plans_path) %>% 
  select(person_id, ActivityType, x, y, departure_time) %>% 
  filter(!is.na(ActivityType))
hhcoords <- read_csv(hhcoords_path) %>% 
  select(-TAZ)

# tours <- read_csv("R/test/inputs/final_tours.csv")
# trips <- read_csv("R/test/inputs/final_trips.csv")
# landuse <- read_csv("R/test/inputs/final_land_use.csv")



#Add list of members to hh file

members <- split(persons$person_id, persons$household_id)
hhmembers <- tibble(household_id = as.numeric(names(members)),
                    members = unname(members))
hh <- left_join(hh, hhmembers, by = "household_id")



#Get home x,y

# homecoords <- plans %>% 
#   filter(ActivityType == "Home") %>% 
#   select(person_id, x, y) %>% 
#   group_by(person_id) %>% 
#   summarise(home_x = mfv(x),
#             home_y = mfv(y))
# 
# left_join(persons, homecoords, by = "person_id")

hh <- left_join(hh, hhcoords, by = "household_id") #Currently this is in WGS84, needs to be UTM12N
#Will need to reqork the hhcoords creator from the populationsim repo

