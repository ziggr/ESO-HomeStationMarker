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

for set_id, stations in pairs(ORIGINAL) do
    local line = ToLine(set_id, stations)
    if line then print(line) end
end
