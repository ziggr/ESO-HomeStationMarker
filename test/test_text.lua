package.path = package.path..";test/?.lua;lang/?.lua"
luaunit = require("luaunit")
hsm     = require("HomeStationMarker_Text")

TestText = {}


local FODDER = {
    { "gibberish", nil }
,   { "1 1", 1, 1 }
}

function TestText.TestLoop()
    for _, f in pairs(FODDER) do
        local fodder = { input      = f[1]
                       , station_id = f[2]
                       , set_id     = f[3]
                   }
        local got = HomeStationMarker.TextToStationSetIDs(fodder.input)
        local s   = "'"..tostring(fodder.input)..'"'
        if fodder.station_id or fodder.set_id then
            luaunit.assertNotNil(got,                               "returned table for "..s)
            luaunit.assertEquals(got.station_id, fodder.station_id, "station_id for "..s)
            luaunit.assertEquals(got.set_id,     fodder.station_id, "set_id for "..s)
        else
            luaunit.assertNil(got, "returned table for "..s)
        end
    end
end



os.exit( luaunit.LuaUnit.run() )
