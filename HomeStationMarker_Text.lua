HomeStationMarker = HomeStationMarker or {}

-- From http://lua-users.org/wiki/SplitJoin
local function split(str,sep)
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

                        -- Why "or 1"? So that this code can run in a test
                        -- environment outside of ESO.
HomeStationMarker.STATION_SET = {
    [CRAFTING_TYPE_ALCHEMY         or 4] = { "al", "alchemy"        }
,   [CRAFTING_TYPE_BLACKSMITHING   or 1] = { "bs", "blacksmith"     }
,   [CRAFTING_TYPE_CLOTHIER        or 2] = { "cl", "clothier"       }
,   [CRAFTING_TYPE_ENCHANTING      or 3] = { "en", "enchanting"     }
,   [CRAFTING_TYPE_JEWELRYCRAFTING or 7] = { "jw", "jewelrycrafting"}
,   [CRAFTING_TYPE_PROVISIONING    or 5] = { "pr", "provisioning"   }
,   [CRAFTING_TYPE_WOODWORKING     or 6] = { "ww", "woodworking"    }
}


function HomeStationMarker.TextToStationSetIDs(text)
    local self = HomeStationMarker
    local w = split(text, " ")

    local r = {}

                        -- Scan for station first.
                        -- Station identifier, if any, must be in first or
                        -- last word.
    local wilist = { #w, 1 }
    for _,wi in pairs(wilist) do
        local ww = w[wi]


                        -- Specified by number?
                        --
                        -- We depend on no crafting type (1..7) matching
                        -- any craftable set_id (37+ .. 410 ...)
        local n = tonumber(ww)
        if n then
            if self.STATION_SET[n] then
                r.station_id   = n
                r.station_text = ww
            elseif LibSets.craftedSets[n] then
                r.set_id   = n
                r.set_text = ww
            end
        end

                        -- Crafting Station abbreviation?
        local wwl = self.SimplifyString(ww)
        if 2 <= #wwl then
            for station_id, abbr_list in pairs(self.STATION_SET) do
                if r.station_id then break end
                for _,abbr in pairs(abbr_list) do
                    if self.StartsWith(abbr, wwl) then
                        r.station_id = station_id
                        r.station_text = ww
                        break
                    end
                end
            end
        end
    end
                        -- Set Name?
    local want_t = w
                        -- If we used last word for station name,
                        -- don't include it in set name.
    if r.station_id then table.remove(want_t, #want_t) end
    local want   = table.concat(want_t, " ")
    local want_l = self.SimplifyString(want)
    local row = self.FindGE(self.SetNameTable(), want_l, "set_name")
    if row and self.StartsWith(row.set_name, want_l) then
        r.set_id   = row.set_id
        r.set_text = ww
        r.set_name = row.set_name
    end

                        -- If we found anything, return that
    if r.station_id or r.set_id then return r end

                        -- If we found nothing, return that.
    return nil
end

HomeStationMarker.SET_ABBREV = {
    ["tbs"      ] = 161 -- Twice-Born Star
,   ["nmg"      ] =  51 -- Night Mother's Gaze
,   ["julianos" ] = 207 -- Law of Julianos
,   ["kags"     ] =  92 -- Kagrenac's Hope
,   ["seducer"  ] =  43 -- Armor of the Seducer
}

-- Return a sorted table of set names, including any aliases.
-- All names are returned simplified: lowercase, no punctuation or spaces.
function HomeStationMarker.SetNameTable()
    local self = HomeStationMarker
    if self.set_name_table then return self.set_name_table end

    local set_names = {}
    local lookup = {}

    for set_id, _ in pairs(LibSets.craftedSets) do
        local sn  = LibSets.GetSetName(set_id)
        local snl = self.SimplifyString(sn)
        lookup[snl] = set_id
        table.insert(set_names, snl)
    end
    for abbrev, set_id in pairs(self.SET_ABBREV) do
        local snl = self.SimplifyString(abbrev)
        lookup[snl] = set_id
        table.insert(set_names, snl)
    end

    table.sort(set_names)

    local r = {}
    for _, set_name in ipairs(set_names) do
        local row = { set_name = set_name, set_id = lookup[set_name] }
        table.insert(r, row)
    end

    self.set_name_table = r
    return self.set_name_table
end

function HomeStationMarker.SimplifyString(s)
    local lower    = string.lower(s)
    local no_punct = string.gsub(lower,"[^%l]","")
    return no_punct
end

function HomeStationMarker.StartsWith(longer, prefix)
   return longer:sub(1, #prefix) == prefix
end

-- Return the least element of t whose value for `key` is >= want_val.
function HomeStationMarker.FindGE(t, want_val, key)

                        -- Ideally this would be an O(log n) binary search
                        -- not an O(n) scan. But lua lacks such basic tools,
                        -- and I've got better things to do with my day than
                        -- reinvent the wheel.
    for _, row in ipairs(t) do
        if row[key] >= want_val then
            return row
        end
    end
    return nil
end
