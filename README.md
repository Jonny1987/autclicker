# autclicker
### Autoclicker for linux

Command line based tool for automatic mouse clicks.

### Works as follows:
The mouse will click the chosen locations repeatedly with a customisable delay between each cycle.
The click locations can be separated into groups, and the user can add a new click location to a particular group, 
or change all the locations in a group.

Each cycle, the number of cycles left in each group is recalculated and printed to the terminal and a countdown
until the next cycle starts is shown.

### To set the click locations and number of repetitions in each group :
`python autclick.py -g A B C -r X Y Z`

where

* A, B, C are the number of clicks in groups 1, 2, 3 respectively
* X, Y, Z are the repetitions (number of cycles) in those groups

### To set the delay between cycles:
`python autclick.py -d 3`
(to set a 3 second time delay)

decimal numbers with 1 decimal place can also be used

### To add a click to a group:

`python autclicker.py -a G P N`

where

* G is the number of the group (zero indexed)
* P is the position the click should be added (zero indexed) (eg 2 would mean the new clicks would start at the 3rd click in the sequence for that group)
* N is the number of clicks to add

The locations of the new clicks are then indicated by clicking on the screen N times

### To change the clicks in a group:
This will remove all existing clicks and replace them with new ones.

`python autclicker.py -cg G N`

where

* G is the number of the group (zero indexed)
* N is the number of clicks to add

The locations of the new clicks are then indicated by clicking on the screen N times

### To change the cycles in a group:
This will remove all existing clicks and replace them with new ones.

`python autclicker.py -cr G N`

where

* G is the number of the group (zero indexed)
* N is the new number of cycles for that group

