local craplib = {}

local unloaded = 0
local collected = 0

local FUEL_CHEST = false
local FUEL_LAVA = false

local fuelSlot = 1

local xPos, zPos = 0, 0
local xDir, zDir = 0, 1

local height = 0
local altitude = 0
local downwards = true

local isInitialized = false

function craplib.getCollectedItems() return collected + unloaded end

function craplib.getFuelSlot() return fuelSlot end

function craplib.getAltitude() return altitude end

function craplib.setFuelChest() FUEL_CHEST = true end

function craplib.setFuelLava() FUEL_LAVA = true end

function craplib.setFuelSlot(nFuelSlot) fuelSlot = nFuelSlot end

function craplib.setAltitude(nAltitide) altitude = nAltitide end

function craplib.init(nFuelSlot)
    if not isInitialized then
        fuelSlot = nFuelSlot or nil

        if not craplib.refuel() then
            print("Out of Fuel")
            return
        end
    end
end

function craplib.unload(_bKeepOneFuelStack)
    print("Unloading items...")
    for n = 1, 16 do
        nCount = turtle.getItemCount(n)
        if nCount > 0 then
            turtle.select(n)
            bDrop = true
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

function craplib.supplyChest()
    local x, y, z, xd, zd = xPos, height, zPos, xDir, zDir
    craplib.goTo(0, 0, 0, -1, 0)
    if fuelSlot then
        turtle.select(fuelSlot)
    else
        turtle.select(1)
    end
    if FUEL_CHEST and not FUEL_LAVA then
        craplib.turnRight()
        if not turtle.refuel(0) then turtle.transferTo(16) end
        i = turtle.getItemSpace(turtle.getSelectedSlot())
        turtle.suck(i)
        craplib.turnLeft()
    elseif FUEL_CHEST and FUEL_LAVA then
        craplib.turnRight()
        while turtle.getFuelLimit() * 0.75 < turtle.getFuelLevel() do
            turtle.drop()
            sleep(1)
            turtle.suck()
            if not turtle.refuel() then break end
        end
        craplib.turnLeft()
    end
    craplib.goTo(x, y, z, xd, zd)
end

function craplib.returnSupplies()
    local x, y, z, xd, zd = xPos, height, zPos, xDir, zDir
    print("Returning to starting point...")
    craplib.goTo(0, 0, 0, 0, -1)

    craplib.supplyChest()

    fuelNeeded = 2 * (x + math.abs(y) + z) + 1
    if not craplib.refuel(fuelNeeded) then
        craplib.unload(true)
        print("Waiting for fuel")
        while not craplib.refuel(fuelNeeded) do
            os.pullEvent("turtle_inventory")
        end
    else
        craplib.unload(true)
    end

    craplib.supplyChest()

    print("Resuming mining...")
    craplib.goTo(x, y, z, xd, zd)
end

function craplib.endTour()
    craplib.goTo(0, 0, 0, 0, -1)
    craplib.unload(true)
    craplib.goTo(0, 0, 0, 0, 1)

    print("Collected " .. (collected + unloaded) .. " items total.")
end

function craplib.collect()
    bFull = true
    nTotalItems = 0
    for n = 1, 16 do
        nCount = turtle.getItemCount(n)
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

function craplib.refuel(ammount)
    fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" then return true end

    needed = ammount or (xPos + zPos + math.abs(height) + 2)
    if turtle.getFuelLevel() < needed then
        local selectedSlot = turtle.getSelectedSlot()
        if fuelSlot then
            turtle.select(fuelSlot)
            while turtle.getItemCount(fuelSlot) > 0 and turtle.getFuelLevel() <
                needed do turtle.refuel(1) end
            if turtle.getFuelLevel() >= needed then
                turtle.select(selectedSlot)
                return true
            end
        else
            for n = 1, 16 do
                if turtle.getItemCount(n) > 0 then
                    turtle.select(n)
                    if turtle.refuel(1) then
                        while turtle.getItemCount(n) > 0 and
                            turtle.getFuelLevel() < needed do
                            turtle.refuel(1)
                        end
                        if turtle.getFuelLevel() >= needed then
                            turtle.select(1)
                            return true
                        end
                    end
                end
            end
        end
        turtle.select(selectedSlot)
        return false
    end

    return true
end

function craplib.tryForwards()
    if not craplib.refuel() then
        print("Not enough Fuel")
        craplib.returnSupplies()
    end

    while not turtle.forward() do
        if turtle.detect() then
            if turtle.dig() then
                if not craplib.collect() then
                    craplib.returnSupplies()
                end
            else
                return false
            end
        elseif turtle.attack() then
            if not craplib.collect() then craplib.returnSupplies() end
        else
            sleep(0.5)
        end
    end

    xPos = xPos + xDir
    zPos = zPos + zDir
    return true
end

function craplib.digUp()
    if turtle.detectUp() then
        if turtle.digUp() then
            if not craplib.collect() then craplib.returnSupplies() end
        end
    end
end

function craplib.digDown()
    if turtle.detectDown() then
        if turtle.digDown() then
            if not craplib.collect() then craplib.returnSupplies() end
        end
    end
end

function craplib.fallingBlocks()
    turtle.suckUp()
    while turtle.detectUp() do
        if turtle.digUp() then
            if not craplib.collect() then craplib.returnSupplies() end
        end
        sleep(1)
    end
end

function craplib.digForwards()
    turtle.suckUp()
    turtle.suck()
    turtle.suckDown()
    if altitude == 0 then
        craplib.digUp()
        craplib.digDown()
        craplib.fallingBlocks()
    elseif downwards then
        craplib.digUp()
        if (height > altitude) then
            craplib.digDown()
            craplib.fallingBlocks()
        end
    else
        if (height < altitude) then craplib.digUp() end
        craplib.digDown()
        if (height < altitude) then craplib.fallingBlocks() end
    end

    return craplib.tryForwards()
end

function craplib.tryDown()
    if not craplib.refuel() then
        print("Not enough Fuel")
        craplib.returnSupplies()
    end

    while not turtle.down() do
        if turtle.detectDown() then
            if turtle.digDown() then
                if not craplib.collect() then
                    craplib.returnSupplies()
                end
            else
                return false
            end
        elseif turtle.attackDown() then
            if not craplib.collect() then craplib.returnSupplies() end
        else
            sleep(0.5)
        end
    end

    height = height - 1

    return true
end

function craplib.tryUp()
    if not craplib.refuel() then
        print("Not enough Fuel")
        craplib.returnSupplies()
    end

    while not turtle.up() do
        if turtle.detectUp() then
            if turtle.digUp() then
                if not craplib.collect() then
                    craplib.returnSupplies()
                end
            else
                return false
            end
        elseif turtle.attackUp() then
            if not craplib.collect() then craplib.returnSupplies() end
        else
            sleep(0.5)
        end
    end

    height = height + 1

    return true
end

function craplib.changeAltitude()
    if downwards then
        if not (height + 1 > 0) then craplib.digUp() end
        if altitude == 0 then
            return craplib.tryDown()
        elseif (height > altitude) then
            return craplib.tryDown()
        end
    else
        if not (height - 1 < 0) then craplib.digDown() end
        if altitude == 0 then
            return craplib.tryUp()
        elseif (height < altitude) then
            return craplib.tryUp()
        end
    end
end

function craplib.turnLeft()
    turtle.turnLeft()
    xDir, zDir = -zDir, xDir
end

function craplib.turnRight()
    turtle.turnRight()
    xDir, zDir = zDir, -xDir
end

function craplib.goTo(x, y, z, xd, zd)
    while height < y do
        if turtle.up() then
            height = height + 1
        elseif turtle.digUp() or turtle.attackUp() then
            craplib.collect()
        else
            sleep(0.5)
        end
    end

    if xPos > x then
        while xDir ~= -1 do craplib.turnLeft() end
        while xPos > x do
            if turtle.forward() then
                xPos = xPos - 1
            elseif turtle.dig() or turtle.attack() then
                craplib.collect()
            else
                sleep(0.5)
            end
        end
    elseif xPos < x then
        while xDir ~= 1 do craplib.turnLeft() end
        while xPos < x do
            if turtle.forward() then
                xPos = xPos + 1
            elseif turtle.dig() or turtle.attack() then
                craplib.collect()
            else
                sleep(0.5)
            end
        end
    end

    if zPos > z then
        while zDir ~= -1 do craplib.turnLeft() end
        while zPos > z do
            if turtle.forward() then
                zPos = zPos - 1
            elseif turtle.dig() or turtle.attack() then
                craplib.collect()
            else
                sleep(0.5)
            end
        end
    elseif zPos < z then
        while zDir ~= 1 do craplib.turnLeft() end
        while zPos < z do
            if turtle.forward() then
                zPos = zPos + 1
            elseif turtle.dig() or turtle.attack() then
                craplib.collect()
            else
                sleep(0.5)
            end
        end
    end

    while height > y do
        if turtle.down() then
            height = height - 1
        elseif turtle.digDown() or turtle.attackDown() then
            craplib.collect()
        else
            sleep(0.5)
        end
    end

    while zDir ~= zd or xDir ~= xd do craplib.turnLeft() end
end

function craplib.quarry(size, direction, fEnd)
    local endFunction = fEnd or nil
    local direction = direction or "down"
    local alternate = 0
    local done = false

    if direction == "up" then
        downwards = false
    elseif direction == "down" then
        downwards = true
    else
        print("Direction can only be up or down!")
        return
    end

    craplib.changeAltitude()

    local x, y, z, xd, zd = xPos, height, zPos, xDir, zDir

    while not done do
        for n = 1, size do
            for m = 1, size - 1 do
                if not craplib.digForwards() then
                    done = true
                    break
                end
            end
            if done then break end
            if n < size then
                if math.fmod(n + alternate, 2) == 0 then
                    craplib.turnLeft()
                    if not craplib.digForwards() then
                        done = true
                        break
                    end
                    craplib.turnLeft()
                else
                    craplib.turnRight()
                    if not craplib.digForwards() then
                        done = true
                        break
                    end
                    craplib.turnRight()
                end
            end
        end
        if done then break end

        if size > 1 then
            if math.fmod(size, 2) == 0 then
                craplib.turnRight()
            else
                if alternate == 0 then
                    craplib.turnLeft()
                else
                    craplib.turnRight()
                end
                alternate = 1 - alternate
            end
        end

        craplib.changeAltitude()

        if not craplib.changeAltitude() then
            done = true
            break
        elseif endFunction then
            if endFunction() then
                done = true
                break
            end
        end
        craplib.changeAltitude()
    end

    craplib.goTo(x, y, z, xd, zd)
end

if package.loaded["craplib"] then
    return craplib
else
    print("Nothing happens...")
end
