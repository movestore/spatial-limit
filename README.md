# Choose Individuals Within A Selected Area 
# crop data to a selected area 
# selection of individuals that fall in a selected arae
# subset data to a user defined area


MoveApps

Github repository: 

## Description
select the individuals that fall within an area defined by the user

## Documentation
This app enables to subset the data based on a user defined area. The user can draw a rectangle/polygon/circle?, and all individuals that fall within the drawn area will be selected. The tracks will not be "cut of", as the entire trajectory of the individuals will be selected (event though parts may fall outside the drawn polygon).


### Input data
moveStack in Movebank format

### Output data
moveStack in Movebank format

### Artefacts


### Parameters
`Select attribute`: one attribute from the drop down list can be selected. All available attributes associated to the locations of the study are displayed.


### Null or error handling
**Data**: For use in further Apps the input data set is returned unmodified. Empty input will give an error.
