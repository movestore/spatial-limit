
## script can maybe be recycled if someone takes over leaflet.extra

library(shiny)
library(shinyWidgets)
library(leaflet)
library(leaflet.extras) #!!! not maintained anymore
library(move)
library(sp)
library(pals)
library(mapview)
library(raster)
library(rgeos)
library(lubridate)
library(shinycssloaders) ## for spinner while waiting

shinyModuleUserInterface <- function(id, label) {
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
  
  
  #### storing the values clicked on the map while drawing the polygon  ####
  data_of_click <- reactiveValues(clickedMarker = list())

  ### creating leaflet map  ####
  output$mymap <- renderLeaflet({
    ## if option "no thining" is selected, than nothing happens
    if(input$thinoption=="no"){mv <- data}
    ## if option "1 location/hour" is selected the trajectory gets thinned to aprox. one location per hour
    if(input$thinoption=="1hour"){mv <- data[!duplicated(paste0(round_date(timestamps(data), "1 hour"), trackId(data))),]}
    ## if option "1 location/day" is selected the trajectory gets thinned to aprox. one location per day
    if(input$thinoption=="1day"){mv <- data[!duplicated(paste0(round_date(timestamps(data), "1 day"), trackId(data))),]}
    ## the moveStack is split into a list of move objects for easier mapping
    mvL <- move::split(mv)

    #### the leaflet plot with all individulas. When you hover over a specific individual, this one will be highlighted. On the side bar shapes to select an are cn be chosen
    cols <- colorFactor(turbo(n.indiv(mv)), domain=namesIndiv(mv))
    map1 <- leaflet(mv) %>% addTiles()
    for(i in mvL){
      map1 <- map1 %>% 
        addCircleMarkers(lng = coordinates(i)[,1],lat = coordinates(i)[,2], fillOpacity = 0.5, opacity = 0.7, radius=1,color="black")%>%
        addPolylines(lng = coordinates(i)[,1],lat = coordinates(i)[,2],color=~cols(namesIndiv(i)),weight=5, opacity=0.7, layerId=namesIndiv(i),group =namesIndiv(i),popup=namesIndiv(i),highlightOptions = highlightOptions(color = "red",opacity = 1,weight = 2, bringToFront = TRUE))
    }
    map1  %>%
      addScaleBar(position="bottomleft",options=scaleBarOptions(maxWidth = 100, metric = TRUE, imperial = F, updateWhenIdle = TRUE))  %>%
      addDrawToolbar(
      targetGroup='Selected',
      polylineOptions=FALSE,
      markerOptions = FALSE,
      polygonOptions = drawPolygonOptions(shapeOptions=drawShapeOptions(fillOpacity = 0,color = 'white',weight = 4)),
      rectangleOptions = drawRectangleOptions(shapeOptions=drawShapeOptions(fillOpacity = 0,color = 'red',weight = 4)),
      # circleOptions = drawCircleOptions(shapeOptions = drawShapeOptions(fillOpacity = 0,color = 'grey',weight = 4)), ## maybe add later on, to extract coordinates of the circle need a bit more coding
      # circleOptions=T,
      # circleMarkerOptions=FALSE,
      # editOptions = editToolbarOptions(edit = FALSE, selectedPathOptions = selectedPathOptions())
      editOptions = editToolbarOptions(edit = T,remove=T, selectedPathOptions = NULL)
      )
  })

  #### the inteaction with the map, selecting an area and highlighting the selected individuals ####
  observeEvent(input$mymap_draw_new_feature,{
    ## getting the draw polygon on the map
    feature <- input$mymap_draw_new_feature
    ## extracting the coordinates
    polygon_coordinates <- feature$geometry$coordinates
    ## using these coordinates to make a SpatialPolygon object that is needed for further operations.
    drawn_polygon <- sp::Polygon(do.call(rbind, lapply(polygon_coordinates[[1]],function(x){
      c(x[[1]][1], x[[2]][1])
    })))
    spol <- sp::SpatialPolygons(list(sp::Polygons(list(drawn_polygon),"drawn_polygon")))
    projection(spol) <- projection(data)
    selectPoly <- reactive({spol})
    ## cookie cutting the track with the polygon
    sub <- crop(data, selectPoly())
    if(is.null(sub)){
      logger.error("NO tracks found in selected area. NO data will be passed on to the next app.")
      current(NULL)
      }else{
    ## extracting the names of the individuals that fall in this area
    subIDs <- namesIndiv(sub)
    ### creating an reactive object with the selected individuals. This is the object for the output of this app
    current(moveStack(data[[subIDs]],forceTz="UTC"))
    # current <- reactive({
    #   moveStack(data[[subIDs]],forceTz="UTC")
    # })

    ## preparing the selected data to plot the in a different color and make them visible as selected on the map
    mp <- current()
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
   
      }
  })

  #### the inteaction with the map, when I want to cancel my selection, the highlighted individuals and the polygon gets removed ####
  # https://stackoverflow.com/questions/44979900/how-to-download-polygons-drawn-in-leaflet-draw-as-geojson-file-from-r-shiny
  ## see link to handle $mymap_draw_edited_features 
  
  observeEvent(input$mymap_draw_deleted_features,{
    # loop through list of one or more deleted features/ polygons
    for(feature in input$mymap_draw_deleted_features$features){
      # extracting coordinates and building polygon, and electing individuals within this polygon. Exacly the same as above, for some reason it does not work to take the intective object from above
      polygon_coordinates <- feature$geometry$coordinates
      drawn_polygon <- sp::Polygon(do.call(rbind, lapply(polygon_coordinates[[1]],function(x){
        c(x[[1]][1], x[[2]][1])
      })))
      spol <- sp::SpatialPolygons(list(sp::Polygons(list(drawn_polygon),"drawn_polygon")))
      projection(spol) <- projection(data)
      sub <- crop(data, spol)
     
      if(is.null(sub)){
        logger.error("NO tracks found in selected area. NO data will be passed on to the next app.")
        current(NULL) # reactive({NULL})
      }else{
      subIDs <- namesIndiv(sub)
      selectI <- data[[subIDs]]


      ## getting the leaflet map, and removing the selected individuals
      proxy <- leafletProxy("mymap")
      proxy %>% removeShape(layerId = paste0(namesIndiv(selectI),"_sel"))
      ## removing the polygon
      first_layer_ids <-paste0(namesIndiv(selectI),"_sel")
      data_of_click$clickedMarker <- data_of_click$clickedMarker[!data_of_click$clickedMarker %in% first_layer_ids]

      current(moveStack(data[[subIDs]],forceTz="UTC"))
    # current <- reactive({
    #   moveStack(data[[subIDs]],forceTz="UTC")
    # })
    
      }
    }
  })
  # print list of input events
  # output$text <- renderPrint({reactiveValuesToList(input)})  # get list of leaflet event names input$...
  
  
  # observeEvent(input$select, {
  # if(is.null(currentSelec)){
    return(reactive({ current() }))
  # }else{
    # return(reactive({ currentSelec() }))
  # }
  # })
  
  
}

