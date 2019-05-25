HomeStationMarker = {}

local HomeStationMarker             = _G['HomeStationMarker']
HomeStationMarker.name              = "HomeStationMarker"
HomeStationMarker.version           = "5.0.1"
HomeStationMarker.saved_var_version = 1
HomeStationMarker.saved_var_name    = HomeStationMarker.name .. "Vars"

local function Info(msg, ...)
    d("|c999999"..HomeStationMarker.name..": "..string.format(msg,...).."|r")
end
local function Error(msg, ...)
    d("|cFF6666"..HomeStationMarker.name..": "..string.format(msg,...).."|r")
end

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

function HomeStationMarker.OnCraftingStationInteract()
end

function HomeStationMarker.RegisterCraftListener()
    local self = HomeStationMarker
    EVENT_MANAGER:RegisterForEvent(self.name
        , EVENT_CRAFTING_STATION_INTERACT
        , HomeStationMarker.OnCraftingStationInteract
        )
end

function HomeStationMarker.UnregisterCraftListener()
    local self = HomeStationMarker
    EVENT_MANAGER:UnregisterForEvent(self.name
        , EVENT_CRAFTING_STATION_INTERACT)
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

