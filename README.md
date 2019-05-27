# Home Station Marker

An add-on for Elder Scrolls Online that draws 3D markers over crafting stations in a player home.

Adapted from [Shinni's HarvestMap](https://www.esoui.com/downloads/info57-HarvestMap.html) and [Marify's Confirm Master Writ](https://www.esoui.com/downloads/info57-HarvestMap.html).

Learns station locations as you visit them. Also scans current house for all stations, but only if you own or have decorator privileges for current house.

Hides a house's markers when you exit that house, shows them again when you re-enter.

Originally written to help visitors find stations when crafting master writs with [WritWorthy](https://www.esoui.com/downloads/info1605-WritWorthy.html).

## Slash Commands

### `/hsm <station> <set>`
Toggle a marker above the given station. Can omit either argument.

- `/hsm alchemy` toggles a marker over an alchemy station
- `/hsm alessia's blacksmithing` toggles a marker over the Alessia's Bulwark blacksmithing station
- `/hsm hist` toggles a marker over a random Hist Bark station

This is mostly for testing/debugging this add-on. The simplistic string matching here only works for EN English clients.

Requires [Baertram's LibSets](https://www.esoui.com/downloads/info2241-LibSets.html)

#### Crafting station abbreviations

Nobody wants to type "Jewelry Crafting Station".

- two-letters: bs, cl, ww, jw, al, en, pr, tr (transmute)
- first few letters: black, cloth, wood, jewel

#### Set abbreviations

- first few letters: alessia, twice-born, eternal

Uppercase and punctuation ignored.

### `/hsm clear`

Deletes all markers.

### `/hsm forget [all]`

Forget all station locations for current house, or all houses if `/hsm forget all`. Use `/hsm forget` in a house after moving any crafting stations. Deletes all markers in current house (or all houses if `/hsm forget all`) as a necessary side effect.

# Not Supported

I might add these later:
- Mundus stones
- Assistants: Banker, Merchant, Fence

Custom markers? No thank you. That's an additional API and complexity that I don't want to spend my days supporting.


# FPS Cost

Each marker slows down your frames per second.

`zo_callLater` : a periodic task updates each marker rotation 4 times per second. Only registered within player houseing, and only if you have one or more shown markers.

`EVENT_END_CRAFTING_STATION_INTERACT` : An event listener records station location each time you exit a crafting station interaction. This listener is only registered within player housing.

`EVENT_PLAYER_ACTIVATED` : An event listener hides all of a house's markers when you exit player housing, shows that house's previously hidden markers when you enter player housing.

# SavedVariables

- **station locations:** for each player house: each known crafting station's location
- **marker locations:** for each player house: each marker location

# API

```
HomeStationMarker.AddMarker(setId, stationId)

HomeStationMarker.DeleteMarker(setId, stationId)

HomeStationMarker.DeleteAllMarkers()

```
