package.path = package.path..";test/?.lua;lang/?.lua"
luaunit = require("luaunit")
hsm     = require("HomeStationMarker_Text")

TestText = {}

-- Scaffolding to replace LibSets in this test environment
-- Copied right out of LibSets.
LibSets = {}
LibSets.craftedSets = {
    [176]   = true,     --Adelssieg / Noble's Conquest
    [82]    = true,     --Alessias Bollwerk / Alessia's Bulwark
    [54]    = true,     --Aschengriff / Ashen Grip
    [323]   = true,     --Assassinenlist / Assassin's Guile
    [87]    = true,     --Augen von Mara / Eyes of Mara
    [51]    = true,     --Blick der Mutter der Nacht / Night Mother's Gaze
    [324]   = true,     --Daedrische Gaunerei / Daedric Trickery
    [161]   = true,     --Doppelstern / Twice-Born Star
    [73]    = true,     --Erinnerung / Oblivion's Foe
    [226]   = true,     --Ewige Jagd / Eternal Hunt
    [208]   = true,     --Feuertaufe / Trial by Fire
    [207]   = true,     --Gesetz von Julianos / LAw of Julianos
    [240]   = true,     --Gladiator von Kvatch / Kvatch Gladiator
    [408]   = true,     --Grabpflocksammler / Grave-Stake Collector
    [78]    = true,     --Histrinde / Hist Bark
    [80]    = true,     --Hundings Zorn / Hunding's Rage
    [92]    = true,     --Kagrenacs Hoffnung / Kagrenac's Hope
    [351]   = true,     --Kernaxiom / Innate Axiom
    [325]   = true,     --Kettensprenger / Shacklebreaker
    [386]   = true,     --Kreckenantlitz / Sload's Semblance
    [44]    = true,     --Kuss des Vampirs / Vampire's Kiss
    [81]    = true,     --Lied der Lamien / Song of Lamae
    [410]   = true,     --Macht der verlorenen Legion / Might of the Lost Legion
    [48]    = true,     --Magnus' Gabe / Magnu's Gift
    [353]   = true,     --Mechanikblick / Mechanical Acuity
    [352]   = true,     --Messingpanzer / Fortified Brass
    [219]   = true,     --Morkuldin / Morkuldin
    [409]   = true,     --Nagaschamane / Naga Shaman
    [387]   = true,     --Nocturnals Gunst / Nocturnal's Favor
    [84]    = true,     --Orgnums Schuppen / Orgnum's Scales
    [242]   = true,     --Pelinals Talent / Pelinal's Aptitude
    [43]    = true,     --Rüstung der Verführung / Armor of the Seducer
    [178]   = true,     --Rüstungsmeister / Armor Master
    [74]    = true,     --Schemenauge / Spectre's Eye
    [225]   = true,     --Schlauer Alchemist / Clever Alchemist
    [95]    = true,     --Shalidors Fluch / Shalidor's Curse
    [40]    = true,     --Stille der Nacht / Night's Silence
    [224]   = true,     --Tavas Gunst / Tava's Favor
    [37]    = true,     --Todeswind / Death's Wind
    [75]    = true,     --Torugs Pakt / Torug's Pact
    [177]   = true,     --Umverteilung / Redistributor
    [241]   = true,     --Varens Erbe / Varen's Legacy
    [385]   = true,     --Versierter Reiter / Adept Rider
    [148]   = true,     --Weg der Arnea / Way of the Arena
    [79]    = true,     --Weidenpfad / Willow's Path
    [41]    = true,     --Weißplankes Vergeltung / Whitestrake's Retribution
    [38]    = true,     --Zwielichtkuss / Twilight's Embrace
}


local FODDER = {
    { "gibberish"           , nil }
,   {     "1"               , nil, 1 }
,   {     "2"               , nil, 2 }
,   {     "3"               , nil, 3 }
,   {     "4"               , nil, 4 }
,   {     "5"               , nil, 5 }
,   {     "6"               , nil, 6 }
,   {     "7"               , nil, 7 }
,   { "82"                  , 82, nil }
,   { "82 1"                , 82, 1 }
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



os.exit( luaunit.LuaUnit.run() )
