
HomeStationMarker.Export = {}


function HomeStationMarker_Export_ToggleUI()
    local h = HomeStationMarker_ExportUI:IsHidden()

    if h then
        HomeStationMarker.Export:RefreshSoon()
    end

    HomeStationMarker_ExportUI:SetHidden(not h)
end


function HomeStationMarker_Export_OnTextChanged(new_text)
end

function HomeStationMarker.Export:RefreshSoon()
    local text = HomeStationMarker.Export.ToText()

    local MYSTERY_LIMIT = 2818
    HomeStationMarker_Export_Edit:SetText(text:sub(1,MYSTERY_LIMIT))
end

function HomeStationMarker.Export.ToText()
    local self = HomeStationMarker
    local house_key = self.CurrentHouseKey()
    if not house_key then
        return "# Only works in player housing."
    end

    local sv_l = self.saved_vars.station_location
    if not sv_l[house_key] then
        return "# No station location for this house."
    end

    local station_location = sv_l[house_key]
    local text = HomeStationMarker.ExportStations(station_location)
    HomeStationMarker.ZZ = text
    HomeStationMarker.Debug("char count:%d", #text)
    return text
end

