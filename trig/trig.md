# Trig: angle and radius calculations

Using the player position for 3D MarkControl is incorrect: that places the MarkControl in front of the crafting station. This is particularly odd for blacksmith stations that tend to be rotated to random angles since the blacksmithing station's 3D model lacks the obvious front that clothing/woodworking/jewelry all have.

So dump out a record of the housing editor's xyz+orientation values for each of the crafting stations that I'm working on, compare that to the player's xyz+orientation at that station, and math it out to find a useful transformation.

There might be spreadsheets involved.

