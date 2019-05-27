.PHONY: put get getpts log test

put:
	rsync -vrt --delete --exclude=.git \
	--exclude=data \
	--exclude=doc \
	--exclude=test \
	. /Volumes/Elder\ Scrolls\ Online/live/AddOns/HomeStationMarker


getpts:
	cp -f /Volumes/Elder\ Scrolls\ Online/pts/SavedVariables/HomeStationMarker.lua data/
	-cp -f /Volumes/Elder\ Scrolls\ Online/pts/SavedVariables/LibDebugLogger.lua data/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/HomeStationMarker.lua data/
	-cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/LibDebugLogger.lua data/

test:
	lua test/test_text.lua

log:
	lua tool/log_to_text.lua > data/log.txt
