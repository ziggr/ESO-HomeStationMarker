.PHONY: put getpts get test log clayget deg zip doc

put:
	rsync -vrt --delete --exclude=.git \
	--exclude=data \
	--exclude=doc \
	--exclude=test \
	--exclude=trig \
	--exclude=published \
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

clayget:
	lua trig/clayget.lua

deg:
	lua trig/trig.lua

zip:
	-rm -rf published/HomeStationMarker published/HomeStationMarker\ x.x.x.zip
	mkdir -p published/HomeStationMarker
	cp    ./HomeStationMarker* published/HomeStationMarker/
	cp -r ./lang               published/HomeStationMarker/

	cd published; zip -r HomeStationMarker\ x.x.x.zip HomeStationMarker

	rm -rf published/HomeStationMarker

doc:
	tool/2bbcode_phpbb  <README.md >/tmp/hsmdoc
	sed sSdoc/hsm_stations_marked.jpgShttps://cdn-eso.mmoui.com/preview/pvw8154.jpgS /tmp/hsmdoc >doc/README.bbcode
