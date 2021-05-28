-- HomeStationMarker
--
-- Draw 3D beacons above crafting stations in player housing.

HomeStationMarker.saved_var_version = 2
HomeStationMarker.saved_var_name    = HomeStationMarker.name .. "Vars"

local Debug = HomeStationMarker.Debug
local Info  = HomeStationMarker.Info
local Error = HomeStationMarker.Error

-- "set_id" is usually the integer setId assigned by ESO, such as
-- 82 for "Alessia's Bulwark". For such set_id, their "station_id" values
-- will be integer CRAFTING_TYPE_X values [1..7].
--
-- We also reserve a few non-integer set_ids here for special categories
-- because we might one day support beacons over Tythis the Banker and other
-- important interactable items in player housing.
--
HomeStationMarker.SET_ID_NONE       = "no_set"
HomeStationMarker.SET_ID_MISC       = "misc"            -- not implemented
HomeStationMarker.SET_ID_ASSISTANTS = "assistants"      -- not implemented
HomeStationMarker.SET_ID_MUNDUS     = "mundus"          -- not implemented

HomeStationMarker.STATION_ID = {
    -- SET_ID_ASSITANTS
    BANKER              = "banker"      -- Tythis
,   MERCHANT            = "merchant"    -- Nuzhimeh
,   FENCE               = "fence"       -- Pirharri

    -- SET_ID_MISC
,   TRANSMUTE           = "transmute"
,   OUTFITTER           = "outfitter"

    -- SET_ID_MUNDUS
,   MUNDUS_APPRENTICE   = "apprentice"
,   MUNDUS_ATRONACH     = "atronach"
,   MUNDUS_LADY         = "lady"
,   MUNDUS_LORD         = "lord"
,   MUNDUS_LOVER        = "lover"
,   MUNDUS_MAGE         = "mage"
,   MUNDUS_RITUAL       = "ritual"
,   MUNDUS_SERPENT      = "serpent"
,   MUNDUS_SHADOW       = "shadow"
,   MUNDUS_STEED        = "steed"
,   MUNDUS_THIEF        = "thief"
,   MUNDUS_TOWER        = "tower"
,   MUNDUS_WARRIOR      = "warrior"
}

-- RefCounted API ------------------------------------------------------------

-- Request a marker above a station.
--
-- returns true if request added, nil if not, either due to there already
-- having a previous request for that station, or unable to show because
-- no known location for the station in this house (or not in a house.)
--
-- Requested station will be shown immediately if in a player house with that
-- station, and station location is already known to HomeStationMarker from
-- a previous player interaction with that station.
--
function HomeStationMarker.AddMarker(set_id, station_id)
    local self = HomeStationMarker
    Debug( "AddMarker set_id:%s station_id:%s"
         , tostring(set_id)
         , tostring(station_id)
         )
    set_id = set_id or self.SET_ID_NONE
    assert(station_id)
    local requested =  self.RequestMark(
                                { set_id     = set_id
                                , station_id = station_id
                                })
    local shown = nil
    if requested then
        shown = self.ShowMarkControl(set_id, station_id)
    end
    self.IncrementRefCount(set_id, station_id)
    return requested and shown
end

-- Decrement refcount for this station. If refcount becomes 0, then
-- hide the marker.
function HomeStationMarker.DeleteMarker(set_id, station_id)
    local self = HomeStationMarker
    Debug( "DeleteMarker set_id:%s station_id:%s"
         , tostring(set_id)
         , tostring(station_id)
         )
    set_id = set_id or self.SET_ID_NONE
    assert(station_id)
    local rc = self.DecrementRefCount(set_id, station_id)
    if 0 < rc then      -- Non-zero refcount means somebody else still
        return nil      -- wants this marker.
    end
    local unrequested = self.UnrequestMark(
                                { set_id     = set_id
                                , station_id = station_id
                                })
    if unrequested then
        self.HideMarkControl(set_id, station_id)
    end
    return unrequested
end

-- Unconditionally clear refcounts and hide all markers.
function HomeStationMarker.DeleteAllMarkers()
    local self = HomeStationMarker
    Debug("DeleteAllMarkers")
    self.saved_vars.requested_mark = {}
    self.ResetAllRefCounts()
    local house_key = self.CurrentHouseKey()
    if house_key then
        self.HideAllMarkControls()
    end
end


-- Internal ------------------------------------------------------------------

--
-- * Station Location
--   Record station locations as the player walks around an interacts with
--   stations. Ideally, we could just iterate over the placed furnishings in
--   the house, but that requires "deccorator" permission which is rarely
--   granted except in houses that the player owns.
--   RecordStationLocation() / FindStationLocation() / saved_vars.station_location
--
-- * Requested Mark
--   Stations that we should draw beacons over, when possible.
--   Just a list of set_id+station_id tuples.
--   AddRequestedMark() / DeleteRequestedMark() / saved_vars.requested_mark
--   Increment/Decrement/ClearRefCount()        / saved_vars.requested_mark_refcounts
--
-- * MarkControl
--   3D Controls that are the beacons that appear in 3D space.
--   Ideally, one of these for each station listed in "Marks", but often
--   fewer MarkControls if we don't know the station locations for each
--   set_id + station_id
--   ShowMarkControl() / HideMarkControl() / never saved_vars

HomeStationMarker.debug_scan = false

local sid = HomeStationMarker.STATION_ID -- for less typing
-- Textures for the 3D MarkControl
HomeStationMarker.STATION_TEXTURE = {
    [CRAFTING_TYPE_BLACKSMITHING   or 1] = "esoui/art/icons/servicemappins/servicepin_smithy.dds"
,   [CRAFTING_TYPE_CLOTHIER        or 2] = "esoui/art/icons/servicemappins/servicepin_clothier.dds"
,   [CRAFTING_TYPE_ENCHANTING      or 3] = "esoui/art/icons/servicemappins/servicepin_enchanting.dds"
,   [CRAFTING_TYPE_ALCHEMY         or 4] = "esoui/art/icons/servicemappins/servicepin_alchemy.dds"
,   [CRAFTING_TYPE_PROVISIONING    or 5] = "esoui/art/icons/servicemappins/servicepin_inn.dds"
,   [CRAFTING_TYPE_WOODWORKING     or 6] = "esoui/art/icons/servicemappins/servicepin_woodworking.dds"
,   [CRAFTING_TYPE_JEWELRYCRAFTING or 7] = "esoui/art/icons/servicemappins/servicepin_jewelrycrafting.dds"

,   [sid.TRANSMUTE                     ] = "esoui/art/icons/servicemappins/servicepin_transmute.dds"
,   [sid.OUTFITTER                     ] = "esoui/art/icons/servicemappins/servicepin_dyestation.dds"

,   [sid.BANKER                        ] = "esoui/art/icons/servicemappins/servicepin_bank.dds"
,   [sid.MERCHANT                      ] = "esoui/art/icons/servicemappins/servicepin_vendor.dds"
,   [sid.FENCE                         ] = "esoui/art/icons/servicemappins/servicepin_fence.dds"

,   [sid.MUNDUS_APPRENTICE             ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_ATRONACH               ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_LADY                   ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_LORD                   ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_LOVER                  ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_MAGE                   ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_RITUAL                 ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_SERPENT                ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_SHADOW                 ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_STEED                  ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_THIEF                  ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_TOWER                  ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
,   [sid.MUNDUS_WARRIOR                ] = "esoui/art/icons/mapkey/mapkey_mundus.dds"
}
sid = nil

-- Recording "from where did you learn this station's location?"
-- Values used in RecordStationLocation() as elements of station_pos.
-- Table values are in order of priority, lower values beat higher ones.
-- So that we can stop replacing perfect `/hsm scanlocs` locations with
-- awful `OnCraftingStationInteract()` locations.
--
-- FromStationMarker() assumes these values are numbers.
--
HomeStationMarker.LOCATION_FROM = {
    ["HOUSE_SCAN"    ] = 1
,   ["INTERACT_OLD"  ] = 2
,   ["IMPORT"        ] = 3
,   ["INTERACT"      ] = 5
,   ["UNKNOWN"       ] = 9
}

-- Slash Commands and Command-Line Interface UI ------------------------------

function HomeStationMarker.RegisterSlashCommands()
    local self = HomeStationMarker
    local lsc = LibSlashCommander
    if not lsc and LibStub then lsc = LibStub:GetLibrary("LibSlashCommander", true) end
    if lsc then
        local langSlashCommandsEN = self.LANG["en"]["slash_commands"]
        local langSlashCommands = self.LANG[self.clientlang]["slash_commands"]
        local setStationCmdText = string.format(langSlashCommands["SC_SET_STATION"], HomeStationMarker.name, langSlashCommands["SC_SET"], langSlashCommands["SC_STATION"])
        local cmd = lsc:Register( "/hsm"
            , function(args) HomeStationMarker.SlashCommand(args) end
            , setStationCmdText)

        local tEN = {
              {tostring(langSlashCommandsEN["SC_FORGET_LOCS_CMD"]),     langSlashCommandsEN["SC_FORGET_LOCS"]}
            , {tostring(langSlashCommandsEN["SC_FORGET_LOCS_ALL_CMD"]), langSlashCommandsEN["SC_FORGET_LOCS_ALL"]}
            , {tostring(langSlashCommandsEN["SC_SCAN_LOCS_CMD"]),       langSlashCommandsEN["SC_SCAN_LOCS"]}
            , {tostring(langSlashCommandsEN["SC_CLEAR_MARKS_CMD"]),     langSlashCommandsEN["SC_CLEAR_MARKS"]}
            , {tostring(langSlashCommandsEN["SC_EXPORT_CMD"]),          langSlashCommandsEN["SC_EXPORT"]}
            , {tostring(langSlashCommandsEN["SC_IMPORT_CMD"]),          langSlashCommandsEN["SC_IMPORT"]}
        }
        local t = {
              {tostring(langSlashCommands["SC_FORGET_LOCS_CMD"]),     langSlashCommands["SC_FORGET_LOCS"]}
            , {tostring(langSlashCommands["SC_FORGET_LOCS_ALL_CMD"]), langSlashCommands["SC_FORGET_LOCS_ALL"]}
            , {tostring(langSlashCommands["SC_SCAN_LOCS_CMD"]),       langSlashCommands["SC_SCAN_LOCS"]}
            , {tostring(langSlashCommands["SC_CLEAR_MARKS_CMD"]),     langSlashCommands["SC_CLEAR_MARKS"]}
            , {tostring(langSlashCommands["SC_EXPORT_CMD"]),          langSlashCommands["SC_EXPORT"]}
            , {tostring(langSlashCommands["SC_IMPORT_CMD"]),          langSlashCommands["SC_IMPORT"]}
        }
        if self.clientlang ~= "en" then
            for _, v in pairs(tEN) do
                local sub = cmd:RegisterSubCommand()
                sub:AddAlias(v[1])
                sub:SetCallback(function(args) HomeStationMarker.SlashCommand(v[1], args) end)
                sub:SetDescription(v[2])
            end
        end
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

    if cmd:lower() == "forgetlocs" then
        if args and args:lower() == "all" then
            Info("Forgetting all station locations...")
            self.ForgetStationLocations({all=true})
        else
            Info("Forgetting current house's station locations...")
            self.ForgetStationLocations()
        end
        return
    end

    if cmd:lower() == "scanlocs" then
        Info("Scanning current house's station locations...")
        self.ScanStationLocations()
        return
    end

    if cmd:lower() == "clear" then
        Info("Clearing marks...")
        self.DeleteAllMarkers()
        return
    end

    if (cmd:lower() == "export") then
        HomeStationMarker_Export_ToggleUI()
        return
    end

    if (cmd:lower() == "import") then
        HomeStationMarker_Import_ToggleUI()
        return
    end

                        -- Figure out which station to toggle
    local r = self.TextToStation(cmd)
    if r and r.station_id then
                        -- Convert text prcessor's `nil` to "no set"
                        -- which we can use as a valid table key.
        r.set_id = r.set_id or self.SET_ID_NONE
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
--  { set_id       = 82
--  , set_name     = "Alessia's Bulwark"
--  , station_id   = 1    # CRAFTING_TYPE_BLACKSMITHING
--  , station_name = "Blacksmithing"
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

function HomeStationMarker.ToggleStation(args)
    local self = HomeStationMarker
    local found_i = self.FindRequestedMarkIndex(args)
    if found_i then
        local removed = self.UnrequestMark(args)
        if removed then
            self.HideMarkControl(args.set_id, args.station_id)
        end
    else
        local added = self.RequestMark(args)
        if added then
            self.ShowMarkControl(args.set_id, args.station_id)
        end
    end
end

function HomeStationMarker.ForgetStationLocations(args)
    local self = HomeStationMarker
    local all_houses = args and args.all
    Debug("ForgetStationLocations")

                        -- Hide any showing 3D MarkControls: we're about to
                        -- forget their locations.
    local house_key = self.CurrentHouseKey()
    if house_key then
        self.HideAllMarkControls()
    end

    if not all_houses then
        if not house_key then
            Error("ForgetStationLocations: ignored. Only works within player housing.")
            return
        end
        local sv_l = self.saved_vars.station_location
        if sv_l and sv_l[house_key] then
            sv_l[house_key] = nil
            Info("Station locations forgotten for house:%s", house_key)
        else
            Info("No station locations to forget for house:%s", house_key)
        end
    else
        if self.saved_vars.station_location then
            self.saved_vars.station_location = {}
            Info("Station locations forgotten all houses.")
        else
            Info("No station locations to forget for any house.")
        end
    end
end

function HomeStationMarker.ScanStationLocations()
    local self = HomeStationMarker
    local house_key = self.CurrentHouseKey()
    if not house_key then
        Error("ScanStationLocations: not in player housing.")
        return
    end
    if nil == GetNextPlacedHousingFurnitureId(nil) then
        Error("ScanStationLocations: no decorator permission in this house,"
              .." or house has no furniture.")
        return
    end
    if not self.LibSets() then
        return
    end

    local furniture_id = GetNextPlacedHousingFurnitureId(nil)
    local loop_limit   = 1000 -- avoid infinite loops in case GNPHFI() surprises us
    local furn_ct      = 0
    local loc_ct       = 0
    while furniture_id and 0 < loop_limit do
        furn_ct = furn_ct + 1
        local o = self.FurnitureToInfo(furniture_id)
        if o then
            loc_ct = loc_ct + 1
            o.station_pos.provenance = self.LOCATION_FROM.HOUSE_SCAN
            self.RecordStationLocation( house_key
                                      , o.station_id
                                      , o.set_info
                                      , o.station_pos
                                      )
        end
        furniture_id = GetNextPlacedHousingFurnitureId(furniture_id)
        loop_limit = loop_limit - 1
    end

    Info("ScanStationLocations: station locations recorded:%d", loc_ct)
end

function HomeStationMarker.Test()
    Debug("Testing!")
end

-- Util ----------------------------------------------------------------------

-- HouseKey is a unique identifier for "a specific house, owned by a specific
-- player." This lets us one player's "Grand Psijic Villa" station locations
-- separately from _another_ player's Grand Psijic Villa's station locations.
--
-- House is a single integer, such as 62 for Grand Psijic Villa
-- Owner is the player's account @-name, such as "@ziggr"

function HomeStationMarker.CurrentHouseKey()
    local house_owner  = GetCurrentHouseOwner()
    local house_id     = GetCurrentZoneHouseId()

    if house_owner and (house_owner ~= "")
        and house_id and (0 < house_id) then
        return string.format("%d\t%s", house_id, house_owner)
    end
    return nil
end

-- Station Locations ---------------------------------------------------------

function HomeStationMarker.FindStationLocation(house_key, set_id, station_id)
    assert(house_key)
    assert(set_id or station_id)
    local self = HomeStationMarker
    local sv_l = self.saved_vars.station_location
    if not (sv_l
            and sv_l[house_key]
            and sv_l[house_key][set_id]
            and sv_l[house_key][set_id][station_id]) then
        return nil
    end

    local s = sv_l[house_key][set_id][station_id]
    if not s then return nil end
    return self.FromStationLocationString(s)
end

function HomeStationMarker.RecordStationLocation( house_key, station_id
                                                , set_info, station_pos )
    local self = HomeStationMarker
    assert(house_key)
    assert(station_id)
    assert(station_pos)
    assert(station_pos.world_x and station_pos.world_y and station_pos.world_z )

    local set_id = (set_info and set_info.set_id) or self.SET_ID_NONE
    local xyz_string = self.ToStationLocationString(station_pos)

    self.saved_vars["station_location"] = self.saved_vars["station_location"] or {}
    local sv_loc = self.saved_vars["station_location"]
    sv_loc[house_key]                     = sv_loc[house_key] or {}
    sv_loc[house_key][set_id]             = sv_loc[house_key][set_id] or {}
    sv_loc[house_key][set_id]["name"]     = (set_info and set_info.set_name)

                        -- If we already have a location, don't let an awful
                        -- OnCraftingStationInteract() location replace a
                        -- perfect ScanStationLocations() location.
    if (sv_loc[house_key][set_id][station_id]) then
        local prev_pos = self.FromStationLocationString(
                                        sv_loc[house_key][set_id][station_id])
        if prev_pos and prev_pos.provenance then
            local new_prov = station_pos.provenance or self.LOCATION_FROM.UNKNOWN
            if prev_pos.provenance < new_prov then
                Debug("RecordStationLocation: skipped, previous location retained.")
                return
            end
        end
    end

    sv_loc[house_key][set_id][station_id] = xyz_string

    Debug("RecordStationLocation: h:%s set_id:%-3.3s station_id:%s xyz:%-25.25s %s"
         , tostring(house_key)
         , tostring(set_id)
         , tostring(station_id)
         , xyz_string
         , (set_info and set_info.set_name) or ""
         )
end

function HomeStationMarker.ToStationLocationString(station_pos)
    assert(station_pos)
    assert(station_pos.world_x and station_pos.world_y and station_pos.world_z )
    local xyz    = { station_pos.world_x
                   , station_pos.world_y
                   , station_pos.world_z
                   }
    if station_pos.orientation then
        local o = string.format("%4.3g", station_pos.orientation)
        table.insert(xyz, o)
    else
        table.insert(xyz, "")
    end
    table.insert(xyz, station_pos.provenance or "")
    local xyz_string = table.concat(xyz, "\t")
    return xyz_string
end

function HomeStationMarker.FromStationLocationString(s)
    assert(s)
    assert(s ~= "")
    local self = HomeStationMarker
    local w = self.split(s, "\t")
    if #w < 3 then HomeStationMarker.Error("bad location string: '%s'", s) end
    assert(3 <= #w)
    local r = { world_x     = tonumber(w[1])
              , world_y     = tonumber(w[2])
              , world_z     = tonumber(w[3])
              , orientation = tonumber(w[4])
              , provenance  = tonumber(w[5]) or self.LOCATION_FROM.UNKNOWN
              }
    assert(r.world_x and r.world_y and r.world_z)

                        -- Migrate old location provenance values to make
                        -- room for IMPORT=3 to sort before INTERACT=5.
    if r.provenance == HomeStationMarker.LOCATION_FROM.INTERACT_OLD then
        r.provenance = HomeStationMarker.LOCATION_FROM.INTERACT
    end

    return r
end

-- Register/unregister event listener to detect station locations while
-- in player housing.
function HomeStationMarker.OnPlayerActivated(event, initial)
    local self = HomeStationMarker
    local house_key = self.CurrentHouseKey()
    self.Debug("EVENT_PLAYER_ACTIVATED house_key:%s", tostring(house_key))
    if house_key then
        self.RegisterCraftListener()
        self.RegisterSceneListener()
        self.RegisterClientInteractListener()
        self.RegisterDyeInteractListener()
        self.RegisterTransmuteInteractListener()
                        -- Yes, tear down any previous mark controls upon
                        -- entering a house. Otherwise we erroneously leave
                        -- the previous house's mark controls existent after
                        -- porting from house A to house B.
        self.HideAllMarkControls()
        self.ShowAllMarkControls()
        self.StartPeriodicRotate()
    else
        self.UnregisterCraftListener()
        self.UnregisterSceneListener()
        self.UnregisterClientInteractListener()
        self.UnregisterDyeInteractListener()
        self.UnregisterTransmuteInteractListener()
        self.HideAllMarkControls()
        self.StopPeriodicRotate()
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
    station_pos.provenance = self.LOCATION_FROM.INTERACT
    self.RecordStationLocation(house_key, station_id, set_info, station_pos)
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
    , [CRAFTING_TYPE_JEWELRYCRAFTING] = {  3,1,3,1,1,0 }
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

-- Interact Listener ---------------------------------------------------------
--
-- Unlike the craft listner, where we can use programmatic constants and API
-- calls to learn the crafting station ID, there does not seem to be any
-- reliable (aka numeric constants) way to learn the banker, merchant, fence,
-- or mundus stone. The outfit station has its own event.
--
-- So instead we listen for EVENT_CLIENT_INTERACT_RESULT and convert its
-- target string "Tythis Andromo, the Banker" to a constant. This requires
-- EN/DE/FR/etc language-dependent string tables. Ugh.

--[[

Banker      EVENT_CLIENT_INTERACT_RESULT(0,"Tythis Andromo, the Banker")
            EVENT_CHATTER_BEGIN
Bank        EVENT_OPEN_BANK(2)
            EVENT_CLOSE_BANK()
            EVENT_CHATTER_END()

Merchant    EVENT_CLIENT_INTERACT_RESULT(0,"Nuzhimeh the Merchant")
            EVENT_CHATTER_BEGIN(1)
Store       EVENT_OPEN_STORE()
            EVENT_CLOSE_STORE()
            EVENT_CHATTER_END()

Fence       EVENT_CLIENT_INTERACT_RESULT(0,"Pirharri the Smuggler")
            EVENT_CHATTER_BEGIN(1)
Fence       EVENT_OPEN_FENCE(true, false)
            EVENT_CLOSE_STORE
            EVENT_CHATTER_END

Outfit Station   USE DYING_STATION!
            EVENT_CLIENT_INTERACT_RESULT(0, "Outfit Station")
            EVENT_DYEING_STATION_INTERACT_START()
            EVENT_CHATTER_END()

Transmute   USE RETRAIT STATION
            EVENT_CLIENT_INTERACT_RESULT(0, "Transmute Station")
            EVENT_RETRAIT_STATION_INTERACT_START()
            EVENT_CHATTER_END

Mundus      EVENT_CONFIRM_INTERACT("Mundus Stone"
                        , "Those under the sign of The Warrior...")
                        , "Accept Sign"
                        , "Cancel"
            EVENT_CLIENT_INTERACT_RESULT(0,"The Warrior")

Tythis Andromo, the Banker
Pirharri the Smuggler
Nuzhimeh the Merchant
                            Hey aren't a new set of banker/merchant/fence
                            NPCs available in the Elsweyr crown store for
                            US$50 each? Yeah, I'm not spending US$100 to
                            learn their names
The Warrior
The Tower
The Thief
The Steed
The Shadow
The Serpent
The Ritual
The Mage
The Lord
The Lover
The Lady
The Atronach
The Apprentice

]]

function HomeStationMarker.RegisterClientInteractListener()
    local self = HomeStationMarker
    Debug("RegisterClientInteractListener")
    EVENT_MANAGER:RegisterForEvent(self.name
        , EVENT_CLIENT_INTERACT_RESULT
        , HomeStationMarker.OnClientInteractResult
        )
end

function HomeStationMarker.UnregisterClientInteractListener()
    Debug("UnregisterClientInteractListener")
    local self = HomeStationMarker
    EVENT_MANAGER:UnregisterForEvent(self.name
        , EVENT_CLIENT_INTERACT_RESULT)
end

local ast = HomeStationMarker.SET_ID_ASSISTANTS
local mun = HomeStationMarker.SET_ID_MUNDUS
local sid = HomeStationMarker.STATION_ID

HomeStationMarker.INTERACT_TARGET_TO_SET_STATION = {
    ["BANKER"     ] = { set_id = ast, station_id = sid.BANKER             }
,   ["MERCHANT"   ] = { set_id = ast, station_id = sid.MERCHANT           }
,   ["FENCE"      ] = { set_id = ast, station_id = sid.FENCE              }
,   ["APPRENTICE" ] = { set_id = mun, station_id = sid.MUNDUS_APPRENTICE  }
,   ["ATRONACH"   ] = { set_id = mun, station_id = sid.MUNDUS_ATRONACH    }
,   ["LADY"       ] = { set_id = mun, station_id = sid.MUNDUS_LADY        }
,   ["LORD"       ] = { set_id = mun, station_id = sid.MUNDUS_LORD        }
,   ["LOVER"      ] = { set_id = mun, station_id = sid.MUNDUS_LOVER       }
,   ["MAGE"       ] = { set_id = mun, station_id = sid.MUNDUS_MAGE        }
,   ["RITUAL"     ] = { set_id = mun, station_id = sid.MUNDUS_RITUAL      }
,   ["SERPENT"    ] = { set_id = mun, station_id = sid.MUNDUS_SERPENT     }
,   ["SHADOW"     ] = { set_id = mun, station_id = sid.MUNDUS_SHADOW      }
,   ["STEED"      ] = { set_id = mun, station_id = sid.MUNDUS_STEED       }
,   ["THIEF"      ] = { set_id = mun, station_id = sid.MUNDUS_THIEF       }
,   ["TOWER"      ] = { set_id = mun, station_id = sid.MUNDUS_TOWER       }
,   ["WARRIOR"    ] = { set_id = mun, station_id = sid.MUNDUS_WARRIOR     }
}
ast = nil
mun = nil
sid = nil

function HomeStationMarker.OnClientInteractResult(event, result, target_name)
    local self = HomeStationMarker
    local key  = self.InteractTargetToKey(target_name)
    Debug( "OnClientInteractResult: result:%s target:%s key:%s"
         , tostring(result)
         , tostring(target_name)
         , tostring(key)
         )
    if not key then return end
    local s = self.INTERACT_TARGET_TO_SET_STATION[key]
    if not s then return end
    local house_key        = self.CurrentHouseKey()
    local station_pos      = self.CurrentStationLocation()
    station_pos.provenance = self.LOCATION_FROM.INTERACT
    self.RecordStationLocation(house_key, s.station_id, s, station_pos)
end

function HomeStationMarker.InteractTargetToKey(target_name)
    local self = HomeStationMarker
    if not target_name then return nil end
    if not self.interact_target_to_key then
        local t    = {}
        local langInteract = self.LANG[self.clientlang]["interact"]
        for k,v in pairs(langInteract) do
            t[v] = k
        end
        self.interact_target_to_key = t
    end
    local tn = zo_strformat("<<1>>", target_name)
-- Debug(tn) -- nur zum Debuggen
    local key = self.interact_target_to_key[tn]

    if key then
                        -- Convert second-or-later assistants
                        -- Ezabi "BANKER.2" and Fezez "MERCHANT.2"
                        -- to their keys "BANKER" or "MERCHANT"
        key = key:gsub(".%d+","")
    end
    return key
end

function HomeStationMarker.RegisterDyeInteractListener()
    local self = HomeStationMarker
    Debug("RegisterDyeInteractListener")
    EVENT_MANAGER:RegisterForEvent(self.name
        , EVENT_DYEING_STATION_INTERACT_START
        , HomeStationMarker.OnDyeInteractResult
        )
end

function HomeStationMarker.UnregisterDyeInteractListener()
    Debug("UnregisterDyeInteractListener")
    local self = HomeStationMarker
    EVENT_MANAGER:UnregisterForEvent(self.name
        , EVENT_DYEING_STATION_INTERACT_START)
end

function HomeStationMarker.OnDyeInteractResult()
    Debug("OnDyeInteractResult")
    local self = HomeStationMarker
    local house_key        = self.CurrentHouseKey()
    local station_pos      = self.CurrentStationLocation()
    station_pos.provenance = self.LOCATION_FROM.INTERACT
    self.RecordStationLocation(house_key, self.STATION_ID.OUTFITTER
                              , { set_id = self.SET_ID_MISC }
                              , station_pos
                              )
end

function HomeStationMarker.RegisterTransmuteInteractListener()
    local self = HomeStationMarker
    Debug("RegisterTransmuteInteractListener")
    EVENT_MANAGER:RegisterForEvent(self.name
        , EVENT_RETRAIT_STATION_INTERACT_START
        , HomeStationMarker.OnTransmuteInteractResult
        )
end

function HomeStationMarker.UnregisterTransmuteInteractListener()
    Debug("UnregisterTransmuteInteractListener")
    local self = HomeStationMarker
    EVENT_MANAGER:UnregisterForEvent(self.name
        , EVENT_RETRAIT_STATION_INTERACT_START)
end

function HomeStationMarker.OnTransmuteInteractResult()
    Debug("OnTransmuteInteractResult")
    local self = HomeStationMarker
    local house_key        = self.CurrentHouseKey()
    local station_pos      = self.CurrentStationLocation()
    station_pos.provenance = self.LOCATION_FROM.INTERACT
    self.RecordStationLocation(house_key, self.STATION_ID.TRANSMUTE
                              , { set_id = self.SET_ID_MISC }
                              , station_pos
                              )
end


-- Scene Listener ------------------------------------------------------------
--
-- Hide/Show 3D Mark Controls when starting an interaction, inventory, bank,
-- or other scene.
-- Inspired by Manavortex's Inventory Insight IIfA:RegisterForSceneChanges()
--
HomeStationMarker.SCENES = {
    ["hudui"] = {}
,   ["hud"  ] = {}
}
function HomeStationMarker.RegisterSceneListener()
    local self = HomeStationMarker
    for scene_name, fn_list in pairs(self.SCENES) do
        local scene = SCENE_MANAGER:GetScene(scene_name)
        if scene then
            local fn = function(...)
                        HomeStationMarker.OnSceneChange(scene_name, ...)
                    end
            fn_list.fn = fn
            Debug("RegisterSceneListener %s", scene_name)
            scene:RegisterCallback("StateChange", fn)
        else
            Debug("RegisterSceneListener skipped")
        end
    end
end

function HomeStationMarker.UnregisterSceneListener()
    local self = HomeStationMarker
    for scene_name, fn_list in pairs(self.SCENES) do
        local scene = SCENE_MANAGER:GetScene(scene_name)
        if scene and fn_list.fn then
            Debug("UnregisterSceneListener %s", scene_name)
            scene:UnregisterCallback("StateChange", fn_list.fn)
            fn_list.fn = nil
        else
            Debug("UnregisterSceneListener skipped")
        end
    end
end

function HomeStationMarker.OnSceneChange(scene_name, old_state, new_state)
    -- NOISY!
    -- Debug("OnSceneChange scene_name:%s old_state:%s new_state:%s"
    --      , tostring(scene_name)
    --      , tostring(old_state)
    --      , tostring(new_state)
    --      )
    if SCENE_SHOWN == new_state then
        -- Debug("OnSceneChange showing 3D MarkControls")
        HomeStationMarker_TopLevel:SetHidden(false)
    elseif SCENE_HIDDEN == new_state then
        -- Debug("OnSceneChange hiding 3D MarkControls")
        HomeStationMarker_TopLevel:SetHidden(true)
    end
end

function HomeStationMarker.IsHUDVisible()
    local self = HomeStationMarker
    for scene_name, fn_list in pairs(self.SCENES) do
        if SCENE_MANAGER:IsShowing(scene_name) then
            return true
        end
    end
    return false
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
                        --
                        -- Remarkably stable! Regardless of how I walk up to a
                        -- station, whether from front, side, or back, I get
                        -- the same 3D coords for CurrentPlayerLocation().
    local pos = HomeStationMarker.CurrentPlayerLocation()
    pos.orientation = GetPlayerCameraHeading()
    return pos
end

function HomeStationMarker.AddGuiRenderCoords(world_coords)
    local x,y,z = WorldPositionToGuiRender3DPosition( world_coords.world_x
                                                    , world_coords.world_y
                                                    , world_coords.world_z
                                                    )
    world_coords.gui_x = x
    world_coords.gui_y = y
    world_coords.gui_z = z
    return world_coords
end

-- Offsets to position the 3D MarkControl above its station.
--
-- Y offset raises MarkControl above station.
--

-- X/Z offsets are based on the camera orientation recorded when the player
-- interacted with the station. In theory, the station would be about 1 meter
-- in front of the player, so a little sine/cosine trigonometry and you've
-- found the X/Z center of the crafting station.
--
-- But that's not what I see when I do that. Any offset I use that works well
-- for North/South-facing stations seems to be terrible for East/West-facing
-- stations, plopping markers down in the middle of the hallway, or far behind
-- the station. Is this due to the camera pan for the first 5+ seconds after
-- interacting with a station?
--
-- Zeroing out X/Z offsets and giving up for now. If I pick this up again,
-- I should plop down 8-12 sets of stations in circles in the ColdHarbour
-- home and test there.
--
local pi  = math.pi -- for less typing
local sid = HomeStationMarker.STATION_ID
HomeStationMarker.STATION_OFFSET = {
    [CRAFTING_TYPE_BLACKSMITHING   or 1] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_CLOTHIER        or 2] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_WOODWORKING     or 6] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_JEWELRYCRAFTING or 7] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_ENCHANTING      or 3] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_ALCHEMY         or 4] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_PROVISIONING    or 5] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.BANKER                        ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MERCHANT                      ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.FENCE                         ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.TRANSMUTE                     ] = { y = 4, a = 0.0*pi, r = 0.0 }
,   [sid.OUTFITTER                     ] = { y = 4, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_APPRENTICE             ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_ATRONACH               ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_LADY                   ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_LORD                   ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_LOVER                  ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_MAGE                   ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_RITUAL                 ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_SERPENT                ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_SHADOW                 ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_STEED                  ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_THIEF                  ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_TOWER                  ] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [sid.MUNDUS_WARRIOR                ] = { y = 3, a = 0.0*pi, r = 0.0 }

}
pi = nil
sid = nil

function HomeStationMarker.OffsetGuiRenderCoords(coords, station_id)
    local self = HomeStationMarker
    local off  = HomeStationMarker.STATION_OFFSET[station_id]
    if not off then return coords end
    coords.gui_y = (coords.gui_y or 0) +  (off.y or 0)

    if coords.orientation and off.a and off.r then
        local theta = coords.orientation + off.a
        local z     = math.sin(theta) * (off.r)
        local x     = math.cos(theta) * (off.r)
        coords.gui_x = coords.gui_x + x
        coords.gui_z = coords.gui_z + z
    end

    return coords
end

-- Requested Marks -----------------------------------------------------------
--
-- saved_vars.requested_mark is a list of stations that we'd like to mark if
-- we can.
--
-- Just a collection of <set_id + station_id> 2-tuples.
-- No house or 3D control data here.
--
-- Requesting/unrequesting a mark here does NOT automatically show/hide any
-- corresponding 3D control! A higher-level function should call MarkControl
-- functions to show/hide 3D controls.

function HomeStationMarker.RequestMark(args)
    local self    = HomeStationMarker
    local found_i = self.FindRequestedMarkIndex(args)
    if found_i then
        Error( "RequestMark: requested mark already exists for set_id:%s station_id:%s found_i:%d"
             , tostring(args.set_id)
             , tostring(args.station_id)
             , found_i)
        return nil
    end
    Debug("RequestMark: set:%s station:%s"
            , tostring(args.set_id)
            , tostring(args.station_id)
            )
    local mark_val = self.RequestedMarkValue(args)
    table.insert(self.saved_vars.requested_mark, mark_val)
    return true
end

function HomeStationMarker.UnrequestMark(args)
    local self    = HomeStationMarker
    local found_i = self.FindRequestedMarkIndex(args)
    if not found_i then
        Error( "UnrequestMark: no requested mark found for set_id:%s station_id:%s"
             , tostring(args.set_id)
             , tostring(args.station_id)
             )
        return nil
    end
    Debug("UnrequestMark: set:%s station:%s found_i:%s"
            , tostring(args.set_id)
            , tostring(args.station_id)
            , tostring(found_i)
            )
    table.remove(self.saved_vars.requested_mark, found_i)
    return true
end

function HomeStationMarker.FindRequestedMarkIndex(args)
    local self = HomeStationMarker
    local mark_val     = HomeStationMarker.RequestedMarkValue(args)
    self.saved_vars.requested_mark = self.saved_vars.requested_mark or {}
    for i,sk in ipairs(self.saved_vars.requested_mark) do
        if sk == mark_val then
            return i
        end
    end
    return nil
end

-- A value in saved_vars.requested_mark
function HomeStationMarker.RequestedMarkValue(args)
    local function tostr(x)
        if not x then return "" else return tostring(x) end
    end
    return string.format("%s\t%s"
            , tostr(args.set_id)
            , tostr(args.station_id)
            )
end

function HomeStationMarker.FromRequestedMarkValue(mark_val)
    local w = HomeStationMarker.split(mark_val, "\t")
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

-- 3D Marker Controls --------------------------------------------------------

function HomeStationMarker.ShowAllMarkControls()
    Debug("ShowAllMarkControls")
    local self      = HomeStationMarker
    HomeStationMarker_TopLevel:SetHidden(false)
    self.saved_vars.requested_mark = self.saved_vars.requested_mark or {}
    self.curr_rotate_orientation = nil -- Reset cached rotation for periodic.
    for _,v in ipairs(self.saved_vars.requested_mark) do
        local r = self.FromRequestedMarkValue(v)
        self.ShowMarkControl(r.set_id, r.station_id)
    end
end

function HomeStationMarker.ShowMarkControl(set_id, station_id)
    local self      = HomeStationMarker
    local house_key = self.CurrentHouseKey()
    if not house_key then
        Debug("ShowMarkControl: Ignored. Not in player housing.")
        return nil
    end

    if self.IsHUDVisible() then
                        -- Usually we want to force our TopLevel container to
                        -- be visible when showing MarkControls. But if
                        -- somebody requests a marker while currently showing
                        -- inventory or some other scene, don't force TopLevel
                        -- visible: you'll end up showing all our markers on
                        -- top of the inventory screen and that is ugly.
        HomeStationMarker_TopLevel:SetHidden(false)
    end
    if self.MCPoolFind(set_id, station_id) then
        Debug( "ShowMarkControl: set_id:%s station_id:%s ignored. Already showing."
             , tostring(set_id)
             , tostring(station_id)
             )
        return nil
    end
                        -- Where?
    local coords    = self.FindStationLocation(house_key, set_id, station_id)
    if not coords then
        Debug( "ShowMarkControl: set_id:%s station_id:%s ignored. No known coords."
             , tostring(set_id)
             , tostring(station_id)
             )
        return nil
    end
    Debug( "ShowMarkControl: set_id:%s station_id:%s xyz:%6.6d %6.6d %6.6d"
         , tostring(set_id)
         , tostring(station_id)
         , coords.world_x
         , coords.world_y
         , coords.world_z
         )

    self.CreateMarkControl(set_id, station_id, coords)
    self.InvalidateRotateCache()
    return true
end

function HomeStationMarker.HideAllMarkControls()
    Debug("HideAllMarkControls")
    local self      = HomeStationMarker
    HomeStationMarker_TopLevel:SetHidden(true)
    if self.mark_control_pool then
        self.mark_control_pool:ReleaseAllObjects()
    end
end

function HomeStationMarker.HideMarkControl(set_id, station_id)
    local self = HomeStationMarker
    self.ReleaseMarkControl(set_id, station_id)
end

function HomeStationMarker.CreateMarkControl(set_id, station_id, coords)
    local self = HomeStationMarker
    local c = self.AcquireMarkControl(set_id, station_id)
    c:Create3DRenderSpace()
    c:SetTexture(self.STATION_TEXTURE[station_id])
    c:Set3DLocalDimensions(1.0, 1.0)
    c:SetColor(1.0, 1.0, 1.0, 1.0)
    c:SetHidden(false)
    self.AddGuiRenderCoords(coords)
    self.OffsetGuiRenderCoords(coords, station_id)
    c:Set3DRenderSpaceOrigin(coords.gui_x, coords.gui_y, coords.gui_z)
end

-- A unique-for-this-marker key used to identify a control in a ZO_ObjectPool.
function HomeStationMarker.MCKey(set_id, station_id)
                        -- We already have a key-like string generator
                        -- used for saved_vars.requested_mark values.
    return HomeStationMarker.RequestedMarkValue({ set_id     = set_id
                                       , station_id = station_id
                                       })
end

function HomeStationMarker.TopLevelControl()
    local self = HomeStationMarker
    if not self.top_level then
        HomeStationMarker_TopLevel:Set3DRenderSpaceOrigin(0, 0, 0)
        self.top_level = HomeStationMarker_TopLevel
    end
    return self.top_level
end

-- Return next available MarkControl, or create a new one if there are no
-- available ones.
function HomeStationMarker.AcquireMarkControl(set_id, station_id)
    local self = HomeStationMarker
    if not self.mark_control_pool then
        self.mark_control_pool = ZO_ObjectPool:New( self.MCPoolFactory
                                                  , self.MCPoolRelease )
    end
    local mckey = self.MCKey(set_id, station_id)
    local mc    = self.mark_control_pool:AcquireObject(mckey)
    -- self.MCPoolDump()
    return mc
end

function HomeStationMarker.ReleaseMarkControl(set_id, station_id)
    local self = HomeStationMarker
    local mckey = self.MCKey(set_id, station_id)
    if self.mark_control_pool then
        self.mark_control_pool:ReleaseObject(mckey)
        -- self.MCPoolDump()
    end
end

function HomeStationMarker.MCPoolFactory(pool)
    local self = HomeStationMarker
    Debug("MCPoolFactory")
    return ZO_ObjectPool_CreateControl( self.name .. "_MC"
                                      , pool
                                      , HomeStationMarker.TopLevelControl()
                                      )
end

function HomeStationMarker.MCPoolRelease(control)
    Debug("MCPoolRelease")
    control:SetHidden(true)
end

function HomeStationMarker.MCPoolFind(set_id, station_id)
    local self = HomeStationMarker
    if not self.mark_control_pool then return nil end
    local mckey = self.MCKey(set_id, station_id)
    return self.mark_control_pool:GetExistingObject(mckey)
end

function HomeStationMarker.MCPoolDump()
    local mcp = HomeStationMarker.mark_control_pool
    if not mcp then return end
    local total_ct  = mcp:GetTotalObjectCount()
    local active_ct = mcp:GetActiveObjectCount()
    local free_ct   = mcp:GetFreeObjectCount()
    Debug( "mcpool total:%d active:%d free:%d"
         , total_ct
         , active_ct
         , free_ct
         )
    if 0 < active_ct then
        for k,v in pairs(mcp:GetActiveObjects()) do
            Debug("mcpool %s", tostring(k))
        end
    end

end

-- Rotate 3D MarkControls ----------------------------------------------------
--
-- Rotate all 3D MarkControls to face the camera so that you don't see the
-- textures edge-on and you can recognize the texture from far away.

function HomeStationMarker.RotateAllMarkControls()
    local self = HomeStationMarker
    if self.mark_control_pool then
        local orientation = GetPlayerCameraHeading()
                        -- +++ Cache current orientation, and don't waste
                        -- CPU time re-rotating markers to their current
                        -- orientation.
        if self.curr_rotate_orientation == orientation then return end
        local active      = self.mark_control_pool:GetActiveObjects()
        for key, mark_control in pairs(active) do
            mark_control:Set3DRenderSpaceOrientation(0, orientation, 0)
        end
        self.curr_rotate_orientation = orientation
    end
end

function HomeStationMarker.InvalidateRotateCache()
    local self = HomeStationMarker
    self.curr_rotate_orientation = nil
end

function HomeStationMarker.StartPeriodicRotate()
    local self = HomeStationMarker
    Debug("StartPeriodicRotate")
    if not self.periodic_rotate then
        self.periodic_rotate = true
        self.PeriodicRotate()
    end
end

function HomeStationMarker.StopPeriodicRotate()
    Debug("StopPeriodicRotate")
    HomeStationMarker.periodic_rotate = false
end

function HomeStationMarker.PeriodicRotate()
    -- Debug("PeriodicRotate") -- Noisy!
    local self = HomeStationMarker
    if self.periodic_rotate then
        self.RotateAllMarkControls()

                        -- 250ms is a bit too slow: you can see the 3D
                        -- MarkControls rotate as you spin your camera around.
                        -- 125ms is soother, that'll do. I don't want to run
                        -- this too frequently and waste CPU time. Add-on CPU
                        -- time gets hammered and FPS drops so brutally during
                        -- crafting sessions due to all the inventory and craft
                        -- result listeners in so many add-ons that I'm loathe
                        -- to add any more while in a crafting house.
        zo_callLater(self.PeriodicRotate, 125)
    end
end

-- Furniture -----------------------------------------------------------------

function HomeStationMarker.FurnitureToInfo(furniture_id)
    local self = HomeStationMarker
    if not furniture_id then return nil end
    -- .station_id
    -- .set_info.set_id
    -- .set_info.set_name
    -- .station_pos.world_x y z orientation

    local o = {}
    local r = { GetPlacedHousingFurnitureInfo(furniture_id) }
    o.item_name             = r[1]
    o.texture_name          = r[2]
    o.furniture_data_id     = r[3]
    local furniture_data_id = r[3]
    o.quality           = GetPlacedHousingFurnitureQuality(furniture_id)
    o.link              = GetPlacedFurnitureLink(
                                furniture_id, LINK_STYLE_DEFAULT)
    o.collectible_id    = GetCollectibleIdFromFurnitureId(furniture_id)
    o.unique_id         = GetItemUniqueIdFromFurnitureId(furniture_id)
    r = { HousingEditorGetFurnitureWorldPosition(furniture_id) }
    o.station_pos = {}
    o.station_pos.world_x = r[1]
    o.station_pos.world_y = r[2]
    o.station_pos.world_z = r[3]
    r = { HousingEditorGetFurnitureOrientation(furniture_id) }
    o.station_pos.orientation = r[2]
    r = { GetFurnitureDataCategoryInfo(furniture_data_id) }
    o.category_id = r[1]
    o.subcategory_id = r[2]

    if o.category_id == 25 and self.debug_scan
        -- or string.find(o.item_name, "Provision")
        then -- category_id for crafting stations, mundus stones, assistants, others.
        local row = { tostring(o.item_name)
                    , tostring(o.category_id)
                    , tostring(o.subcategory_id)
                    , tostring(o.link)
                    , tostring(o.texture_name)
                    }
        local line = table.concat(row, "\t")
        Debug(line)
    end

    if not o.texture_name then return nil end
    local tinfo = HomeStationMarker.FURNITURE_TEXTURE_INFO[o.texture_name]
    if not tinfo then return nil end

    o.station_id = tinfo.station_id
    o.set_info   = {}
    if tinfo.set_id then
        o.set_info.set_id = tinfo.set_id
    else
        o.set_info.set_id = self.StationNameToSetID(o.item_name)
        if o.set_info.set_id then
            o.set_info.set_name = self.LibSets().GetSetName(o.set_info.set_id)
        else
            o.set_info_set_id = self.SET_ID_NONE
        end
    end
    return o
end

-- Hardcoded list of known furniture textures and the set/station they map to.
-- There's no reliable programmatic way to query a furniture for set/station
-- identifiers. There's also no reliable programmatic way to extract attuned
-- station set bonuses. Have to string match for those.

local nos = HomeStationMarker.SET_ID_NONE
local mis = HomeStationMarker.SET_ID_MISC
local ast = HomeStationMarker.SET_ID_ASSISTANTS
local mun = HomeStationMarker.SET_ID_MUNDUS
local sid = HomeStationMarker.STATION_ID

HomeStationMarker.FURNITURE_TEXTURE_INFO = {
    ["/esoui/art/icons/assistant_banker_01.dds"                           ] = { set_id = ast, station_id = sid.BANKER                    }
,   ["/esoui/art/icons/assistant_fence_01.dds"                            ] = { set_id = ast, station_id = sid.FENCE                     }
,   ["/esoui/art/icons/assistant_vendor_01.dds"                           ] = { set_id = ast, station_id = sid.MERCHANT                  }
,   ["/esoui/art/icons/assistant_ezabibanker.dds"                         ] = { set_id = ast, station_id = sid.BANKER                    }
,   ["/esoui/art/icons/assistant_fezezmerchant.dds"                       ] = { set_id = ast, station_id = sid.MERCHANT                  }

,   ["/esoui/art/icons/housing_cwc_crf_housingretrait001.dds"             ] = { set_id = mis, station_id = sid.TRANSMUTE                 }
,   ["/esoui/art/icons/housing_gen_crf_transmogtable001.dds"              ] = { set_id = mis, station_id = sid.OUTFITTER                 }
,   ["/esoui/art/icons/housing_gen_crf_portabletabledye001.dds"           ] = { set_id = mis, station_id = sid.OUTFITTER                 }

    -- These textures match both attuned and non-attuned crafting stations.
,   ["/esoui/art/icons/housing_gen_crf_portableblacksmith001.dds"         ] = { set_id = nil, station_id = CRAFTING_TYPE_BLACKSMITHING   }
,   ["/esoui/art/icons/housing_gen_crf_portabletableleatherworking001.dds"] = { set_id = nil, station_id = CRAFTING_TYPE_CLOTHIER        }
,   ["/esoui/art/icons/housing_gen_crf_portabletablewoodworking001.dds"   ] = { set_id = nil, station_id = CRAFTING_TYPE_WOODWORKING     }
,   ["/esoui/art/icons/housing_gen_crf_portabletablejewelry001.dds"       ] = { set_id = nil, station_id = CRAFTING_TYPE_JEWELRYCRAFTING }

,   ["/esoui/art/icons/housing_gen_crf_portabletablealchemy001.dds"       ] = { set_id = nos, station_id = CRAFTING_TYPE_ALCHEMY         }
,   ["/esoui/art/icons/housing_gen_crf_portabletableenchanter001.dds"     ] = { set_id = nos, station_id = CRAFTING_TYPE_ENCHANTING      }
,   ["/esoui/art/icons/housing_gen_crf_portablecampfire001.dds"           ] = { set_id = nos, station_id = CRAFTING_TYPE_PROVISIONING    }

    -- Clockwork City, non-attuned versions
    -- There doesn't seem to be a clockwork jewelry station.
,   ["/esoui/art/icons/housing_cwc_crf_tableblacksmith001.dds"            ] = { set_id = nos, station_id = CRAFTING_TYPE_BLACKSMITHING   }
,   ["/esoui/art/icons/housing_cwc_crf_tableleatherworking001.dds"        ] = { set_id = nos, station_id = CRAFTING_TYPE_CLOTHIER        }
,   ["/esoui/art/icons/housing_cwc_crf_tablewoodworking001.dds"           ] = { set_id = nos, station_id = CRAFTING_TYPE_WOODWORKING     }
,   ["/esoui/art/icons/housing_cwc_crf_tablealchemycrafting001.dds"       ] = { set_id = nos, station_id = CRAFTING_TYPE_ALCHEMY         }
,   ["/esoui/art/icons/housing_cwc_crf_tableenchanter001.dds"             ] = { set_id = nos, station_id = CRAFTING_TYPE_ENCHANTING      }
,   ["/esoui/art/icons/housing_cwc_crf_provisioning001.dds"               ] = { set_id = nos, station_id = CRAFTING_TYPE_PROVISIONING    }

    -- new life/winter fest cook fire
,   ["/esoui/art/icons/housing_uni_inc_holidayhearthlogs001.dds"          ] = { set_id = nos, station_id = CRAFTING_TYPE_PROVISIONING    }

    -- witchest fest alchemy station
,   ["/esoui/art/icons/housing_uni_exc_reachhealingtotem001.dds"          ] = { set_id = nos, station_id = CRAFTING_TYPE_ALCHEMY         }

,   ["/esoui/art/icons/housing_gen_exc_mundusstoneapprentice001.dds"      ] = { set_id = mun, station_id = sid.MUNDUS_APPRENTICE         }
,   ["/esoui/art/icons/housing_gen_exc_mundusstoneatronach001.dds"        ] = { set_id = mun, station_id = sid.MUNDUS_ATRONACH           }
,   ["/esoui/art/icons/housing_gen_exc_mundusstonelady001.dds"            ] = { set_id = mun, station_id = sid.MUNDUS_LADY               }
,   ["/esoui/art/icons/housing_gen_exc_mundusstonelord001.dds"            ] = { set_id = mun, station_id = sid.MUNDUS_LORD               }
,   ["/esoui/art/icons/housing_gen_exc_mundusstonelover001.dds"           ] = { set_id = mun, station_id = sid.MUNDUS_LOVER              }
,   ["/esoui/art/icons/housing_gen_exc_mundusstonemage001.dds"            ] = { set_id = mun, station_id = sid.MUNDUS_MAGE               }
,   ["/esoui/art/icons/housing_gen_exc_mundusstoneritual001.dds"          ] = { set_id = mun, station_id = sid.MUNDUS_RITUAL             }
,   ["/esoui/art/icons/housing_gen_exc_mundusstoneserpent001.dds"         ] = { set_id = mun, station_id = sid.MUNDUS_SERPENT            }
,   ["/esoui/art/icons/housing_gen_exc_mundusstoneshadow001.dds"          ] = { set_id = mun, station_id = sid.MUNDUS_SHADOW             }
,   ["/esoui/art/icons/housing_gen_exc_mundusstonesteed001.dds"           ] = { set_id = mun, station_id = sid.MUNDUS_STEED              }
,   ["/esoui/art/icons/housing_gen_exc_mundusstonethief001.dds"           ] = { set_id = mun, station_id = sid.MUNDUS_THIEF              }
,   ["/esoui/art/icons/housing_gen_exc_mundusstonetower001.dds"           ] = { set_id = mun, station_id = sid.MUNDUS_TOWER              }
,   ["/esoui/art/icons/housing_gen_exc_mundusstonewarrior001.dds"         ] = { set_id = mun, station_id = sid.MUNDUS_WARRIOR            }

    -- Other furniture that appear in category 25 "Services" but which
    -- HomeStationMarker does not touch.

,   ["/esoui/art/icons/housing_targetdummy_humanoid_01.dds"               ] = nil
,   ["/esoui/art/icons/housing_targetdummy_robusthumanoid_01.dds"         ] = nil
,   ["/esoui/art/icons/targetdummy_theprecursor.dds"                      ] = nil

,   ["/esoui/art/icons/housing_uni_inc_musicboxaldmeri001.dds"            ] = nil
,   ["/esoui/art/icons/housing_uni_inc_musicboxdaggerfall001.dds"         ] = nil
,   ["/esoui/art/icons/housing_uni_inc_musicboxebonhart001.dds"           ] = nil
,   ["/esoui/art/icons/housing_uni_inc_musicboxeso001.dds"                ] = nil

,   ["/esoui/art/icons/housing_gen_con_housingchest003.dds"               ] = nil -- storage chest
,   ["/esoui/art/icons/housing_gen_con_housingchest004.dds"               ] = nil -- storage coffer

}

nos = nil
mis = nil
ast = nil
mun = nil
sid = nil

function HomeStationMarker.StationNameToSetID(item_name)
    local self = HomeStationMarker
    local simpler_name = self.SimplifyString(item_name)
    local snt  = self.SetNameTable()
    for _,row in ipairs(snt) do
        if string.find(simpler_name, row.set_name) then
            return row.set_id
        end
    end
    Debug("StationNameToSetID: no match for '%s'", item_name)
    return nil
end

-- RefCounts -----------------------------------------------------------------

function HomeStationMarker.IncrementRefCount(set_id, station_id)
    local self = HomeStationMarker
    local key  = self.MCKey(set_id, station_id)
    self.saved_vars.requested_mark_refcounts
        = self.saved_vars.requested_mark_refcounts or {}
    local rc = self.saved_vars.requested_mark_refcounts -- for less typing
    rc[key] = (rc[key] or 0) + 1
    return rc[key]
end

function HomeStationMarker.DecrementRefCount(set_id, station_id)
    local self = HomeStationMarker
    local key  = self.MCKey(set_id, station_id)
    self.saved_vars.requested_mark_refcounts
        = self.saved_vars.requested_mark_refcounts or {}
    local rc = self.saved_vars.requested_mark_refcounts -- for less typing
    rc[key] = math.max(1, rc[key] or 1) - 1
    return rc[key]
end

function HomeStationMarker.ResetAllRefCounts()
    local self = HomeStationMarker
    self.saved_vars.requested_mark_refcounts = {}
end

-- Saved Variables -----------------------------------------------------------

-- HomeStationMarker used to store all locations in a single account-wide
-- table. That's not going to work if the same user has the same house on
-- two different servers (NA + EU). Need to track station_location and
-- refcounts separately for each server.
--
-- This is a one-time migrator that moves saved table entries from the
-- account-wide no-server-knowledge table to a per-server table. In the
-- rare case that this isn't what you want, uh, /hsm forgetlocs_all.
--
function HomeStationMarker.MigrateSavedVariables()
    self = HomeStationMarker
    local old_saved_vars = ZO_SavedVars:NewAccountWide(
                              self.name .. "Vars"
                            , self.saved_var_version
                            , nil
                            , self.default
                            )
    if not old_saved_vars.station_location then return end

    local kk = { "requested_mark"
               , "requested_mark_refcounts"
               , "station_location"
               }
    for _,k in ipairs(kk) do
        if not self.saved_vars[k] then
            self.saved_vars[k] = old_saved_vars[k]
            old_saved_vars[k] = nil
            -- self.Debug("HomeStationMarker: migrated saved variable %s", tostring(k))
        end
    end

    self.Info("HomeStationMarker: migrated saved variables.")
end

function HomeStationMarker.ServerName()
    local self = HomeStationMarker
    if not self.server_name then
        self.clientlang = GetCVar("language.2") or "en"
        self.server_name = "NA"
        local plat = GetCVar("LastPlatform") -- ""
        if (plat == "Live-EU") then
            self.server_name = "EU"
        end
    end
    return self.server_name
end

-- Init ----------------------------------------------------------------------

function HomeStationMarker.OnAddOnLoaded(event, addonName)
    local self = HomeStationMarker
    if addonName ~= self.name then return end

    self.inited     = true
    self.saved_vars = ZO_SavedVars:NewAccountWide(
                              self.name .. "Vars"
                            , self.saved_var_version
                            , self.ServerName()
                            , self.default
                            )
    self.MigrateSavedVariables()

    -- self.RegisterCraftListener()
    self.RegisterSlashCommands()
end


EVENT_MANAGER:RegisterForEvent( HomeStationMarker.name
                              , EVENT_ADD_ON_LOADED
                              , HomeStationMarker.OnAddOnLoaded
                              )

EVENT_MANAGER:RegisterForEvent( HomeStationMarker.name
                              , EVENT_PLAYER_ACTIVATED
                              , HomeStationMarker.OnPlayerActivated
                              )
