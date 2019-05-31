-- HomeStationMarker
--
-- Draw 3D beacons above crafting stations in player housing.
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
HomeStationMarker.SET_ID_TRANSMUTE  = "transmute"
HomeStationMarker.SET_ID_ASSISTANTS = "assistants"
HomeStationMarker.SET_ID_MUNDUS     = "mundus"

-- Slash Commands and Command-Line Interface UI ------------------------------

function HomeStationMarker.RegisterSlashCommands()
    local lsc = LibStub:GetLibrary("LibSlashCommander", true)
    if lsc then
        local cmd = lsc:Register( "/hsm"
                                , function(args) HomeStationMarker.SlashCommand(args) end
                                , "HomeStationMarker <set> <station>")

        local t = { {"forgetlocs"    , "Forget all station locations for current house, also deletes all markers for current house." }
                  , {"forgetlocs all", "Forget all station locations for all houses, also deletes all markers for all houses." }
                  , {"clear"         , "Delete all markers for current house." }
                  , {"clear all"     , "Delete all markers for all houses." }
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

    if cmd:lower() == "clear" then
        if args and args:lower() == "all" then
            Info("Deleting all markers...")
            self.UnrequestMarks({all=true})
        else
            Info("Deleting current house's markers...")
            self.UnrequestMarks()
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
    local found_i = self.FindMarkIndex(args)
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
    local all_houses = args and args.all
    Error("ForgetStationLocations: unimplemented")
end

function HomeStationMarker.UnrequestMarks(args)
    local all_houses = args and args.all
    Error("UnrequestMarks: unimplemented")
end

function HomeStationMarker.Test()
    d("Testing!")
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

    Debug("RecordStationLocation: h:%s set_id:%-3.3s station_id:%s xyz:%-20.20s %s"
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
                   , station_pos.world_z }
    local xyz_string = table.concat(xyz, "\t")
    return xyz_string
end

function HomeStationMarker.FromStationLocationString(s)
    assert(s)
    assert(s ~= "")
    local self = HomeStationMarker
    local w = self.split(s, "\t")
    assert(3 <= #w)
    local r = { world_x = tonumber(w[1])
              , world_y = tonumber(w[2])
              , world_z = tonumber(w[3])
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
    return HomeStationMarker.CurrentPlayerLocation()
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

-- Marking Stations ----------------------------------------------------------
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
    local found_i = self.FindMarkIndex(args)
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
    local mark_val = self.MarkValue(args)
    table.insert(self.saved_vars.requested_mark, mark_val)
    return true
end

function HomeStationMarker.UnrequestMark(args)
    local self    = HomeStationMarker
    local found_i = self.FindMarkIndex(args)
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
end

function HomeStationMarker.FindMarkIndex(args)
    local self = HomeStationMarker
    local mark_val     = HomeStationMarker.MarkValue(args)
    self.saved_vars.requested_mark = self.saved_vars.requested_mark or {}
    for i,sk in ipairs(self.saved_vars.requested_mark) do
        if sk == mark_val then
            return i
        end
    end
    return nil
end

-- A value in saved_vars.requested_mark
function HomeStationMarker.MarkValue(args)
    local function tostr(x)
        if not x then return "" else return tostring(x) end
    end
    return string.format("%s\t%s"
            , tostr(args.set_id)
            , tostr(args.station_id)
            )
end

function HomeStationMarker.FromMarkValue(mark_val)
    local w = HomeStationMarker.split(mark_val)
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
function HomeStationMarker.ShowMarkControl(set_id, station_id)
    local self      = HomeStationMarker

                        -- ### if already showing, don't show a second one

                        -- Where?
    local house_key = self.CurrentHouseKey()
    if not house_key then
        Debug("ShowMarkControl: Ignored. Not in player housing.")
        return nil
    end
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

function HomeStationMarker.HideMarkControl(set_id, station_id)
    Error("HideMarkControl: unimplemented")
end

function HomeStationMarker.CreateMarkControl(set_id, station_id, coords)
    local self = HomeStationMarker
    local c = self.NewMarkControl()
    c:Create3DRenderSpace()
    c:SetTexture("esoui/art/inventory/inventory_tabicon_craftbag_blacksmithing_down.dds")
    c:Set3DLocalDimensions(1.4, 1.4)
    c:SetColor(1.0, 1.0, 1.0, 1.0)
    c:SetHidden(false)
    self.AddGuiRenderCoords(coords)
    c:Set3DRenderSpaceOrigin(coords.gui_x, coords.gui_y, coords.gui_z)
end

function HomeStationMarker.TopLevelControl()
    local self = HomeStationMarker
    if not self.top_level then
        HomeStationMarker_TopLevel:Set3DRenderSpaceOrigin(0, 0, 0)
        self.top_level = HomeStationMarker_TopLevel
    end
    return self.top_level
end

function HomeStationMarker.NewMarkControl()
    local self = HomeStationMarker
    self.mark_control_serial = (self.mark_control_serial or 0) + 1
    local top_level = HomeStationMarker.TopLevelControl()
    local c = top_level:CreateControl( string.format( "Marker_%03d"
                                                    , self.mark_control_serial )
                                     , CT_TEXTURE )

    Debug("CreateMarkControl returning:"..tostring(c))
    return c
end

function HomeStationMarker.ReleaseMarkControl(control)
    control:SetHidden(true)
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

