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
HomeStationMarker.SET_ID_TRANSMUTE  = "transmute"       -- not implemented
HomeStationMarker.SET_ID_ASSISTANTS = "assistants"      -- not implemented
HomeStationMarker.SET_ID_MUNDUS     = "mundus"          -- not implemented

-- API -----------------------------------------------------------------------

-- Request a marker above a station.
--
-- returns true if request added, nil if not.
--
-- Requested station will be shown immediately if in a player house with that
-- station, and station location is already known to HomeStationMarker from
-- a previous player interaction with that station.
function HomeStationMarker.AddMarker(set_id, station_id)
    local self = HomeStationMarker
    Debug( "AddMarker set_id:%s station_id:%s"
         , tostring(set_id)
         , tostring(station_id)
         )
    assert(station_id)
    local requested =  self.RequestMark(
                                { set_id     = set_id
                                , station_id = station_id
                                })
    if requested then
        self.ShowMarkControl(set_id, station_id)
    end
    return requested
end

function HomeStationMarker.DeleteMarker(set_id, station_id)
    local self = HomeStationMarker
    Debug( "DeleteMarker set_id:%s station_id:%s"
         , tostring(set_id)
         , tostring(station_id)
         )
    assert(station_id)
    local unrequested = self.UnrequestMark(
                                { set_id     = set_id
                                , station_id = station_id
                                })
    if unrequested then
        self.HideMarkControl(set_id, station_id)
    end
    return unrequested
end

function HomeStationMarker.DeleteAllMarkers()
    local self = HomeStationMarker
    Debug("DeleteAllMarkers")
    self.saved_vars.requested_mark = {}
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
--
-- * MarkControl
--   3D Controls that are the beacons that appear in 3D space.
--   Ideally, one of these for each station listed in "Marks", but often
--   fewer MarkControls if we don't know the station locations for each
--   set_id + station_id
--   ShowMarkControl() / HideMarkControl() / never saved_vars


-- Textures for the 3D MarkControl
HomeStationMarker.STATION_TEXTURE = {
    [CRAFTING_TYPE_BLACKSMITHING   or 1] = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_blacksmithing_down.dds"
,   [CRAFTING_TYPE_CLOTHIER        or 2] = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_clothing_down.dds"
,   [CRAFTING_TYPE_ENCHANTING      or 3] = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_down.dds"
,   [CRAFTING_TYPE_ALCHEMY         or 4] = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_alchemy_down.dds"
,   [CRAFTING_TYPE_PROVISIONING    or 5] = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_provisioning_down.dds"
,   [CRAFTING_TYPE_WOODWORKING     or 6] = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_woodworking_down.dds"
,   [CRAFTING_TYPE_JEWELRYCRAFTING or 7] = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_jewelrycrafting_down.dds"
}

-- Slash Commands and Command-Line Interface UI ------------------------------

function HomeStationMarker.RegisterSlashCommands()
    local lsc = LibStub:GetLibrary("LibSlashCommander", true)
    if lsc then
        local cmd = lsc:Register( "/hsm"
                                , function(args) HomeStationMarker.SlashCommand(args) end
                                , "HomeStationMarker <set> <station>")

        local t = { {"forgetlocs"    , "Forget all station locations for current house, also deletes all markers for current house." }
                  , {"forgetlocs all", "Forget all station locations for all houses, also deletes all markers for all houses." }
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
        Info("Sccanning current house's station locations...")
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
    Error("ScanStationLocations: unimplemented")
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
    end
    local xyz_string = table.concat(xyz, "\t")
    return xyz_string
end

function HomeStationMarker.FromStationLocationString(s)
    assert(s)
    assert(s ~= "")
    local self = HomeStationMarker
    local w = self.split(s, "\t")
    assert(3 <= #w)
    local r = { world_x     = tonumber(w[1])
              , world_y     = tonumber(w[2])
              , world_z     = tonumber(w[3])
              , orientation = tonumber(w[4])
              }
    assert(r.world_x and r.world_y and r.world_z)
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
        self.ShowAllMarkControls()
        self.StartPeriodicRotate()
    else
        self.UnregisterCraftListener()
        self.UnregisterSceneListener()
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
    Debug("OnSceneChange scene_name:%s old_state:%s new_state:%s"
         , tostring(scene_name)
         , tostring(old_state)
         , tostring(new_state)
         )
    if SCENE_SHOWN == new_state then
        Debug("OnSceneChange showing 3D MarkControls")
        HomeStationMarker_TopLevel:SetHidden(false)
    elseif SCENE_HIDDEN == new_state then
        Debug("OnSceneChange hiding 3D MarkControls")
        HomeStationMarker_TopLevel:SetHidden(true)
    end
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
local pi = math.pi
HomeStationMarker.STATION_OFFSET = {
    [CRAFTING_TYPE_BLACKSMITHING   or 1] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_CLOTHIER        or 2] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_WOODWORKING     or 6] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_JEWELRYCRAFTING or 7] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_ENCHANTING      or 3] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_ALCHEMY         or 4] = { y = 3, a = 0.0*pi, r = 0.0 }
,   [CRAFTING_TYPE_PROVISIONING    or 5] = { y = 3, a = 0.0*pi, r = 0.0 }
}

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

    HomeStationMarker_TopLevel:SetHidden(false)
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
    c:Set3DLocalDimensions(1.4, 1.4)
    c:SetColor(1.0, 1.0, 1.0, 1.0)
    c:SetHidden(false)
    self.AddGuiRenderCoords(coords)
    self.OffsetGuiRenderCoords(coords, station_id)
d(coords)
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
    Debug("MCPoolFactory")
    return ZO_ObjectPool_CreateControl( "HomeStationMarker_MC"
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

