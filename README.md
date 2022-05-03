# Select Individual Tracks by Space Use
# Choose Individuals Within A Selected Area 
# crop data to a selected area 
# selection of individuals that fall in a selected arae
# subset data to a user defined area

MoveApps

Github repository: *github.com/movestore/spatial-limit*

## Description
Select interactively the tracks of individuals that use area defined by the user.
select the individuals that fall within an area defined by the user

## Documentation
This highly interactive App allows the selection of (complete) tracks that pass through or use a defined area by point-clicking. Select either a rectangular area or a line-polygon. The tracks will not be "cut of", as the entire trajectories of the individuals will be selected (event though parts may fall outside the drawn polygon).

At selection of the option, the tracks can be pre-thinned. The resulting (set of) track(s) is transferred to the next App or can be downloaded as output .rds.

This app enables to subset the data based on a user defined area. The user can draw a rectangle/polygon/circle?, and all individuals that fall within the drawn area will be selected. The tracks will not be "cut of", as the entire trajectory of the individuals will be selected (event though parts may fall outside the drawn polygon).

### Input data
moveStack in Movebank format

### Output data
moveStack in Movebank format

### Artefacts
none.

### Parameters
`thinoption`: A thinning option from the drop down list can be selected, but can also be adapted in the UI afterwards (options: no thinning, 1 location/hour, 1 location/day).


### Null or error handling
**Data**: If no area is selected or no tracks fall within the selected area, the full data set it returned.
