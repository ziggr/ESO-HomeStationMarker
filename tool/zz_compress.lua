dofile("data/HomeStationMarker.lua")
dofile("HomeStationMarker_Text.lua")

ORIGINAL = HomeStationMarkerVars["Default"]["@ziggr"]["$AccountWide"]["station_location"]["46\t@ziggr"]

-- From http://lua-users.org/wiki/SplitJoin
function split(str,sep)
    local sep = sep or "\t"
    local ret={}
    local n=1
    for w in str:gmatch("([^"..sep.."]*)") do
        ret[n] = ret[n] or w -- only set once (so the blank after a string is ignored)
        if w=="" then
            n = n + 1
        end -- step forwards on a blank but not a string
    end
    return ret
end

function splitt(str)
    local t1 = string.find(str, '\t')
    local t2 = string.find(str, '\t', 1 + t1)
    local t3 = string.find(str, '\t', 1 + t2)
    local t4 = string.find(str, '\t', 1 + t3)
    local t5 = string.find(str, '\t', 1 + t4) or #str
    return { string.sub(str, 1     , t1 - 1)
           , string.sub(str, 1 + t1, t2 - 1)
           , string.sub(str, 1 + t2, t3 - 1)
           , string.sub(str, 1 + t3, t4 - 1)
           , string.sub(str, 1 + t4, t5 - 1)
           }
end

function FromStationLocationString(s)
    assert(s)
    assert(s ~= "")
    local w = splitt(s, "\t")

-- print(string.format("line:'%s'\n", s))
-- for i,s in ipairs(w) do
-- print(string.format(" %d:'%s'\n", i, tostring(s)))
-- end

    assert(3 <= #w)
    local r = { world_x     = tonumber(w[1])
              , world_y     = tonumber(w[2])
              , world_z     = tonumber(w[3])
              , orientation = tonumber(w[4])
              , provenance  = tonumber(w[5]) or -1
              }
    assert(r.world_x and r.world_y and r.world_z)
    return r
end

function ta(tbl, fmt, arg)
    assert(arg)
    local s = string.format(fmt, arg)
    table.insert(tbl, s)
end

function rad2deg(rad)
                        -- To degrees
    local deg = rad * 180 / math.pi

                        -- Positive, want [0..360]
    while deg < 0 do
        deg = deg + 360
    end

                        -- Rounded to nearest 10-degree
    deg = 10 * math.floor(0.5 + deg / 10)
    return deg
end

function ToLine(set_id, stations)
    if type(set_id) ~= "number" then return nil end

    local out = {}
    ta(out, "%3d", set_id)

    for _, i in ipairs({1,2,6,7}) do
        local tabbed = stations[i]
        local r      = FromStationLocationString(tabbed)

        ta(out, "%5d", r.world_x)
        ta(out, "%5d", r.world_y)
        ta(out, "%5d", r.world_z)
        ta(out, "%3d", rad2deg(r.orientation))
    end
    return table.concat(out, "")
end

function ReadSet(set_id, stations)
    if type(set_id) ~= "number" then return nil end
    local out = {}

    for _, i in ipairs({1,2,6,7}) do
        local tabbed = stations[i]
        local r      = FromStationLocationString(tabbed)
        out[i] = r
    end
    return out
end

-- READ FILE
DATA = {}
for set_id, stations in pairs(ORIGINAL) do
    DATA[set_id] = ReadSet(set_id, stations)
end

-- SCAN for minimums, accumulate list of set_ids
SET_ID = {}
HUGE   = 1000000
MIN    = { world_x = HUGE
         , world_y = HUGE
         , world_z = HUGE
         }
for set_id, stations in pairs(DATA) do
    table.insert(SET_ID, set_id)
    for i,station in pairs(stations) do
        MIN.world_x = math.min(MIN.world_x, station.world_x)
        MIN.world_y = math.min(MIN.world_y, station.world_y)
        MIN.world_z = math.min(MIN.world_z, station.world_z)
    end
end
table.sort(SET_ID)

function ToCompressedLine(set_id, stations)
    local cells = {}
    ta(cells, "%d", set_id)

                        -- Find a local mimimum
    local local_min = { world_x = HUGE
                      , world_y = HUGE
                      , world_z = HUGE
                      }
    for _,i in ipairs({1,2,6,7}) do
        local station = stations[i]
        local_min.world_x = math.min(local_min.world_x, station.world_x)
        local_min.world_y = math.min(local_min.world_y, station.world_y)
        local_min.world_z = math.min(local_min.world_z, station.world_z)
    end

                    -- Offset that min from our global min
    ta(cells, "%d", local_min.world_x - MIN.world_x)
    ta(cells, "%d", local_min.world_y - MIN.world_y)
    ta(cells, "%d", local_min.world_z - MIN.world_z)

                    -- Offset each station from that local min
    local stations = DATA[set_id]
    for _,i in ipairs({1,2,6,7}) do
        local station = stations[i]
        local offsets = { world_x     = station.world_x - local_min.world_x
                        , world_y     = station.world_y - local_min.world_y
                        , world_z     = station.world_z - local_min.world_z
                        , orientation = rad2deg(station.orientation) / 10
                        }
        ta(cells, "%d", offsets.world_x)
        ta(cells, "%d", offsets.world_y)
        ta(cells, "%d", offsets.world_z)
        ta(cells, "%d", offsets.orientation)
    end
    local line = table.concat(cells, " ")
    return line
end

-- OUTPUT
for _,set_id in ipairs(SET_ID) do
    local line = ToCompressedLine(set_id, DATA[set_id])
    print(line)
end
