dofile("data/LibDebugLogger.lua")

HSM = "HomeStationMarker"

for i,row in ipairs(LibDebugLoggerLog) do
    if row[5] == HSM then
        print(row[4].." "..row[6])
    end
end
