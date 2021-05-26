HomeStationMarker = HomeStationMarker or {}

-- From http://lua-users.org/wiki/SplitJoin
-- 2021-05-22 Does not work on Lua 5.3.3.
function HomeStationMarker.splitX(str,sep)
    sep = sep or "\t"
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

-- From http://lua-users.org/wiki/SplitJoin
-- 2021-05-22 Worksbb on Lua 5.3.3.
function HomeStationMarker.split(str,sep)
    sep = sep or "\t"
    local ret = {}

    if str:len() > 0 then
        local is_plain = true

        local word_index, word_begin = 1, 1
        local sep_begin,sep_end = str:find(sep, word_begin, is_plain)
        while sep_begin do
            ret[word_index] = str:sub(word_begin, sep_begin-1)
            word_index = word_index+1
            word_begin = sep_end+1
            sep_begin,sep_end = str:find(sep, word_begin, is_plain)
      end
      ret[word_index] = str:sub(word_begin)
   end

   return ret
end

                        -- Why "or 1"? So that this code can run in a test
                        -- environment outside of ESO.
HomeStationMarker.STATION_ALL = {
    [CRAFTING_TYPE_ALCHEMY         or 4] = { "al", "alchemy"        }
,   [CRAFTING_TYPE_BLACKSMITHING   or 1] = { "bs", "blacksmithing"  }
,   [CRAFTING_TYPE_CLOTHIER        or 2] = { "cl", "clothier"       }
,   [CRAFTING_TYPE_ENCHANTING      or 3] = { "en", "enchanting"     }
,   [CRAFTING_TYPE_JEWELRYCRAFTING or 7] = { "jw", "jewelrycrafting"}
,   [CRAFTING_TYPE_PROVISIONING    or 5] = { "pr", "provisioning"   }
,   [CRAFTING_TYPE_WOODWORKING     or 6] = { "ww", "woodworking"    }
}

                        -- Which crafting stations can be crafted
                        -- at a set bonus table (bs cl ww jw)?
                        --
                        -- Helps avoid "Clever Alch" erroneously matching
                        -- "Alchemy"
                        --
                        -- See also HomeStationMarker.STATION_EQUIPMENT_SEQUENCE
                        -- defined in HomeStationMarker_Text.lua
HomeStationMarker.STATION_EQUIPMENT = {
    [CRAFTING_TYPE_BLACKSMITHING   or 1] = HomeStationMarker.STATION_ALL[1]
,   [CRAFTING_TYPE_CLOTHIER        or 2] = HomeStationMarker.STATION_ALL[2]
,   [CRAFTING_TYPE_JEWELRYCRAFTING or 7] = HomeStationMarker.STATION_ALL[7]
,   [CRAFTING_TYPE_WOODWORKING     or 6] = HomeStationMarker.STATION_ALL[6]
}

function HomeStationMarker.AddNames(r)
    local self = HomeStationMarker
    local libsets = self.LibSets()
    if r and r.set_id and libsets then
        r.set_name = r.set_name or libsets.GetSetName(r.set_id)
    end
    if r and r.station_id then
        if not self.STATION_NAMES then
            local GetString = GetString or function () return nil end
            self.STATION_NAMES = {
                [CRAFTING_TYPE_ALCHEMY         or 4] = GetString(SI_ITEMFILTERTYPE16)
            ,   [CRAFTING_TYPE_BLACKSMITHING   or 1] = GetString(SI_ITEMFILTERTYPE13)
            ,   [CRAFTING_TYPE_CLOTHIER        or 2] = GetString(SI_ITEMFILTERTYPE14)
            ,   [CRAFTING_TYPE_ENCHANTING      or 3] = GetString(SI_ITEMFILTERTYPE17)
            ,   [CRAFTING_TYPE_JEWELRYCRAFTING or 7] = GetString(SI_ITEMFILTERTYPE24)
            ,   [CRAFTING_TYPE_PROVISIONING    or 5] = GetString(SI_ITEMFILTERTYPE18)
            ,   [CRAFTING_TYPE_WOODWORKING     or 6] = GetString(SI_ITEMFILTERTYPE15)
            }
        end
        r.station_name = r.station_name or self.STATION_NAMES[r.station_id]
    end
    return r
end

function HomeStationMarker.TextToStationSetIDs(text)
    local self = HomeStationMarker
    local w = self.split(text, " ")

    local r = {}

                        -- Is last word of a multi-word request
                        -- a crafting station? "clever alch bs"
                        --
                        -- If so, use it and remove it from the match string
                        -- to get it out of the way of set name match later.
    if 2 <= #w then
        local n = self.ToStation(w[#w], self.STATION_EQUIPMENT)
        if n then
            r.station_id = n
            r.station_text = w[#w]
            w[#w] = nil
            self.AddNames(r)
        end
    end
                        -- Remainder is either a set name "clever alch" or
                        -- just a crafting station "alch" without a set name.

                        -- Just a crafting station? Only if its the first
                        -- and only word "al" not part of a longer string of
                        -- gibberish "al bundy"
    local rem  = table.concat(w, " ")
    if 1 == #w then
        local n = self.ToStation(rem, self.STATION_ALL)
        if n then
            r.station_id = n
            r.station_text = rem
            self.AddNames(r)
            return r
        end
    end
                        -- Set name?
    n = self.ToSet(rem)
    if n then
        r.set_id   = n
        r.set_text = rem
    end

                        -- If we found anything, return that.
    if r.station_id or r.set_id then
        self.AddNames(r)
        return r
    end

                        -- If we found nothing, return nothing.
    return nil
end

HomeStationMarker.SET_ABBREV = {
    ["tbs"          ] = 161 -- Twice-Born Star
,   ["nmg"          ] =  51 -- Night Mother's Gaze
,   ["julianos"     ] = 207 -- Law of Julianos
,   ["kags"         ] =  92 -- Kagrenac's Hope
,   ["seducer"      ] =  43 -- Armor of the Seducer
,   ["whitestrake"  ] =  41 -- Whitestrake's Retribution
}

-- Return a sorted table of set names, including any aliases.
-- All names are returned simplified: lowercase, no punctuation or spaces.
function HomeStationMarker.SetNameTable()
    local self = HomeStationMarker
    if self.set_name_table then return self.set_name_table end
    local libsets = self.LibSets()
    if not libsets then return nil end

    local set_names = {}
    local lookup = {}

    for set_id, _ in pairs(libsets.craftedSets) do
        local sn  = libsets.GetSetName(set_id)
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
    if not s then return s end
    local lower    = string.lower(s)
    local no_punct = string.gsub(lower,"[^%l]","")
    return no_punct
end

function HomeStationMarker.StartsWith(longer, prefix)
   return longer:sub(1, #prefix) == prefix
end

-- Return the least element of t whose value for `key` is >= want_val.
function HomeStationMarker.FindGE(t, want_val, key)
    if not (t and want_val and key) then return nil end

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

function HomeStationMarker.ToStation(s, station_list)
    local self = HomeStationMarker
    if not s then return nil end
                        -- Specified by number? "1" for bs?
    local n    = tonumber(s)
    if n and station_list[n] then
        return n
    end

                        -- Specified by station name? "bs" for bs?
    local wwl = self.SimplifyString(s)
    if 2 <= #wwl then
        for i,abbr_list in pairs(station_list) do
            for _,abbr in ipairs(abbr_list) do
                if self.StartsWith(abbr, wwl) then
                    return i
                end
            end
        end
    end

    return nil
end

function HomeStationMarker.ToSet(s)
    if not s then return nil end
    local self = HomeStationMarker
                        -- Specifed by number? "225" for Clever Alchemist?
    local n    = tonumber(s)
    if n then
        return n
    end

                        -- Prefix (or entire) of s set name?
    local wwl = self.SimplifyString(s)
    local set_name_table = self.SetNameTable()
    local row = self.FindGE(set_name_table, wwl, "set_name")
    if row then
        if self.StartsWith(self.SimplifyString(row.set_name), wwl) then
            return row.set_id
        end
    end

                        -- Abbreviation of a set name?
    for abbrev, set_id in pairs(self.SET_ABBREV) do
        if self.StartsWith(abbrev, wwl) then
            return set_id
        end
    end

    return nil
end

function HomeStationMarker.LibSets()
    local self = HomeStationMarker
    if not self.lib_sets then
        if not LibSets then
            self.Error("LibSets required for set name searches.")
            return nil
        end

        if LibSets.IsSetsScanning() then
            self.Error("LibSets still scanning. Wait.")
            return nil
        end

        if not LibSets.AreSetsLoaded() then
            self.Error("LibSets sets not loaded.")
            return nil
        end
        self.lib_sets = LibSets
    end
    return self.lib_sets
end

                        -- See also HomeStationMarker.STATION_EQUIPMENT
                        -- defined in HomeStationMarker.lua
HomeStationMarker.STATION_EQUIPMENT_SEQUENCE = {
    CRAFTING_TYPE_BLACKSMITHING   or 1
,   CRAFTING_TYPE_CLOTHIER        or 2
,   CRAFTING_TYPE_JEWELRYCRAFTING or 7
,   CRAFTING_TYPE_WOODWORKING     or 6
}

function HomeStationMarker.XYZToString(coord)
    return string.format( "%d %d %d"
                           , coord.world_x
                           , coord.world_y
                           , coord.world_z )
end

function HomeStationMarker.StringToXYZ(s)
    if not s then return nil end
    local w = HomeStationMarker.split(s, " ")
    if 3 ~= #w then return nil end
    local coord  = { ["world_x"] = tonumber(w[1])
                   , ["world_y"] = tonumber(w[2])
                   , ["world_z"] = tonumber(w[3])
                   }
    return coord
end

function HomeStationMarker.Export4(set_id, station_table)

                        -- Offset all 4 station locations from some nearby
                        -- minimum coord. Then all 4 station locations will
                        -- later become small positive offsets from the min.
    local HUGE      = 100000000
    local min_coord = { world_x = HUGE,  world_y = HUGE,  world_z = HUGE }
    for _,station_id in ipairs(HomeStationMarker.STATION_EQUIPMENT_SEQUENCE) do
        local coord = station_table[station_id]
        if coord then
            min_coord.world_x = math.min(min_coord.world_x, coord.world_x)
            min_coord.world_y = math.min(min_coord.world_y, coord.world_y)
            min_coord.world_z = math.min(min_coord.world_z, coord.world_z)
        end
    end

    local t = { tostring(set_id) }
    table.insert(t,HomeStationMarker.XYZToString(min_coord))
    for _,station_id in ipairs(HomeStationMarker.STATION_EQUIPMENT_SEQUENCE) do
        local coord = station_table[station_id]
        if coord then
            local offset = { ["world_x"] = coord.world_x - min_coord.world_x
                           , ["world_y"] = coord.world_y - min_coord.world_y
                           , ["world_z"] = coord.world_z - min_coord.world_z
                           }
            table.insert(t,HomeStationMarker.XYZToString(offset))
        else
            table.insert(t,"")
        end
    end
    return table.concat(t, "/")
end

function HomeStationMarker.Import4(line)
    local w = HomeStationMarker.split(line, "/")
    local set_id = tonumber(w[1])
    local min_coord = HomeStationMarker.StringToXYZ(w[2])

    local station_table = {}

    for i,ct in ipairs(HomeStationMarker.STATION_EQUIPMENT_SEQUENCE) do
        local offset = HomeStationMarker.StringToXYZ(w[2+i])
        if offset then
            local coord  = { ["world_x"] = offset.world_x + min_coord.world_x
                           , ["world_y"] = offset.world_y + min_coord.world_y
                           , ["world_z"] = offset.world_z + min_coord.world_z
                           , }
            station_table[ct] = coord
        end
    end

    return set_id, station_table
end

function HomeStationMarker.Export1(set_id, station_id, coord)
    if not (coord.world_x and coord.world_y and coord.world_z) then return "" end

    return string.format("%s:%s/%d %d %d"
                        , tostring(set_id)
                        , tostring(station_id)
                        , coord.world_x
                        , coord.world_y
                        , coord.world_z
                        )
end

function HomeStationMarker.Import1(line)
    local w = HomeStationMarker.split(line, "/")
    local ww = HomeStationMarker.split(w[1], ":")
    local coord = HomeStationMarker.StringToXYZ(w[2])
    local station_id = ww[1]
    local set_id     = ww[2]
    return station_id, set_id, coord
end

function HomeStationMarker.ImportLine(line, output)
                        -- Skip comments. # won't occur ANYWHERE
                        -- in our set_id, station_id, integer character set,
                        -- so any such line is to be ignored as a comment.
    if string.find(line, "#") then return end

                        -- set_id:station_id single-station lines
    if line:find(":") then
        local set_id, station_id, coord = HomeStationMarker.Import1(line)
        if tonumber(set_id) then set_id = tonumber(set_id) end
        if tonumber(station_id) then station_id = tonumber(station_id) end
        output[set_id] = output[set_id] or {}
        output[set_id][station_id] = output[set_id][station_id] or {}

        output[set_id][station_id]["world_x"] = coord.world_x
        output[set_id][station_id]["world_y"] = coord.world_y
        output[set_id][station_id]["world_z"] = coord.world_z
        return
    end
                        -- No colon? Must me a 4-station line.
    local set_id, station_table = HomeStationMarker.Import4(line)
    if set_id and station_table then
        output[set_id] = station_table
    end
end

local function sorted_keys(t)
    local r = {}
    for key,_ in pairs(t) do table.insert(r, key) end
    local function cmp(a,b)
        if type(a) ~= type(b) then
            return cmp(type(a), type(b))
        end
        return a < b
    end
    table.sort(r, cmp)
    return r
end

-- Copied from https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
local function lines_in(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
end

function HomeStationMarker.ExportStations(station_location)
    local lines         = {}
    local set_id_list   = sorted_keys(station_location)
    for _, set_id in ipairs(set_id_list) do
        local station_ls_table = station_location[set_id]
        if tonumber(set_id) then
            local station_table = {}
            for k,v in pairs(station_ls_table) do
                if k ~= "name" then
                    local coord = HomeStationMarker.FromStationLocationString(v)
                    station_table[k] = coord
                end
            end
            local line = HomeStationMarker.Export4(set_id, station_table)
            table.insert(lines, line)
        else
            local station_id_list = sorted_keys(station_ls_table)
            for _, station_id in ipairs(station_id_list) do
                local ls    = station_ls_table[station_id]
                local coord = HomeStationMarker.FromStationLocationString(ls)
                local line  = HomeStationMarker.Export1(set_id, station_id, coord)
                table.insert(lines, line)
            end
        end
    end
    return table.concat(lines, "\n")
end

function HomeStationMarker.ImportStations(text)
    local output = {}

    for line in lines_in(text) do
        HomeStationMarker.ImportLine(line, output)
    end
    return output
end
