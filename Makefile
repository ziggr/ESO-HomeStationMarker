.PHONY: put

put:
	rsync -vrt --delete --exclude=.git \
	--exclude=data \
	--exclude=doc \
	. /Volumes/Elder\ Scrolls\ Online/live/AddOns/HomeStationMarker


getpts:
	cp -f /Volumes/Elder\ Scrolls\ Online/pts/SavedVariables/HomeStationMarker.lua data/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/HomeStationMarker.lua data/
