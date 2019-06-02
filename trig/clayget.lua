--[[
Convert ZZCraftoriumLayout saved_vars file into a tab-delimited table
of station positions and orientations.

ZZCraftoriumLayout saved_vars contain an accurate record of each crafting
table in PC NA @ziggr's Grand Linchal Manor. This should provide enough
data to know how to offset `GetUnitWorldPosition("player")` values from
where the player is to where the 3D MarkControl should go.

ZZCraftoriumLayout orientation data _might_ be accurate. But I've seen a
few values (Morkuldin) that seem incorrect. This might match orientation bugs
we've seen in-game where one player sees a station rotated correctly, but
another player in the same house at the same time sees the station rotated
backwards: "Hey your clothing station is backwards." "Looks correct to me."
--]]

dofile("data/ZZCraftoriumLayout.lua")
flat = ZZCraftoriumLayoutVars["Default"]["@ziggr"]["$AccountWide"]["get_flat"]

local RE = "^%d+  (%d+)  (%d+)  (%d+) ([%-%d+%.]+) ([^%()]+) %(([^%)]+)"

local function deg2rad(deg)
    return (deg / 180 * math.pi + 2*math.pi) % 2*math.pi
end

local STATION_ID = {
    ["Blacksmithing Station"    ] = 1
,   ["Clothing Station"         ] = 2
,   ["Woodworking Station"      ] = 6
,   ["Jewelry Crafting Station" ] = 7
}
local db = {}


for _,line in ipairs(flat) do
    if line:find("Station") then
        local w = {line:find(RE)}

        if w then
            local r = {}
            table.insert(r, w[3] ) -- x
            table.insert(r, w[4] ) -- z
            table.insert(r, w[5] ) -- y
            table.insert(r, w[6] ) -- ori_deg
            table.insert(r, deg2rad(w[6])) --  ori_rad
            table.insert(r, w[7] ) -- station
            table.insert(r, w[8] ) -- set

            local s = table.concat(r, "\t")
            local set = w[8]
            local station_name = w[7]
            local station_id   = STATION_ID[station_name]

            if set and station_id then
                db[set] = db[set] or {}
                db[set][station_id] = s
            end
        end
    end
end

set_list = {}
for set,_ in pairs(db) do
    table.insert(set_list, set)
end
table.sort(set_list)

for _,set in ipairs(set_list) do
    for _,station_id in ipairs({1,2,6,7}) do
        if db[set][station_id] then
            print(db[set][station_id])
        end
    end
end

