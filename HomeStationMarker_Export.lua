
HomeStationMarker.Export = {}


function HomeStationMarker_Export_ToggleUI()
    local h = HomeStationMarker_ExportUI:IsHidden()

    if not HomeStationMarker.Export.editbox then
        HomeStationMarker.Export.editbox = HomeStationMarker.Export.CreateEditBox()

        local lang = self.LANG[self.clientlang]["export"] or self.LANG["en"]["export"]

        HomeStationMarker_ExportUIWindowTitle:SetText(lang.WINDOW_TITLE)
    end

    if h then
        HomeStationMarker.Export:RefreshSoon()
    end

    HomeStationMarker_ExportUI:SetHidden(not h)
end

function HomeStationMarker_Import_ToggleUI()
    local h = HomeStationMarker_ImportUI:IsHidden()

    if not HomeStationMarker.Export.editbox_import then
        HomeStationMarker.Export.editbox_import = HomeStationMarker_ImportUIEditBox

        local lang = self.LANG[self.clientlang]["export"] or self.LANG["en"]["export"]

        HomeStationMarker_ImportUIWindowTitle:SetText(lang.WINDOW_TITLE_IMPORT)
    end

    HomeStationMarker_ImportUI:SetHidden(not h)
end

-- Zig ran into problems with the edit box not displaying more than 2818
-- characters. Rather than deeply debug and understand what went wrong, it's
-- easier for Zig to just bypass XML and create the UI element(s)
-- programmatically.
--
-- Only to later discover that the editbox-creation code was fine all along,
-- but the text data itself, full of colon ':', pipe '|', and number '0123456789'
-- characters somehow trigger undesired display failures in ZOS code. I suspect
-- that I'm triggering some item_link detecctor, even when
-- editbox:SetAllowMarkupType(ALLOW_MARKUP_TYPE_NONE).
--
function HomeStationMarker.Export.CreateEditBox()
    local container = HomeStationMarker_ExportUI

    local backdrop = WINDOW_MANAGER:CreateControlFromVirtual( nil
                                                            , container
                                                            , "ZO_EditBackdrop"
                                                            )
    backdrop:SetAnchor(TOPLEFT,     container, TOPLEFT,      5, 50)
    backdrop:SetAnchor(BOTTOMRIGHT, container, BOTTOMRIGHT, -5, -5)

    local editbox = WINDOW_MANAGER:CreateControlFromVirtual(
          nil
        , backdrop
        , "ZO_DefaultEditMultiLineForBackdrop"
        )

    editbox:SetMaxInputChars(20000)

    local text = HomeStationMarker.Export.ToText()
    editbox:SetText(text)

                        -- Scroll to top. Doesn't work immediately, but
                        -- there's nothing that a SLEEP 10 can't fix!
    zo_callLater(function() editbox:SetCursorPosition(0) end, 10)

    return editbox
end

function HomeStationMarker_Import_OnTextChanged(new_text)
    HomeStationMarker.Debug("hi")
    ZO_EditDefaultText_OnTextChanged(HomeStationMarker_ImportUIEditBox)
end

function HomeStationMarker_Import_OnClicked()
    HomeStationMarker.Debug("click.")
end

function HomeStationMarker.Export:RefreshSoon()
    local text = HomeStationMarker.Export.ToText()
    -- local text = HomeStationMarker.Export.GenerateText(6000)

    HomeStationMarker.Export.editbox:SetText(text:sub(1,MYSTERY_LIMIT))
end

function HomeStationMarker.Export.ToText()
    local self = HomeStationMarker
    local lang = self.LANG[self.clientlang]["export"] or self.LANG["en"]["export"]

    local house_key = self.CurrentHouseKey()
    if not house_key then
        return "# " .. lang.ERR_NOT_IN_HOUSE
    end

    local sv_l = self.saved_vars.station_location
    if not sv_l[house_key] then
        return "# ".. lang.ERR_NO_STATION_LOCATION
    end

    local h = { "server:"   .. self.ServerName()
              , "owner:"    .. GetCurrentHouseOwner()
              , "house_id:" .. tostring(GetCurrentZoneHouseId())
              }
    local house_text = table.concat(h, "\n") .. "\n"

    local station_location  = sv_l[house_key]
    local station_text      = HomeStationMarker.ExportStations(station_location)

    local preamble          = lang.PREAMBLE
    local postamble         = lang.POSTAMBLE
    local text              = preamble
                            .. "\n\n" .. house_text
                            .. "\n"   .. station_text
                            .. "\n"   .. postamble
                            .. "\n"

    HomeStationMarker.ZZ = text
    HomeStationMarker.Debug("char count:%d", #text)
    return text
end

-- function HomeStationMarker.Export.GenerateText(char_ct)
--     local char_per_line = 100
--     local line_template = "%04d: 789 1234 6789 1234 6789 1234 6789 1234 6789 1234 6789 1234 6789 1234 6789 1234 6789 1234 6789 1234 6789 1234 6789 1234 6789 "
--     local line_template = string.sub(line_template,1,char_per_line-1).."\n"
--     local lines = {}
--     for char_i = 1,char_ct,char_per_line do
--         local line = string.format(line_template, char_i)
--         table.insert(lines,line)
--     end
--     return table.concat(lines,"")
-- end
