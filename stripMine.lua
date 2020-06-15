local tArgs = {...}
if #tArgs ~= 1 or tArgs[1] == "help" then
    print("Usage: stripMine <stripes>")
    return
end

local stripes

stripes = tonumber(tArgs[1])

if stripes == nil or stripes < 0 then
    print("Number of stripes must be positive.")
    return
end

local stripesLeft = stripes

local height = 0
local unloaded = 0
local collected = 0

local xPos, zPos = 0, 0
local xDir, zDir = 0, 1

local fuelChest = false
local torches = false

local goTo -- Filled in further down
local refuel -- Filled in further down

local function unload(_bKeepOneFuelStack)
    print("Unloading items...")
    iterations = 16
    if torches then iterations = 15 end
    for n = 1, 16 do
        local nCount = turtle.getItemCount(n)
        if nCount > 0 then
            turtle.select(n)
            local bDrop = true
            if _bKeepOneFuelStack and turtle.refuel(0) then
                i = turtle.getItemSpace(n)
                turtle.suck(i)
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

local function fuelChest()
    turtle.select(1)
    if fuelChest then
        turtle.turnLeft()
        turtle.turnLeft()
        if not turtle.refuel(0) then turtle.transferTo(16) end
        i = turtle.getItemSpace(1)
        turtle.suck(i)
        turtle.turnLeft()
        turtle.turnLeft()
    end
end

local function returnSupplies()
    local x, y, z, xd, zd = xPos, height, zPos, xDir, zDir
    print("Returning to starting point...")
    goTo(0, 0, 0, -1, 0)

    if fuelChest then fuelChest() end

    local fuelNeeded = 2 * (x + math.abs(y) + z) + 1
    if not refuel(fuelNeeded) then
        unload(true)
        print("Waiting for fuel")
        while not refuel(fuelNeeded) do os.pullEvent("turtle_inventory") end
    else
        unload(true)
    end

    if fuelChest then fuelChest() end

    if torches then
        if turtle.getItemCount(16) == 0 then
            write("Need some torches in the last slot (")
            write(stripesLeft)
            print(")")

            while turtle.getItemCount(16) == 0 do
                os.pullEvent("turtle_inventory")
            end
        end
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

    local needed = ammount or (xPos + zPos + math.abs(height) + 2)
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

function digUp()
    if turtle.detectUp() then
        if turtle.digUp() then if not collect() then returnSupplies() end end
    end
end

function digDown()
    if turtle.detectDown() then
        if turtle.digDown() then
            if not collect() then returnSupplies() end
        end
    end
end

function fallingBlocks()
    turtle.suckUp()
    while turtle.detectUp() do
        if turtle.digUp() then if not collect() then returnSupplies() end end
        sleep(0.5)
    end
end

local function digForwards()
    turtle.suckUp()
    turtle.suck()
    turtle.suckDown()

    digUp()
    digDown()
    fallingBlocks()

    return tryForwards()
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
    if math.fmod(height, 10) == 0 then
        print("Descended " .. math.abs(height) .. " metres.")
    end

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
    if math.fmod(height, 10) == 0 then
        print("Descended " .. height .. " metres.")
    end

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

function stripe()

    stripesLeft = stripesLeft - 1

    for i = 1, 3 do digForwards() end

    turnLeft()

    if torches then
        turnLeft()
        turtle.select(16)
        turtle.place()

        if turtle.getItemCount(16) == 0 and stripesLeft > 0 then
            turtle.select(1)
            returnSupplies()
        end

        turnRight()
    end

    for i = 1, 2 do
        for j = 1, 5 do digForwards() end

        digUp()
        digDown()
        fallingBlocks()

        turnLeft()
        turnLeft()

        for j = 1, 5 do tryForwards() end
    end

    turnRight()
end

turnLeft()

if not turtle.detect() then
    turnRight()
    print("Please Place a Chest at the left")
    return
end

turnRight()

turtle.select(16)

if turtle.getItemCount() > 0 then torches = true end

turnRight()
turtle.select(1)

if turtle.detect() and turtle.suck(1) and turtle.refuel(0) then
    fuelChest = true
    i = turtle.getItemSpace(1)
    turtle.suck(i)
end

turnLeft()

if not refuel() then
    print("Out of Fuel")
    return
end

print("Mining...")

tryUp()

for n = 1, stripes do stripe() end

print("Returning to starting point...")

-- Return to where we started
goTo(0, 0, 0, -1, 0)
unload(false)
goTo(0, 0, 0, 0, 1)

print("Mined " .. (collected + unloaded) .. " items total.")
