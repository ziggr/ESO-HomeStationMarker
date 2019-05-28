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
    d("cmd:"..tostring(cmd).." args:"..tostring(args))
    if not cmd then
        return
    end
    local self = HomeStationMarker

    if cmd:lower() == "forget" then
        if args and args:lower() == "all" then
            Info("forgetting all station locations...")
            self.ForgetStations({all=true})
        else
            Info("forgetting current house's station locations...")
            self.ForgetStations()
        end
        return
    end

    if cmd:lower() == "clear" then
        if args and args:lower() == "all" then
            Info("deleting all markers...")
            self.DeleteMarks({all=true})
        else
            Info("deleting current house's markers...")
            self.DeleteMarks()
        end
        return
    end

                        -- Figure out which station to toggle
    local r = self.TextToStation(cmd)
    if r.set_id or r.station_id then
        Info( "toggling mark for set_id:%s station_id:%s"
            , tostring(r.set_id)
            , tostring(r.station_id))
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

-- Text processor to turn "alessia bs" into
--  { set_id     = 82
--  , set_name   = "Alessia's Bulwark"
--  , station_id = 1    # CRAFTING_TYPE_BLACKSMITHING
--  }
function HomeStationMarker.TextToStation(cmd)
    local r = {}
    return r
end

-- Forget Stations -----------------------------------------------------------

function HomeStationMarker.ForgetStations(args)
    local all_houses = args and args.all
end

-- Delete Marks --------------------------------------------------------------

function HomeStationMarker.DeleteMarks(args)
    local all_houses = args and args.all
end


-- Recording Locations -------------------------------------------------------

function HomeStationMarker.RecordStation(house_key, crafting_type, set_info, station_pos)
    local self = HomeStationMarker
    assert(house_key)
    assert(crafting_type)
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
    sv["loc"][house_key][set_id][crafting_type] = xyz_string

    Debug("RecordStation: h:%s set_id:%-3.3s ct:%s xyz:%-20.20s %s"
         , tostring(house_key)
         , tostring(set_id)
         , tostring(crafting_type)
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

function HomeStationMarker.OnCraftingStationInteract(event, crafting_type, same_station)
    local self = HomeStationMarker
    Debug("OnCraftingStationInteract ct:%s same:%s"
         , tostring(crafting_type), tostring(same_station))
    local house_key     = self.CurrentHouseKey()
    local set_info      = self.CurrentStationSetInfo(crafting_type)
    local station_pos   = self.CurrentStationLocation()
    self.RecordStation(house_key, crafting_type, set_info, station_pos)
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
function HomeStationMarker.CurrentStationSetInfo(crafting_type)
    local ctype = crafting_type or GetCraftingInteractionType()
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
        Debug( "CurrentStationSetInfo: not an equipment station. ct:%d"
             , ctype)
        return nil
    end

    local link = GetSmithingPatternResultLink(unpack(args))
    local set_info = {GetItemLinkSetInfo(link)}
    if not (set_info and set_info[1]) then
        Debug( "CurrentStationSetInfo: no set bonus. ct:%d"
             , ctype)
        return nil
    end

    Debug( "CurrentStationSetInfo: set_id:%d set_name:%s ct:%d"
         , set_info[6]
         , set_info[2]
         , ctype )

    return { set_id        = set_info[6]
           , set_name      = set_info[2]
           , crafting_type = ctype
           }
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

function HomeStationMarker.Togglestation(args)
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

