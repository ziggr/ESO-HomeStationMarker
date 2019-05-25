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
                  , {"clear"     , "Delete all markers for all houses." }
                  , {"test"      , "do the thing." }
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
    if not cmd then
        Info("Hiya!")
        return
    end

    if cmd:lower() == "forget" then
        if args and args:lower() == "all" then
            HomeStationMarker.ForgetStations({all=true})
        else
            HomeStationMarker.ForgetStations()
        end
        return
    end

    if cmd:lower() == "clear" then
        if args and args:lower() == "all" then
            HomeStationMarker.DeleteMarks({all=true})
        else
            HomeStationMarker.DeleteMarks()
        end
        return
    end

    if cmd:lower() == "port" then
        JumpToHouse("@ziggr")                    -- NA, alphabetical
        -- JumpToHouse("@ireniicus")                -- EU, alphabetical
        -- JumpToSpecificHouse("@marcopolo184", 46) -- EU, chrono/traits
    end

    if cmd:lower() == "test" then
        Info("testing..."..tostring(args))
        HomeStationMarker.Test()
    end
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

