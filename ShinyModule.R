library(leaflet)
library(leaflet.extras)
library(move)
library(sp)
library(pals)
library(mapview)
library(raster)
library(rgeos)
library(lubridate)

shinyModuleUserInterface <- function(id, label, thinoption = "1hour") {
  ns <- NS(id)

  tagList(
    titlePanel("Choose individuals within the selected area"),
    radioButtons(ns("thinoption"), label="Thin data for faster visualization",choices=c("No thining" = "no","1 location/hour" = "1hour","1 location/day" = "1day"), selected=thinoption, inline=T),
    leafletOutput(ns("mymap"))
  )
}

shinyModuleConfiguration <- function(id, input) {
  ns <- NS(id)

  configuration <- list()

  print(ns('thinoption'))

  configuration["thinoption"] <- input[[ns('thinoption')]]

  configuration
}

shinyModule <- function(input, output, session, data, thinoption = "1hour") {
  #### interactive object to read in .RData file  ####
  mvObj <- reactive({ data })
  current <- reactiveVal(data)

  #### storing the values clicked on the map while drawing the polygon  ####
  data_of_click <- reactiveValues(clickedMarker = list())

  #### creating leaflet map  ####
  output$mymap <- renderLeaflet({
    #### making new object for simplicity, and preparing the data for the plot
    m <- mvObj()
    if(!class(m)=="MoveStack"){stop("It seems you are only working with one individual. This App is intended for sevelal individuals. Single individuals cannot be used in this function.")}
    ## if option "no thining" is selected, than nothing happens
    if(input$thinoption=="no"){mv <- m}
    ## if option "1 location/hour" is selected the trajectory gets thinned to aprox. one location per hour
    if(input$thinoption=="1hour"){mv <- m[!duplicated(paste0(round_date(timestamps(m), "1 hour"), trackId(m))),]}
    ## if option "1 location/day" is selected the trajectory gets thinned to aprox. one location per day
    if(input$thinoption=="1day"){mv <- m[!duplicated(paste0(round_date(timestamps(m), "1 day"), trackId(m))),]}
    ## the moveStack is split into a list of move objects for easier mapping
    mvL <- move::split(mv)

    #### the leaflet plot with all individulas. When you hover over a specific individual, this one will be highlighted. On the side bar shapes to select an are cn be chosen
    cols <- colorFactor(brewer.spectral(n.indiv(mv)), domain=namesIndiv(mv))
    map1 <- leaflet(mv) %>% addTiles()
    for(i in mvL){
      map1 <- addPolylines(map1, lng = coordinates(i)[,1],lat = coordinates(i)[,2],color=~cols(namesIndiv(i)),weight=5, opacity=0.7, layerId=namesIndiv(i), highlightOptions = highlightOptions(color = "red",opacity = 1,weight = 2, bringToFront = TRUE))
    }
    map1  %>%
      addScaleBar(position="bottomleft",options=scaleBarOptions(maxWidth = 100, metric = TRUE, imperial = F, updateWhenIdle = TRUE))  %>%
      addDrawToolbar(
      targetGroup='Selected',
      polylineOptions=FALSE,
      markerOptions = FALSE,
      polygonOptions = drawPolygonOptions(shapeOptions=drawShapeOptions(fillOpacity = 0,color = 'white',weight = 4)),
      rectangleOptions = drawRectangleOptions(shapeOptions=drawShapeOptions(fillOpacity = 0,color = 'white',weight = 4)),
      # circleOptions = drawCircleOptions(shapeOptions = drawShapeOptions(fillOpacity = 0,color = 'white',weight = 4)),
      circleOptions=FALSE,
      circleMarkerOptions=FALSE,
      editOptions = editToolbarOptions(edit = FALSE, selectedPathOptions = selectedPathOptions()))
  })

  #### the inteaction with the map, selecting an area and highlighting the selected individuals ####
  observeEvent(input$mymap_draw_new_feature,{
    ## getting the draw polygon on the map
    feature <- input$mymap_draw_new_feature
    ## extracting the coordinates
    polygon_coordinates <- feature$geometry$coordinates
    ## using these coorinates to make a SpatialPolygon object that is needed for further operations.
    drawn_polygon <- sp::Polygon(do.call(rbind, lapply(polygon_coordinates[[1]],function(x){
      c(x[[1]][1], x[[2]][1])
    })))
    spol <- sp::SpatialPolygons(list(sp::Polygons(list(drawn_polygon),"drawn_polygon")))
    projection(spol) <- projection(mvObj())
    selectPoly <- reactive({spol}) ## I think this is the object that should be saved, as the input of individuals could change
    ## cookie cutting the track with the polygon
    sub <- crop(mvObj(), selectPoly())
    ## extracting the names of the individuals that fall in this area
    subIDs <- namesIndiv(sub)
    ### creating an reactive object with the selected individuals. This is the object for the output of this app
    selectR <- reactive({
      mvObj()[[subIDs]]
    })

    ## preparing the selected data to plot the in a different color and make them visible as selected on the map
    mp <- selectR()
    if(input$thinoption=="no"){ selectRPl <- mp}
    if(input$thinoption=="1hour"){selectRPl <- mp[!duplicated(paste0(round_date(timestamps(mp), "1 hour"), trackId(mp))),]}
    if(input$thinoption=="1day"){selectRPl <- mp[!duplicated(paste0(round_date(timestamps(mp), "1 day"), trackId(mp))),]}
    ## getting the leaflet map created above, and adding the selected individuals on the map
    proxy <- leafletProxy("mymap")
    spL <- split(selectRPl)
    for(i in spL){
      proxy <- addPolylines(proxy,data=i, lng = coordinates(i)[,1],lat = coordinates(i)[,2],color="black",weight=5, opacity=0.7, layerId=paste0(namesIndiv(i),"_sel"), highlightOptions = highlightOptions(color = "gold",opacity = 1,weight = 2, bringToFront = TRUE))
    }
    proxy

    current(mvObj()[[subIDs]])
  })

  #### the inteaction with the map, when I want to cancel my selection, the highlighted individuals and the polygon gets removed ####
  observeEvent(input$mymap_draw_deleted_features,{
    # loop through list of one or more deleted features/ polygons
    for(feature in input$mymap_draw_deleted_features$features){
      # extracting coordinates and building polygon, and electing individuals within this polygon. Exacly the same as above, for some reason it does not work to take the intective object from above
      polygon_coordinates <- feature$geometry$coordinates
      drawn_polygon <- sp::Polygon(do.call(rbind, lapply(polygon_coordinates[[1]],function(x){
        c(x[[1]][1], x[[2]][1])
      })))
      spol <- sp::SpatialPolygons(list(sp::Polygons(list(drawn_polygon),"drawn_polygon")))
      projection(spol) <- projection(mvObj())
      sub <- crop(mvObj(), spol)
      subIDs <- namesIndiv(sub)
      selectI <- mvObj()[[subIDs]]


      ## getting the leaflet map, and removing the selected individuals
      proxy <- leafletProxy("mymap")
      proxy %>% removeShape(layerId = paste0(namesIndiv(selectI),"_sel"))
      ## removing the polygon
      first_layer_ids <-paste0(namesIndiv(selectI),"_sel")
      data_of_click$clickedMarker <- data_of_click$clickedMarker[!data_of_click$clickedMarker %in% first_layer_ids]
    }

    current(mvObj()[[subIDs]])
  })

  return(reactive({ current() }))
}

