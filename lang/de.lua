HomeStationMarker.LANG = HomeStationMarker.LANG or {}
HomeStationMarker.LANG["de"] = {
  ["interact"] = {
    ["BANKER"     ] = "Tythis Andromo der Bankier"
  , ["BANKER.2"   ] = "Ezabi der Bankier"
  , ["MERCHANT"   ] = "Nuzhimeh die Händlerin"
  , ["MERCHANT.2" ] = "Fezez der Händler"
  , ["FENCE"      ] = "Pirharri der Schmuggler"

  , ["APPRENTICE" ] = "der Lehrling"
  , ["ATRONACH"   ] = "der Atronach"
  , ["LADY"       ] = "die Fürstin"
  , ["LORD"       ] = "der Fürst"
  , ["LOVER"      ] = "die Liebende"
  , ["MAGE"       ] = "die Magierin"
  , ["RITUAL"     ] = "das Ritual"
  , ["SERPENT"    ] = "die Schlange"
  , ["SHADOW"     ] = "der Schatten"
  , ["STEED"      ] = "das Schlachtross"
  , ["THIEF"      ] = "die Diebin"
  , ["TOWER"      ] = "der Turm"
  , ["WARRIOR"    ] = "der Krieger"
  },
  ["slash_commands"] = {
    ["SC_SET"                 ] = "Set"
  , ["SC_STATION"             ] = "Handwerksstation"
  , ["SC_SET_STATION"         ] = "%s <%s> <%s>"
  , ["SC_FORGET_LOCS"         ] = "Vergesse alle Positionen der Stationen und löscht die Markierungen im aktuellen Haus."
  , ["SC_FORGET_LOCS_CMD"     ] = "vergesse"
  , ["SC_FORGET_LOCS_ALL"     ] = "Vergesse alle Positionen der Stationen und löscht die Markierungen in ALLEN Häusern."
  , ["SC_FORGET_LOCS_ALL_CMD" ] = "vergesse_alle"
  , ["SC_SCAN_LOCS"           ] = "Scanne Einrichtung, um die Positionen der Stationen zu erlernen."
  , ["SC_SCAN_LOCS_CMD"       ] = "scanne"
  , ["SC_CLEAR_MARKS"         ] = "Remove all marks."
  , ["SC_CLEAR_MARKS_CMD"     ] = "clear"
  , ["SC_EXPORT"              ] = "Show export window."
  , ["SC_EXPORT_CMD"          ] = "export"
  , ["SC_IMPORT"              ] = "Show import window."
  , ["SC_IMPORT_CMD"          ] = "import"
  },

  ["export"] = {
    ["WINDOW_TITLE"       ]  = "HomeStationMarker Export"
  , ["WINDOW_TITLE_IMPORT"]  = "HomeStationMarker Import"
  , ["PREAMBLE"    ]  =           "# To share your home's station locations with other players,"
                      .. "\n" ..  "# 1. Copy this entire text with CTRL+A then CTRL+C."
                      .. "\n" ..  "# 2. Send to other players via Discord or some other way."
                      .. "\n" ..  "#    (ESO mail is limited to 700 characters, too small for"
                      .. "\n" ..  "#     HomeStationMarker locations.)"
                      .. "\n" ..  "#"
                      .. "\n" ..  "# To import station locations:"
                      .. "\n" ..  "# 1. Copy the entire text that was sent via Discord or elsewhere."
                      .. "\n" ..  "# 1. Type `/hsm import` into the chat window."
                      .. "\n" ..  "#    This opens the HomeStationMarker Import window."
                      .. "\n" ..  "# 2. Paste with CTRL+V."
                      .. "\n" ..  "#"
  , ["POSTAMBLE"   ]            = "# (end)"
  , ["ERR_NOT_IN_HOUSE"             ] = "Only works in player housing."
  , ["ERR_NO_STATION_LOCATIONS"     ] = "No station location for this house. Try `/hsm scanlocs`."
  , ["IMPORT_TEXT_DEFAULT"          ] = "# Paste text here with CTRL+V"
  , ["IMPORT_BUTTON"                ] = "Import"
  , ["IMPORT_VALUE_MISSING"         ] = "(missing)"
  , ["IMPORT_ERROR_SERVER_MISMATCH" ] = "(wrong server)"
  , ["IMPORT_LABEL_SERVER"          ] = "server"
  , ["IMPORT_LABEL_HOUSE"           ] = "house"
  , ["IMPORT_LABEL_OWNER"           ] = "owner"
  , ["IMPORT_LABEL_STATION_COUNT"   ] = "station count"
  }

}
