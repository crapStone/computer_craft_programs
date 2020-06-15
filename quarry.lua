local craplib = require("craplib")

local tArgs = {...}

-- handle cli arguments
if #tArgs > 2 or tArgs[1] == "help" then
    print()
    print("Usage: quarry [option] [diameter]")
    print("              [altitude]")
    print()
    print("Options:")
    print("  -d  specify heigth to start digging")
    print()
    return
end

local size
local goDown = 0

local function readParams()
    write("diameter: ")
    size = tonumber(io.read())
    write("altitude: ")
    temp = tonumber(io.read())
    if temp ~= nil then craplib.setAltitude(temp) end
end

local function readArgs()
    if #tArgs == 0 then
        readParams()
        return
    end

    local valid_args = false

    local skip_one = false
    for i = 1, #tArgs - 1 do
        if skip_one then do break end end

        if tArgs[i] == "-d" then
            skip_one = true
            goDown = tonumber(tArgs[i + 1])

            -- elseif tostring(tArgs[i]).find("-") then
            -- print( "unrecognized argument " + tArgs[i] )

        elseif #tArgs - i <= 2 then
            size = tonumber(tArgs[i])
            if #tArgs > i then
                craplib.setAltitude(tonumber(tArgs[i + 1]))
            end

            valid_args = true
            i = #tArgs -- end for loop
        end
    end

    if not valid_args then readParams() end
end

local function checkArgs()
    if craplib.getAltitude() ~= 0 then
        if craplib.getAltitude() > 0 then
            downwards = false
            craplib.setAltitude(craplib.getAltitude() - 1)
        else
            craplib.setAltitude(craplib.getAltitude() + 1)
        end
    end

    if size == nil or size < 1 then
        print("Diameter must be a positive number")
        return
    end
end

-- ############################################################
-- Mine in a quarry pattern until we hit something we can't dig
-- ############################################################

local function main()
    readArgs()
    checkArgs()

    turtle.select(1)

    if turtle.getItemCount(1) > 0 then
        item = turtle.getItemDetail(1).name
        if string.find(item, "bucket") then craplib.setFuelLava() end
    end

    craplib.turnLeft()

    if turtle.detect() and turtle.suck(1) and turtle.refuel(0) then
        craplib.setFuelChest()
        turtle.suck(1)
        craplib.supplyChest()
    end

    craplib.turnRight()

    if not craplib.refuel() then
        print("Out of Fuel")
        return
    end

    print("Excavating...")

    if goDown ~= 0 then
        if downwards then
            for i = 1, goDown do craplib.goDown() end
        else
            for i = 1, goDown do craplib.goUp() end
        end
    end

    craplib.quarry(size)

    craplib.endTour()

end

main()
