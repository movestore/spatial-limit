library(shiny)
library(leaflet)
library(move)
library(shinycssloaders) ## for spinner while waiting


# library(sp)
# library(pals)
# library(mapview)
# library(raster)
# library(rgeos)
# library(lubridate)
# library(shinyWidgets)



shinyModuleUserInterface <- function(id, label, thinoption = "1hour") {
  ns <- NS(id)

  tagList(
    titlePanel("Choose individuals within a selected area"), ## change acording to readme
    # actionBttn(ns("select"),label = "Select chosen area",style = "fill",color = "danger"), ## maybe makes sense to add it, but not adding it for now, as not sure it would work automatically in a workflow
    radioButtons(ns("thinoption"), label="Thin data for faster visualization",choices=c("No thining" = "no","1 location/hour" = "1hour","1 location/day" = "1day"), selected="1day", inline=T),
    withSpinner(leafletOutput(ns("mymap"), height = "80vh"), type=5, size=1.5) #,color= "#28b78d"
    # verbatimTextOutput( ns("text")) # get list of leaflet event names input$...
  )
}

shinyModuleConfiguration <- function(id, input) {
  ns <- NS(id)
  configuration <- list()
  configuration
}

shinyModule <- function(input, output, session, data) {
  ns <- session$ns
  current <- reactiveVal()
  

  
}

