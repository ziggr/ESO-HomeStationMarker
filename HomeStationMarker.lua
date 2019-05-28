HomeStationMarker.saved_var_version = 1
HomeStationMarker.saved_var_name    = HomeStationMarker.name .. "Vars"

local Debug = HomeStationMarker.Debug
local Info  = HomeStationMarker.Info
local Error = HomeStationMarker.Error

HomeStationMarker.SET_ID_NONE       = "no_set"
HomeStationMarker.SET_ID_TRANSMUTE  = "transmute"
HomeStationMarker.SET_ID_ASSISTANTS = "assistants"
HomeStationMarker.SET_ID_MUNDUS     = "mundus"

-- Slash Commands ------------------------------------------------------------

function HomeStationMarker.RegisterSlashCommands()
    local lsc = LibStub:GetLibrary("LibSlashCommander", true)
    if lsc then
        local cmd = lsc:Register( "/hsm"
                                , function(args) HomeStationMarker.SlashCommand(args) end
                                , "HomeStationMarker <set> <station>")

        local t = { {"forget"    , "Forget all station locations for current house, also deletes all markers for current house." }
                  , {"forget all", "Forget all station locations for all houses, also deletes all markers for all houses." }
                  , {"clear"     , "Delete all markers for current house." }
                  , {"clear all" , "Delete all markers for all houses." }
                  }
        for _, v in pairs(t) do
            local sub = cmd:RegisterSubCommand()
            sub:AddAlias(v[1])
            sub:SetCallback(function(args) HomeStationMarker.SlashCommand(v[1], args) end)
            sub:SetDescription(v[2])
        end
    else
        SLASH_COMMANDS["/hsm"] = HomeStationMarker.SlashCommand
    end
end

function HomeStationMarker.SlashCommand(cmd, args)
    -- d("cmd:"..tostring(cmd).." args:"..tostring(args))
    if not cmd then
        return
    end
    local self = HomeStationMarker

    if cmd:lower() == "forget" then
        if args and args:lower() == "all" then
            Info("Forgetting all station locations...")
            self.ForgetStations({all=true})
        else
            Info("Forgetting current house's station locations...")
            self.ForgetStations()
        end
        return
    end

    if cmd:lower() == "clear" then
        if args and args:lower() == "all" then
            Info("Deleting all markers...")
            self.DeleteMarks({all=true})
        else
            Info("Deleting current house's markers...")
            self.DeleteMarks()
        end
        return
    end

                        -- Figure out which station to toggle
    local r = self.TextToStation(cmd)
    if r and (r.set_id or r.station_id) then
        Info( "Toggling mark for %s"
             , self.ArgToSetStationText(r)
            )
        self.ToggleStation(r)
    end
                        -- Zig-only debugging stuff
    if GetDisplayName() == "@ziggr" then
        if cmd:lower() == "port" then
            JumpToHouse("@ziggr")                    -- NA, alphabetical
            -- JumpToHouse("@ireniicus")                -- EU, alphabetical
            -- JumpToSpecificHouse("@marcopolo184", 46) -- EU, chrono/traits
        end

        if cmd:lower() == "test" then
            Info("testing..."..tostring(args))
            self.Test()
        end
    end
end

-- For more consistent and useful arg dumps to chat.
function HomeStationMarker.ArgToSetStationText(args)
    return string.format( "set_id:%s %s station_id:%s %s"
         , tostring(args and args.set_id)
         , (args and args.set_name) or ""
         , tostring(args and args.station_id)
         , (args and args.station_name) or ""
         )
end

-- Text processor to turn "alessia bs" into
--  { set_id     = 82
--  , set_name   = "Alessia's Bulwark"
--  , station_id = 1    # CRAFTING_TYPE_BLACKSMITHING
--  }
function HomeStationMarker.TextToStation(cmd)
    local self = HomeStationMarker
    local r = self.TextToStationSetIDs(cmd)
    Debug( "TextToStation: '%s' %s"
         , tostring(cmd)
         , self.ArgToSetStationText(r)
         )
    return r
end

-- Forget Stations -----------------------------------------------------------

function HomeStationMarker.ForgetStations(args)
    local all_houses = args and args.all
    Error("ForgetStations: unimplemented")
end

-- Delete Marks --------------------------------------------------------------

function HomeStationMarker.DeleteMarks(args)
    local all_houses = args and args.all
    Error("DeleteMarks: unimplemented")
end


-- Recording Locations -------------------------------------------------------

function HomeStationMarker.FindStation(house_key, set_id, station_id)
    assert(house_key)
    assert(set_id or station_id)

end

function HomeStationMarker.RecordStation(house_key, station_id, set_info, station_pos)
    local self = HomeStationMarker
    assert(house_key)
    assert(station_id)
    assert(station_pos)
    assert(station_pos.world_x and station_pos.world_y and station_pos.world_z )

    local set_id = (set_info and set_info.set_id) or self.SET_ID_NONE
    local xyz    = { station_pos.world_x
                   , station_pos.world_y
                   , station_pos.world_z }
    local xyz_string = table.concat(xyz, "\t")

    local sv = self.saved_vars
    sv["loc"]                    = sv["loc"]            or {}
    sv["loc"][house_key]         = sv["loc"][house_key] or {}
    sv["loc"][house_key][set_id] = sv["loc"][house_key][set_id] or {}
    sv["loc"][house_key][set_id]["name"] = (set_info and set_info.set_name)
    sv["loc"][house_key][set_id][station_id] = xyz_string

    Debug("RecordStation: h:%s set_id:%-3.3s station_id:%s xyz:%-20.20s %s"
         , tostring(house_key)
         , tostring(set_id)
         , tostring(station_id)
         , xyz_string
         , (set_info and set_info.set_name) or ""
         )
end

function HomeStationMarker.OnPlayerActivated(event, initial)
    local self = HomeStationMarker
    local house_key = self.CurrentHouseKey()
    self.Debug("EVENT_PLAYER_ACTIVATED house_key:%s", tostring(house_key))
    if house_key then
        self.RegisterCraftListener()
    else
        self.UnregisterCraftListener()
    end
end

function HomeStationMarker.RegisterCraftListener()
    local self = HomeStationMarker
    Debug("RegisterCraftListener")
    EVENT_MANAGER:RegisterForEvent(self.name
        , EVENT_CRAFTING_STATION_INTERACT
        , HomeStationMarker.OnCraftingStationInteract
        )
end

function HomeStationMarker.UnregisterCraftListener()
    Debug("UnregisterCraftListener")
    local self = HomeStationMarker
    EVENT_MANAGER:UnregisterForEvent(self.name
        , EVENT_CRAFTING_STATION_INTERACT)
end

function HomeStationMarker.OnCraftingStationInteract(event, station_id, same_station)
    local self = HomeStationMarker
    Debug("OnCraftingStationInteract station_id:%s same:%s"
         , tostring(station_id), tostring(same_station))
    local house_key     = self.CurrentHouseKey()
    local set_info      = self.CurrentStationSetInfo(station_id)
    local station_pos   = self.CurrentStationLocation()
    self.RecordStation(house_key, station_id, set_info, station_pos)
end

function HomeStationMarker.CurrentHouseKey()
    local house_owner  = GetCurrentHouseOwner()
    local house_id     = GetCurrentZoneHouseId()

    if house_owner and (house_owner ~= "")
        and house_id and (0 < house_id) then
        return string.format("%d\t%s", house_id, house_owner)
    end
    return nil
end

-- Return the station's set bonus info, if currently interacting with a
-- crafting station that has a craftable set bonus. Return nil if not.
function HomeStationMarker.CurrentStationSetInfo(station_id)
    local ctype = station_id or GetCraftingInteractionType()
    if not (ctype and ctype ~= 0) then
        Error("CurrentStationSetInfo: no crafting type")
        return nil
    end

    local ARGS  = {
      [CRAFTING_TYPE_BLACKSMITHING  ] = { 15,1,3,1,1,0 }
    , [CRAFTING_TYPE_CLOTHIER       ] = { 16,1,7,1,1,0 }
    , [CRAFTING_TYPE_WOODWORKING    ] = {  7,1,3,1,1,0 }
    , [CRAFTING_TYPE_JEWELRYCRAFTING] = {  3,1,2,1,1,0 }
    }
    local args = ARGS[ctype]
    if not args then
        Debug( "CurrentStationSetInfo: not an equipment station. station_id:%d"
             , ctype)
        return nil
    end

    local link = GetSmithingPatternResultLink(unpack(args))
    local set_info = {GetItemLinkSetInfo(link)}
    if not (set_info and set_info[1]) then
        Debug( "CurrentStationSetInfo: no set bonus. station_id:%d"
             , ctype)
        return nil
    end

    Debug( "CurrentStationSetInfo: set_id:%d set_name:%s station_id:%d"
         , set_info[6]
         , set_info[2]
         , ctype )

    local r = { set_id     = set_info[6]
              , set_name   = set_info[2]
              , station_id = ctype
              }
    HomeStationMarker.AddNames(r)
    return r
end

-- Geometry/Location ---------------------------------------------------------

function HomeStationMarker.CurrentPlayerLocation()
    local p = { GetUnitWorldPosition("player") }
    return { zone_id = p[1]
           , world_x = p[2]
           , world_y = p[3]
           , world_z = p[4]
           }
end

function HomeStationMarker.CurrentStationLocation()
                        -- In the future, we might want to offset by a meter or
                        -- two in the player's current orientation. For now,
                        -- just use the player's location. Close enough.
    return HomeStationMarker.CurrentPlayerLocation()
end

-- Marking Stations ----------------------------------------------------------

function HomeStationMarker.Test()
    d("Testing!")
end

function HomeStationMarker.ToggleStation(args)
    local self = HomeStationMarker
    local station_key = self.StationKey(args)
    local sv   = self.saved_vars
    sv.marks = sv.marks or {}

    local found_i = self.FindMarkIndex(args)
    if found_i then
        self.DeleteMark(args)
    else
        self.AddMark(args)
    end
end

function HomeStationMarker.StationKey(args)
    local function tostr(x)
        if not x then return "" else return tostring(x) end
    end
    return string.format("%s\t%s"
            , tostr(args.set_id)
            , tostr(args.station_id)
            )
end

function HomeStationMarker.FromStationKey(station_key)
    local w = HomeStationMarker.split(station_key)
    local function fromstr(s)
        if s == "" then return nil end
        return tonumber(s) or s
    end
    local r = {
        set_id     = fromstr(w[1])
    ,   station_id = fromstr(w[2])
    }
    return r
end

function HomeStationMarker.FindMarkIndex(args)
    local self = HomeStationMarker
    local station_key     = HomeStationMarker.StationKey(args)
    self.saved_vars.marks = self.saved_vars.marks or {}
    for i,sk in ipairs(self.saved_vars.marks) do
        if sk == station_key then
            return i
        end
    end
    return nil
end

function HomeStationMarker.DeleteMark(args)
    local self    = HomeStationMarker
    local found_i = self.FindMarkIndex(args)
    if not found_i then
        Error( "DeleteMark: no marker found for set_id:%s station_id:%s"
             , tostring(args.set_id)
             , tostring(args.station_id)
             )
        return nil
    end
    Debug("DeleteMark: set:%s station:%s found_i:%s"
            , tostring(args.set_id)
            , tostring(args.station_id)
            , tostring(found_i)
            )
    table.remove(self.saved_vars.marks, found_i)

    self.HideMarkControl(args.set_id, args.station_id)
end

-- Add this station to the list of stations that get a 3D marker control
-- whenever we enter a house that has this station.
--
-- If already in a house with this station, immediately create a 3D
-- marker control.
--
function HomeStationMarker.AddMark(args)
    local self    = HomeStationMarker
    local found_i = self.FindMarkIndex(args)
    if found_i then
        Error( "AddMark: marker already exists for set_id:%s station_id:%s found_i:%d"
             , tostring(args.set_id)
             , tostring(args.station_id)
             , found_i)
        return nil
    end
    Debug("AddMark: set:%s station:%s"
            , tostring(args.set_id)
            , tostring(args.station_id)
            )
    local station_key = self.StationKey(args)
    table.insert(self.saved_vars.marks, station_key)

    self.ShowMarkControl(args.set_id, args.station_id)
end

-- 3D Marker Controls --------------------------------------------------------
function HomeStationMarker.ShowMarkControl(set_id, station_id)
    Error("ShowMarkControl: unimplemented")
end

function HomeStationMarker.HideMarkControl(set_id, station_id)
    Error("HideMarkControl: unimplemented")
end

-- Init ----------------------------------------------------------------------

function HomeStationMarker.OnAddOnLoaded(event, addonName)
    local self = HomeStationMarker
    if addonName ~= self.name then return end

    self.inited     = true
    self.saved_vars = ZO_SavedVars:NewAccountWide(
                              "HomeStationMarkerVars"
                            , self.saved_var_version
                            , nil
                            , self.default
                            )
    self.RegisterCraftListener()
end


EVENT_MANAGER:RegisterForEvent( HomeStationMarker.name
                              , EVENT_ADD_ON_LOADED
                              , HomeStationMarker.OnAddOnLoaded
                              )

EVENT_MANAGER:RegisterForEvent( HomeStationMarker.name
                              , EVENT_PLAYER_ACTIVATED
                              , HomeStationMarker.OnPlayerActivated
                              )

HomeStationMarker.RegisterSlashCommands()


--[[

EU server:
Stations, by DLC chronology? Huh.
/script JumpToSpecificHouse("@marcopolo184", 46)

Stations, alphabetical:
/script JumpToHouse("@ireniicus")

NA server:
/script JumpToHouse("@ziggr")


|H0:item:135717:30:1:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0:0|h|h

Adept Rider's Axe

zos_set_index = 385

GetItemLinkSetInfo(string itemLink, boolean equipped)
Returns: boolean hasSet, string setName, number numBonuses, number numEquipped, number maxEquipped, number setId

--]]

