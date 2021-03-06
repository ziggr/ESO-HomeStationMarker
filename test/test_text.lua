package.path = package.path..";test/?.lua;lang/?.lua"
luaunit = require("luaunit")
hsm     = require("HomeStationMarker_Text")

TestText = {}

HomeStationMarker = HomeStationMarker or {}
function HomeStationMarker.Info(...) print(string.format(...)) end
function HomeStationMarker.Error(...) print(string.format(...)) end

-- Scaffolding to replace LibSets in this test environment
-- Copied right out of LibSets
LibSets = {}
LibSets.craftedSets = {
    [176]   = "Noble's Conquest"
,   [82]    = "Alessia's Bulwark"
,   [54]    = "Ashen Grip"
,   [323]   = "Assassin's Guile"
,   [87]    = "Eyes of Mara"
,   [51]    = "Night Mother's Gaze"
,   [324]   = "Daedric Trickery"
,   [161]   = "Twice-Born Star"
,   [73]    = "Oblivion's Foe"
,   [226]   = "Eternal Hunt"
,   [208]   = "Trial by Fire"
,   [207]   = "Law of Julianos"
,   [240]   = "Kvatch Gladiator"
,   [408]   = "Grave-Stake Collector"
,   [78]    = "Hist Bark"
,   [80]    = "Hunding's Rage"
,   [92]    = "Kagrenac's Hope"
,   [351]   = "Innate Axiom"
,   [325]   = "Shacklebreaker"
,   [386]   = "Sload's Semblance"
,   [44]    = "Vampire's Kiss"
,   [81]    = "Song of Lamae"
,   [410]   = "Might of the Lost Legion"
,   [48]    = "Magnus' Gift"
,   [353]   = "Mechanical Acuity"
,   [352]   = "Fortified Brass"
,   [219]   = "Morkuldin"
,   [409]   = "Naga Shaman"
,   [387]   = "Nocturnal's Favor"
,   [84]    = "Orgnum's Scales"
,   [242]   = "Pelinal's Aptitude"
,   [43]    = "Armor of the Seducer"
,   [178]   = "Armor Master"
,   [74]    = "Spectre's Eye"
,   [225]   = "Clever Alchemist"
,   [95]    = "Shalidor's Curse"
,   [40]    = "Night's Silence"
,   [224]   = "Tava's Favor"
,   [37]    = "Death's Wind"
,   [75]    = "Torug's Pact"
,   [177]   = "Redistributor"
,   [241]   = "Varen's Legacy"
,   [385]   = "Adept Rider"
,   [148]   = "Way of the Arena"
,   [79]    = "Willow's Path"
,   [41]    = "Whitestrake's Retribution"
,   [38]    = "Twilight's Embrace"
}
function LibSets.GetSetName(setId, lang)
    return LibSets.craftedSets[setId]
end
function LibSets.IsSetsScanning() return false end
function LibSets.AreSetsLoaded() return true end

local FODDER = {
    { "gibberish"           , nil }
--
,   {     "1"               , nil, 1 }
,   {     "2"               , nil, 2 }
,   {     "3"               , nil, 3 }
,   {     "4"               , nil, 4 }
,   {     "5"               , nil, 5 }
,   {     "6"               , nil, 6 }
,   {     "7"               , nil, 7 }
,   {     "al"              , nil, 4 }
,   {     "bs"              , nil, 1 }
,   {     "cl"              , nil, 2 }
,   {     "en"              , nil, 3 }
,   {     "jw"              , nil, 7 }
,   {     "pr"              , nil, 5 }
,   {     "ww"              , nil, 6 }
,   {     "AL"              , nil, 4 }
,   {     "BS"              , nil, 1 }
,   {     "CL"              , nil, 2 }
,   {     "EN"              , nil, 3 }
,   {     "JW"              , nil, 7 }
,   {     "PR"              , nil, 5 }
,   {     "WW"              , nil, 6 }
,   {     "alchemy"         , nil, 4 }
,   {     "alch"            , nil, 4 }
,   {     "al bundy"        , nil    }
,   {     "blacksmithing"   , nil, 1 }
,   {     "blacksmith"      , nil, 1 }
,   {     "black"           , nil, 1 }
,   {     "clothier"        , nil, 2 }
,   {     "cloth"           , nil, 2 }
,   {     "enchanting"      , nil, 3 }
,   {     "ench"            , nil, 3 }
,   {     "jewelrycrafting" , nil, 7 }
,   {     "jewelry"         , nil, 7 }
,   {     "jewel"           , nil, 7 }
,   {     "provisioning"    , nil, 5 }
,   {     "prov"            , nil, 5 }
,   {     "woodworking"     , nil, 6 }
,   {     "wood"            , nil, 6 }

,   { "82"                  , 82, nil }
,   { "82 1"                , 82, 1 }
,   { "82 bs"               , 82, 1 }
,   { "82 ww"               , 82, 6 }
--
,   { "Adept Rider"               , 385 , nil }
,   { "Alessia's Bulwark"         , 82  , nil }
,   { "Armor Master"              , 178 , nil }
,   { "Armor of the Seducer"      , 43  , nil }
,   { "Ashen Grip"                , 54  , nil }
,   { "Assassin's Guile"          , 323 , nil }
,   { "Clever Alchemist"          , 225 , nil }
,   { "Daedric Trickery"          , 324 , nil }
,   { "Death's Wind"              , 37  , nil }
,   { "Eternal Hunt"              , 226 , nil }
,   { "Eyes of Mara"              , 87  , nil }
,   { "Fortified Brass"           , 352 , nil }
,   { "Grave-Stake Collector"     , 408 , nil }
,   { "Hist Bark"                 , 78  , nil }
,   { "Hunding's Rage"            , 80  , nil }
,   { "Innate Axiom"              , 351 , nil }
,   { "Kagrenac's Hope"           , 92  , nil }
,   { "Kvatch Gladiator"          , 240 , nil }
,   { "Law of Julianos"           , 207 , nil }
,   { "Magnus' Gift"              , 48  , nil }
,   { "Mechanical Acuity"         , 353 , nil }
,   { "Might of the Lost Legion"  , 410 , nil }
,   { "Morkuldin"                 , 219 , nil }
,   { "Naga Shaman"               , 409 , nil }
,   { "Night Mother's Gaze"       , 51  , nil }
,   { "Night's Silence"           , 40  , nil }
,   { "Noble's Conquest"          , 176 , nil }
,   { "Nocturnal's Favor"         , 387 , nil }
,   { "Oblivion's Foe"            , 73  , nil }
,   { "Orgnum's Scales"           , 84  , nil }
,   { "Pelinal's Aptitude"        , 242 , nil }
,   { "Redistributor"             , 177 , nil }
,   { "Shacklebreaker"            , 325 , nil }
,   { "Shalidor's Curse"          , 95  , nil }
,   { "Sload's Semblance"         , 386 , nil }
,   { "Song of Lamae"             , 81  , nil }
,   { "Spectre's Eye"             , 74  , nil }
,   { "Tava's Favor"              , 224 , nil }
,   { "Torug's Pact"              , 75  , nil }
,   { "Trial by Fire"             , 208 , nil }
,   { "Twice-Born Star"           , 161 , nil }
,   { "Twilight's Embrace"        , 38  , nil }
,   { "Vampire's Kiss"            , 44  , nil }
,   { "Varen's Legacy"            , 241 , nil }
,   { "Way of the Arena"          , 148 , nil }
,   { "Whitestrake's Retribution" , 41  , nil }
,   { "Willow's Path"             , 79  , nil }
--]]
,   { "Adept Rider bs"            , 385 , 1 }
,   { "Alessia cloth"             , 82  , 2 }
,   { "clever alch"               , 225 , nil }
,   { "clever alch jw"            , 225 , 7 }
,   { "tbs ww"                    , 161 , 6 }
,   { "alessia's blacksmithing"   , 82  , 1 }
,   { "hist"                      , 78  , nil }
}


function TestText.TestLoop()
    for _, f in pairs(FODDER) do
        local fodder = { input      = f[1]
                       , set_id     = f[2]
                       , station_id = f[3]
                   }
        local got = HomeStationMarker.TextToStationSetIDs(fodder.input)
        local s   = "'"..tostring(fodder.input)..'"'
        if fodder.station_id or fodder.set_id then
            luaunit.assertNotNil(got,                               "returned table for "..s)
            luaunit.assertEquals(got.station_id, fodder.station_id, "station_id for "..s)
            luaunit.assertEquals(got.set_id,     fodder.set_id,     "set_id for "..s)
        else
            luaunit.assertNil(got, "returned table for "..s)
        end
    end
end


function TestText.TestExport41()

    local station_table = { [1] = { world_x = 1, world_y = 2, world_z = 11 }
                          , [2] = { world_x = 2, world_y = 2, world_z = 12 }
                          , [7] = { world_x = 3, world_y = 2, world_z = 13 }
                          , [6] = { world_x = 4, world_y = 2, world_z = 14 }
                          }
    local expect    = "123|1 2 11|0 0 0|1 0 1|2 0 2|3 0 3"
    local got_line  = HomeStationMarker.Export4(123, station_table)
    luaunit.assertEquals(got_line, expect, "123")

    local got_set_id, got_table = HomeStationMarker.Import4(got_line)
    luaunit.assertEquals(got_set_id, 123, "import 123")
    luaunit.assertEquals(got_table, station_table, "import 123")

    station_table       = { [1] = { world_x = 1, world_y = 2, world_z = 11 }
                          , [7] = { world_x = 3, world_y = 2, world_z = 13 }
                          , [6] = { world_x = 4, world_y = 2, world_z = 14 }
                          }
    expect      = "123|1 2 11|0 0 0||2 0 2|3 0 3"
    got_line    = HomeStationMarker.Export4(123, station_table)
    luaunit.assertEquals(got_line, expect, "123 no CL")


    local coord =  { world_x = 1, world_y = 2, world_z = 11 }
    got_line    = HomeStationMarker.Export1("no_set", 3, coord )
    expect      = "no_set:3|1 2 11"
    luaunit.assertEquals(got_line, expect, "Export1 3")

    local set_id, station_id, got_coord = HomeStationMarker.Import1(got_line)
    luaunit.assertEquals(set_id,     "no_set",  "Import 1 set_id")
    luaunit.assertEquals(station_id, "3",       "Import 1 station_id")
    luaunit.assertEquals(got_coord,  coord,     "Import 1 coord")

    local output = {}
    HomeStationMarker.ImportLine("123|1 2 11|0 0 0|1 0 1|2 0 2|3 0 3", output)
    luaunit.assertNotNil(output[123])
    luaunit.assertEquals(output[123][1], { world_x = 1, world_y = 2, world_z = 11 } )
    luaunit.assertEquals(output[123][2], { world_x = 2, world_y = 2, world_z = 12 } )
    luaunit.assertEquals(output[123][7], { world_x = 3, world_y = 2, world_z = 13 } )
    luaunit.assertEquals(output[123][6], { world_x = 4, world_y = 2, world_z = 14 } )

    HomeStationMarker.ImportLine("no_set:3|1 2 11", output)
    luaunit.assertNotNil(output["no_set"])
    luaunit.assertEquals(output["no_set"][3], { world_x = 1, world_y = 2, world_z= 11 })

    local station_location = {
        ["no_set"] = { [3] = { world_x = 1, world_y = 2, world_z = 11 }
                     , [4] = { world_x = 2, world_y = 2, world_z = 22 }
                     , [5] = { world_x = 3, world_y = 5, world_z = 33 } }
    }
    local expect_text = "no_set:3|1 2 11"
                   .. "\nno_set:4|2 2 22"
                   .. "\nno_set:5|3 5 33"
    local got_text = HomeStationMarker.ExportStations(station_location)
    luaunit.assertEquals(got_text, expect_text)

    station_location = {
        ["no_set"] = { [3] = { world_x = 1, world_y = 2, world_z = 11 }
                     , [4] = { world_x = 2, world_y = 2, world_z = 22 }
                     , [5] = { world_x = 3, world_y = 5, world_z = 33 } }
    ,   ["assistants"] = { ["banker"] = { world_x = 4, world_y = 5, world_z = 66 }
                     }
    , [123] =        { [1] = { world_x = 1, world_y = 2, world_z = 11 }
                     , [2] = { world_x = 2, world_y = 2, world_z = 12 }
                     , [7] = { world_x = 3, world_y = 2, world_z = 13 }
                     , [6] = { world_x = 4, world_y = 2, world_z = 14 }
                     }
    }
    local expect_text = ""
                   .. "123|1 2 11|0 0 0|1 0 1|2 0 2|3 0 3"
                   .. "\nassistants:banker|4 5 66"
                   .. "\nno_set:3|1 2 11"
                   .. "\nno_set:4|2 2 22"
                   .. "\nno_set:5|3 5 33"
    got_text = HomeStationMarker.ExportStations(station_location)
    luaunit.assertEquals(got_text, expect_text)

    local got_station_locations = HomeStationMarker.ImportStations(expect_text)
    luaunit.assertEquals(got_station_locations, station_location)
end



os.exit( luaunit.LuaUnit.run() )
