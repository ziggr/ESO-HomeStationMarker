
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
end
