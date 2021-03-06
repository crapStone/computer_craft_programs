local tArgs = {...}
if #tArgs < 2 or #tArgs > 3 then
    print("Usage: wald <length> <width> [<bPlantSaplings>]")
    return
end

local length = tonumber(tArgs[1])
local width = tonumber(tArgs[2])
local plantSaplings = false

if #tArgs == 3 then plantSaplings = tArgs[3] end

if length <= 0 or width <= 0 then
    print("Length and width must be positive")
    return
end

local height = 0
local unloaded = 0
local collected = 0

local xPos, zPos = 0, 0
local xDir, zDir = 0, 1

local goTo -- Filled in further down
local refuel -- Filled in further down

local function unload(_bKeepOneFuelStack)
    print("Unloading items...")
    for n = 1, 16 do
        local nCount = turtle.getItemCount(n)
        if nCount > 0 then
            turtle.select(n)
            local bDrop = true
            if _bKeepOneFuelStack and turtle.refuel(0) then
                bDrop = false
                _bKeepOneFuelStack = false
            end
            if bDrop then
                turtle.drop()
                unloaded = unloaded + nCount
            end
        end
    end
    collected = 0
    turtle.select(1)
end

local function returnSupplies()
    local x, y, z, xd, zd = xPos, height, zPos, xDir, zDir
    print("Returning to surface...")
    goTo(0, 0, 0, 0, -1)

    local fuelNeeded = 2 * (x + y + z) + 1
    if not refuel(fuelNeeded) then
        unload(true)
        print("Waiting for fuel")
        while not refuel(fuelNeeded) do os.pullEvent("turtle_inventory") end
    else
        unload(true)
    end

    print("Resuming mining...")
    goTo(x, y, z, xd, zd)
end

local function collect()
    local bFull = true
    local nTotalItems = 0
    for n = 1, 16 do
        local nCount = turtle.getItemCount(n)
        if nCount == 0 then bFull = false end
        nTotalItems = nTotalItems + nCount
    end

    if nTotalItems > collected then
        collected = nTotalItems
        if math.fmod(collected + unloaded, 50) == 0 then
            print("Mined " .. (collected + unloaded) .. " items.")
        end
    end

    if bFull then
        print("No empty slots left.")
        return false
    end
    return true
end

function refuel(ammount)
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" then return true end

    local needed = ammount or (xPos + zPos + height + 2)
    if turtle.getFuelLevel() < needed then
        local fueled = false
        for n = 1, 16 do
            if turtle.getItemCount(n) > 0 then
                turtle.select(n)
                if turtle.refuel(1) then
                    while turtle.getItemCount(n) > 0 and turtle.getFuelLevel() <
                        needed do turtle.refuel(1) end
                    if turtle.getFuelLevel() >= needed then
                        turtle.select(1)
                        return true
                    end
                end
            end
        end
        turtle.select(1)
        return false
    end

    return true
end

local function tryForwards()
    if not refuel() then
        print("Not enough Fuel")
        returnSupplies()
    end

    while not turtle.forward() do
        if turtle.detect() then
            if turtle.dig() then
                if not collect() then returnSupplies() end
            else
                return false
            end
        elseif turtle.attack() then
            if not collect() then returnSupplies() end
        else
            sleep(0.5)
        end
    end

    xPos = xPos + xDir
    zPos = zPos + zDir
    return true
end

local function tryUp()
    if not refuel() then
        print("Not enough Fuel")
        returnSupplies()
    end

    while not turtle.up() do
        if turtle.detectUp() then
            if turtle.digUp() then
                if not collect() then returnSupplies() end
            else
                return false
            end
        elseif turtle.attackUp() then
            if not collect() then returnSupplies() end
        else
            sleep(0.5)
        end
    end

    height = height + 1
    return true
end

local function tryDown()
    if not refuel() then
        print("Not enough Fuel")
        returnSupplies()
    end

    while not turtle.down() do
        if turtle.detectDown() then
            if turtle.digDown() then
                if not collect() then returnSupplies() end
            else
                return false
            end
        elseif turtle.attackDown() then
            if not collect() then returnSupplies() end
        else
            sleep(0.5)
        end
    end

    height = height - 1
    return true
end

local function turnLeft()
    turtle.turnLeft()
    xDir, zDir = -zDir, xDir
end

local function turnRight()
    turtle.turnRight()
    xDir, zDir = zDir, -xDir
end

function goTo(x, y, z, xd, zd)
    while height > y do
        if turtle.down() then
            height = height - 1
        elseif turtle.digDown() or turtle.attackDown() then
            collect()
        else
            sleep(0.5)
        end
    end

    if xPos > x then
        while xDir ~= -1 do turnLeft() end
        while xPos > x do
            if turtle.forward() then
                xPos = xPos - 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    elseif xPos < x then
        while xDir ~= 1 do turnLeft() end
        while xPos < x do
            if turtle.forward() then
                xPos = xPos + 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    end

    if zPos > z then
        while zDir ~= -1 do turnLeft() end
        while zPos > z do
            if turtle.forward() then
                zPos = zPos - 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    elseif zPos < z then
        while zDir ~= 1 do turnLeft() end
        while zPos < z do
            if turtle.forward() then
                zPos = zPos + 1
            elseif turtle.dig() or turtle.attack() then
                collect()
            else
                sleep(0.5)
            end
        end
    end
    while height < y do
        if turtle.up() then
            height = height + 1
        elseif turtle.digUp() or turtle.attackUp() then
            collect()
        else
            sleep(0.5)
        end
    end

    while zDir ~= zd or xDir ~= xd do turnLeft() end
end

local function fellRow()
    for i = 1, length do
        tryForwards()
        altitude = 0
        while turtle.detectUp() do
            tryUp()
            altitude = altitude + 1
        end
        for j = 1, altitude do tryDown() end
        if i < length then
            tryForwards()
            tryForwards()
        end
    end
    tryForwards()
end

local function plantRow()
    tryUp()
    for i = 1, length do
        tryForwards()
        turtle.placeDown()
        if i < length then
            tryForwards()
            tryForwards()
        end
    end
    tryForwards()
    tryDown()
end

local function turn()
    if zDir == 1 then
        turnRight()
        tryForwards()
        tryForwards()
        tryForwards()
        turnRight()
    elseif zDir == -1 then
        turnLeft()
        tryForwards()
        tryForwards()
        tryForwards()
        turnLeft()
    end

end

if not refuel() then
    print("Out of Fuel")
    return
end

if plantSaplings then
    print("Planting...")
else
    print("Felling...")
end

turtle.select(1)

for i = 1, width do
    if plantSaplings then
        plantRow()
    else
        fellRow()
    end
    if i < width then turn() end
end
if plantSaplings then
    if turtle.detectUp() then turtle.digUp() end
    turtle.up()
end

print("Returning to beginning...")

-- Return to where we started
goTo(0, 0, 0, 0, -1)
if plantSaplings then
    if turtle.detectDown() then turtle.digDown() end
    turtle.down()
end
unload(false)
goTo(0, 0, 0, 0, 1)
