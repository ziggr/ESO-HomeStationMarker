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
    [CRAFTING_TYPE_ALCHEMY         or 4] = { "al" }
,   [CRAFTING_TYPE_BLACKSMITHING   or 1] = { "bs" }
,   [CRAFTING_TYPE_CLOTHIER        or 2] = { "cl" }
,   [CRAFTING_TYPE_ENCHANTING      or 3] = { "en" }
,   [CRAFTING_TYPE_JEWELRYCRAFTING or 7] = { "jw" }
,   [CRAFTING_TYPE_PROVISIONING    or 5] = { "pr" }
,   [CRAFTING_TYPE_WOODWORKING     or 6] = { "ww" }
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



                        -- If we found anything, return that
    if r.station_id or r.set_id then return r end

                        -- If we found nothing, return that.
    return nil
end

function HomeStationMarker.SimplifyString(s)
    local lower    = string.lower(s)
    local no_punct = string.gsub(lower,"[^%l]","")
    return no_punct
end

function HomeStationMarker.StartsWith(longer, prefix)
   return longer:sub(1, #prefix) == prefix
end
