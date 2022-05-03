library(shiny)
library(shinycssloaders) ## for spinner while waiting
library(move)
library(lubridate)

library(raster)

####
data <- readRDS("threeindv.rds")
#####

## IDEA ##
# - use a basemap and or polygon for orientation, maybe with country, region lable
# - make it possible to zoom in, in case much smaller area wants to be selected
# - make it possible to draw a polygon, which is than used to select the tracks, or crop the data (in this case provide a good warning message of "are you sure this is what you want to do")


# Define UI ----
ui <- fluidPage(

    tagList(
    titlePanel("Choose individuals within a selected area"), ## change acording to readme
    # actionBttn(ns("select"),label = "Select chosen area",style = "fill",color = "danger"), ## maybe makes sense to add it, but not adding it for now, as not sure it would work automatically in a workflow
    radioButtons("thinoption", label="Thin data for faster visualization",choices=c("No thining" = "no","1 location/hour" = "1hour","1 location/day" = "1day"), selected="1day", inline=T),
    withSpinner(plotOutput("mymap", height = "80vh"), type=5, size=1.5) #,color= "#28b78d"
    # verbatimTextOutput( ns("text")) # get list of leaflet event names input$...
  )

)

# Define server logic ----
server <- function(input, output) {
  current <- reactiveVal()


  #### storing the values clicked on the map while drawing the polygon  ####
  # data_of_click <- reactiveValues(clickedMarker = list())

  ### creating leaflet map  ####
  output$mymap <- renderPlot({
    ## if option "no thining" is selected, than nothing happens
    if(input$thinoption=="no"){mv <- data}
    ## if option "1 location/hour" is selected the trajectory gets thinned to aprox. one location per hour
    if(input$thinoption=="1hour"){mv <- data[!duplicated(paste0(round_date(timestamps(data), "1 hour"), trackId(data))),]}
    ## if option "1 location/day" is selected the trajectory gets thinned to aprox. one location per day
    if(input$thinoption=="1day"){mv <- data[!duplicated(paste0(round_date(timestamps(data), "1 day"), trackId(data))),]}
    ## the moveStack is split into a list of move objects for easier mapping
    # mvL <- move::split(mv)

    # basemap <- stack("basemap/NE1_HR_LC_SR_W_DR/NE1_HR_LC_SR_W_DR.tif")
    basemap <- stack("basemap/HYP_HR_SR_OB_DR/HYP_HR_SR_OB_DR.tif")
  basemap_cr <- crop(basemap, extent(mv)*2)
  plotRGB(basemap_cr)
  
  basepoly <- readOGR("basemap/ne_10m_admin_0_countries/","ne_10m_admin_0_countries")
  # basepoly <- readOGR("basemap/ne_10m_geography_marine_polys/","ne_10m_geography_marine_polys")
  plot(basepoly, add=T)
  library(maptools)
  pointLabel(coordinates(basepoly),labels=basepoly$NAME)
  # pointLabel(coordinates(basepoly[basepoly$featurecla %in% c("ocean","sea"),]),labels=basepoly$name, cex=.1)
  
  unique(basepoly$featurecla)
  
})

}

# # Run the app ----
shinyApp(ui = ui, server = server)



