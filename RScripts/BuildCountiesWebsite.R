# This script uses relative paths !!!
# Make sure your working directory is set to location of this source file

library(readr)
library(dplyr)

# reference to data and html dirs and extension value
datadir <- "../data"
htmldir <- "../tmp"
ext     <- ".html"

# reference to the county pages template
template  <- "../RMarkdown/Template.Rmd"

# reference to the Home page template
home  <- "../RMarkdown/Home.Rmd"

# constant 100,000
multiplier <- 100000

# create the data directory if it doesn't exist
if (!file.exists(datadir)){
  dir.create(datadir)
}

# create the html directory if it doesn't exist
if (!file.exists(htmldir)){
  dir.create(htmldir)
}

# get the data
covid <- read_csv("https://data.ct.gov/resource/bfnu-rgqt.csv")
pops <- read_csv("../data/populations.csv", skip=2)

# make sure data is in the right order
covid <- covid %>% arrange(dateupdated)

# create a list so we can refer to population data by name
popList <- setNames(as.list(pops$population), pops$county)

# function to append column with normalized covid data based on county population
appendPer100 <- function(df, values, newCol){
  for (i in 1:nrow(df)) {
    df$per100[i] <- (values[i]/popList[[df$county[i]]])*multiplier
  }
  df$per100 <- round(df$per100, 3)
  colnames(df)[length(df)] <- newCol
  return(df)
}

covid <- appendPer100(covid, covid$totalcases, newCol = "CasesPer100K" )
covid <- appendPer100(covid, covid$totaldeaths, newCol = "DeathsPer100K" )
covid <- appendPer100(covid, covid$hospitalization, newCol = "HospitalizationPer100K" )

# save data in a file
save(covid, file = paste(datadir, "/covid.RData", sep = ""))

# build the home page file name and path
homepage <- paste(htmldir, "/", "Home", ext, sep="")

# build the Home page
rmarkdown::render(home, output_file = homepage)

# get distinct counties
counties <- unique(covid$county)

# build the county pages
for (i in counties) {

  # build the file name and path
  htmlfile <- paste(htmldir, "/", i, ext, sep="")
  
  #print(htmlfile)
  
  # render the document
  rmarkdown::render(template, output_file = htmlfile, params = list(data = i))
}


