--[[
Given an X and Y value, what is the angle of a line segment from 0,0 to x,y?

Yeah yeah it's basically arc tangent. But arctan isn't all that: it can't
diffentiate between 45° and 135°, nor can it be passed an input when y=0. So
we need to check +/0/- for input X and Y, and if we're doing that we might
as well just use arc sine or arc cosine.
--]]

local function deg_to_rad(deg)
    return deg / 180 * math.pi
end
local function rad_to_deg(rad)
    return rad * 180 / math.pi
end

local function round(f)
    if f < 0 then
        return math.ceil(f)
    else
        return math.floor(f)
    end
end

-- Return the angle, in radians, for the line from 0,0 to x,y.
local function xy_to_angle(x, y)
    local hypot = math.sqrt(x^2+y^2)
    if hypot <= 0 then return 0 end
    local result = 0
    if 0 <= x then
        result = math.asin(y/hypot)
-- print(string.format("y:%5.2f hypot:%5.2f result:%5.2f",y,hypot,result))
    elseif 0 <= y then
        result = math.acos(x/hypot)
    else
        result = -math.acos(x/hypot)
    end
    return (result + 2*math.pi) % (2*math.pi)
end

for deg = 0,360,5 do
    local rad = deg_to_rad(deg)
    local x   = math.cos(rad)
    local y   = math.sin(rad)

    local result = xy_to_angle(x, y)
    local diff   = result - rad
    diff = round(diff * 100) / 100

    print(string.format("deg:%3d rad:%0.2f x:%5.2f y:%5.2f result:%0.2f diff:%5.2f"
                       , deg
                       , rad
                       , x
                       , y
                       , result
                       , diff
                       ))
end
