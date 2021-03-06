# Afreen Alam
# HW 15: Analysis of COVID-19 data



# Load libraries ----------------------------------------------------------

library(tidyverse)
library(here)
library(lubridate)
library(sf)
library(patchwork)
library(gghighlight)
library(ggthemes)


# Define constants --------------------------------------------------------

### First US case
first_us_case <- "19 Jan 2020"

### First MO case
first_mo_case <- "08 Mar 2020"

### The lower 48 states
lower_48 <- c("Alabama", "Arizona",
              "Arkansas", "California",
              "Colorado", "Connecticut",
              "Delaware", "Florida",
              "Georgia", "Idaho",
              "Illinois", "Indiana",
              "Iowa", "Kansas",
              "Kentucky", "Louisiana",
              "Maine", "Maryland",
              "Massachusetts", "Michigan",
              "Minnesota", "Mississippi",
              "Missouri", "Montana",
              "Nebraska", "Nevada",
              "New Hampshire", "New Jersey",
              "New Mexico", "New York",
              "North Carolina", "North Dakota",
              "Ohio", "Oklahoma",
              "Oregon", "Pennsylvania",
              "Rhode Island", "South Carolina",
              "South Dakota", "Tennessee",
              "Texas", "Utah", "Vermont",
              "Virginia", "Washington",
              "West Virginia",
              "Wisconsin", "Wyoming")

### CDC regions assigned respective state FIPS.
northeast_fips <-  c(9, 23, 25, 33, 44, 50,
                     34, 36, 42)
midwest_fips <- c(18, 17, 26, 39, 55,
                    19, 20, 27, 29,
                    31, 38, 46)
south_fips <-  c(10, 11, 12, 13, 24,
                 37, 45, 51, 54,
                 1, 21, 28, 47,
                 5, 22, 40, 48)
west_fips <-  c(4, 8, 16, 35,
                 30, 49, 32, 56,
                 2, 6, 15, 41, 53)



# Functions ---------------------------------------------------------------


### Write an R function that calculates the number
### of daily new cases from a vector of daily total cases.

new_from_total <- function(args) {
  length_args <- length(args) # Number of input values
  # Vector with first value as 0 and all except last input value
  with_first_value <- c(0, args[1:length_args - 1])
  # Input value subtracted with previous value
  diff <- args - with_first_value
  return(diff) # Returns difference as result
}



# Initial import and wrangling --------------------------------------------

### Use ISO8601 YYYY-MM-DD format

covid_confirmed_raw <- read_csv(here("data",
                                     "covid_confirmed_usafacts.csv"))
covid_confirmed <- covid_confirmed_raw %>%
  filter(countyFIPS != 0 & stateFIPS != 0) %>%
  pivot_longer(c(`1/22/20`:`7/31/20`),
               names_to = "date",
               values_to = "cases") %>%
  mutate(date = mdy(date)) %>%
  filter(date >= dmy(first_us_case))
  


covid_deaths_raw <- read_csv(here("data",
                                  "covid_deaths_usafacts.csv"))
covid_deaths <- covid_deaths_raw %>%
  filter(countyFIPS != 0 & stateFIPS != 0) %>%
  pivot_longer(c(`1/22/20`:`7/31/20`),
               names_to = "date",
               values_to = "deaths") %>%
  mutate(date = mdy(date)) %>%
  filter(date >= dmy(first_us_case))



county_population_raw <- read_csv(here("data",
                                       "covid_county_population_usafacts.csv"))
state_population <- county_population_raw %>%
  filter(countyFIPS != 0)


semo_county_raw <- read_csv(here("data",
                                 "semo_county_enrollment.csv"),
                            skip = 1)
semo_county <- semo_county_raw %>%
  rename("County Name" = X1)








# Plots


# Plot 1 -------------------------------------------------------------------

plot_1_data <- covid_confirmed %>%
  left_join(covid_deaths) %>%
  mutate(Region = case_when(
    stateFIPS %in%  northeast_fips ~ "Northeast",
    stateFIPS %in%  midwest_fips ~ "Midwest",
    stateFIPS %in%  south_fips ~ "South",
    stateFIPS %in%  west_fips ~ "West")) %>%
      filter(date >= dmy(first_mo_case)) %>%
      group_by(Region, date) %>%
      summarise(total_cases = sum(cases, na.rm = TRUE),
                total_deaths = sum(deaths, na.rm = TRUE))
    
p_cases <- ggplot(plot_1_data) +
  geom_line(aes(x = date,
                y = total_cases,
                color = Region), size = 1) +
  labs(x = NULL,
       y = "Total Cases") +
  theme_test() +
  theme(legend.position = "bottom")

p_deaths <- ggplot(plot_1_data) +
  geom_line(aes(x = date,
                y = total_deaths,
                color = Region), size = 1) +
  labs(x = NULL,
       y = "Total Deaths") +
  theme_test() +
  theme(legend.position = "none")

  
  
p_cases + p_deaths +
  plot_layout(nrow = 1)


# Plot 2 -------------------------------------------------------------------
## Plot 2: Highlight Missouri Counties with 200+ students at SEMO

plot_2_data <- covid_confirmed %>%
  filter(State == "MO",
         date >= dmy(first_mo_case)) %>%
  mutate(`County Name` = str_replace(`County Name`, " County$", ""),
         `County Name` = str_replace(`County Name`, "^Jackson.*", "Jackson"))


semo_data <- semo_county %>%
  select(-c(`2015`:`2018`)) %>%
  mutate(`County Name` =
           str_replace_all(`County Name`,
                           c("De Kalb" = "DeKalb",
                             "Sainte" = "Ste\\.",
                             "Saint" = "St\\.",
                             "St\\. Louis City" = "City of St\\. Louis")))


plot_2_final <- plot_2_data %>%
  group_by(`County Name`, date) %>%
  summarise(total_confirmed = sum(cases,
                                  na.rm = TRUE)) %>%
  left_join(semo_data)
  

  
  ggplot(plot_2_final) +
  geom_line(aes(x = date,
                y = total_confirmed,
                color = `County Name`),
            size = 0.7) +
  labs(x = NULL,
       y = "Total Confirmed Cases",
       color = "County") +
    gghighlight(`2019` >= 200,
                use_direct_label = FALSE) +
    theme_test() +
    scale_x_date(date_labels = "%d %b")
  


# Plot 3 -------------------------------------------------------------------

## Plot 3: Cleveland plot comparing number of cases in April and July


plot_3_1 <- covid_confirmed %>%
  filter(date %in% c(ymd("2020-04-01"), ymd("2020-07-01"))) %>%
  rename(cases_first = cases,
         date_first = date) %>%
  group_by(State, date_first) %>%
  summarise(cases_first = sum(cases_first))

plot_3_1a <- plot_3_1 %>%
  filter(date_first == ymd("2020-04-01"))
plot_3_1b <- plot_3_1 %>%
  filter(date_first == ymd("2020-07-01"))


plot_3_last <- covid_confirmed %>%
  filter(date %in% c(ymd("2020-04-30"), ymd("2020-07-30"))) %>%
  rename(cases_last = cases,
         date_last = date) %>%
  group_by(State, date_last) %>%
  summarise(cases_last = sum(cases_last))

plot_3_last_a <- plot_3_last %>%
  filter(date_last == ymd("2020-04-30"))
plot_3_last_b <- plot_3_last %>%
  filter(date_last == ymd("2020-07-30"))


state_population_3 <- state_population %>%
  group_by(State) %>%
  summarise(population = sum(population))

plot_3_bottom <- left_join(plot_3_1b, plot_3_last_b) %>%
  mutate(new_cases = cases_last - cases_first) %>%
  left_join(state_population_3) %>%
  mutate(case_rate = (new_cases / population) * 100000) %>%
  arrange(case_rate)

order_states <- plot_3_bottom$State
order_states <- factor(order_states, ordered = TRUE)
          
plot_3_top <- left_join(plot_3_1a, plot_3_last_a) %>%
  mutate(new_cases = cases_last - cases_first) %>%
  left_join(state_population_3) %>%
  mutate(case_rate = (new_cases / population) * 100000) %>%
  arrange(plot_3_bottom$State)





plot_3 <- plot_3_top %>%
  rbind(plot_3_bottom) %>%
  mutate(month = month(date_first, label = TRUE),
         State = factor(State, ordered = TRUE,
                        levels = order_states)) %>%
  select(month, State, case_rate)

ggplot(plot_3,
       aes(x = State,
           y = case_rate),
       group = State) +
  geom_line(color = "gray50") +
  geom_point(aes(fill = month,
                 shape = month),
             size = 2) +
  coord_flip() +
  scale_shape_manual(values = c(22, 21)) +
  scale_fill_brewer(palette = "Dark2") +
  theme_minimal() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        legend.position = "none") +
  labs(x = NULL,
       y = "COVID-19 cases (per 100,000) for\nApril(squares) & July(circles)")
  
  



# Plot 4 ------------------------------------------------------------------

## Plot 4: Missouri COVID cases, highlighting when state opened.
   
   
plot_4_data <- covid_confirmed %>%
     filter(State == "MO",
            date >= dmy(first_mo_case)) %>%
     group_by(date) %>%
     summarise(total_cases = sum(cases)) %>%
     mutate(daily = new_from_total(total_cases))
   
### frollmean calculates a 7-day rolling average of daily new cases.
plot_4_data$roll_mean <-
  data.table::frollmean(plot_4_data$daily,
                        7, align = "right") %>%
  replace_na(0)
   
### Graph data
   
plot_4_data %>%
  ggplot(aes(x = date, y = daily)) +
  geom_col(color = "gray85",
           fill = "grey70") +
  scale_x_date(date_labels = "%b %d",
               date_breaks = "2 weeks") +
  theme_test() +
  geom_col(data = filter(plot_4_data,
                         date == dmy("16 June 2020")),
           mapping = aes(x = date, y = daily),
           color = "gray85",
           fill = "#C8102E") +
  geom_line(aes(x = date, y = roll_mean),
            color = "#9D2235",
            size = 0.6) +
  annotate("text", x = mdy("Jun 01 2020"), y = 450,
           label = "Missouri reopened\n       16 June 2020",
           color = "#C8102E") +
  labs(x = NULL,
       y = "Daily New Cases")
  


# Plot 5 ------------------------------------------------------------------

## Plot 5: Table and choropleth map



plot_5_data <- covid_confirmed %>%
  left_join(covid_deaths) %>%
  filter(date == ymd("2020-07-31")) %>%
  group_by(State) %>%
  summarise("Total Cases" = sum(cases, na.rm = TRUE),
            "Total Deaths" = sum(deaths, na.rm = TRUE)) %>%
  mutate("Death Rate (%)" = (`Total Deaths` / `Total Cases`)
         * 100)


### Table for part 5

table_part_5 <- plot_5_data %>%
  filter(`Death Rate (%)` >= 5) %>%
  arrange(desc(`Death Rate (%)`))
table_part_5
  
  
states <- st_read(here::here("data",
                             "cb_2017_us_state_500k.shp"),
                  stringsAsFactors = TRUE)


states_df <- states %>%
  dplyr::filter(NAME %in% lower_48) %>%
  rename(State =  STUSPS)

states_df <- left_join(states_df, plot_5_data)


### Graph

ggplot(states_df) +
  geom_sf(aes(fill = `Death Rate (%)`)) +
  scale_fill_viridis_c(name = "COVID-19 Death rate\n% of confirmed cases",
                       option = "inferno") +
  coord_sf(crs = st_crs(5070)) +
  theme_bw() +
  theme(legend.position = "bottom")



## END ##
