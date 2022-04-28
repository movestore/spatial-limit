# Select Tracks by Space Use
MoveApps

Github repository: *github.com/movestore/spatial-limit*

## Description
Select interactively the tracks of individuals that use area defined by the user.

## Documentation
This highly interactive App allows the selection of (complete) tracks that pass through or use a defined area by point-clicking. Select either a rectangular area or a line-polygon. The tracks will not be "cut of", as the entire trajectories of the individuals will be selected (event though parts may fall outside the drawn polygon).

At selection of the option, the tracks can be pre-thinned. The resulting (set of) track(s) is transferred to the next App or can be downloaded as output .rds.


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
