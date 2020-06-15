local craplib = require("libs.craplib")

local treelib = {}

local size -- Filled in further down
local replant = false
local saplingSlot = 1

function treelib.setReplant() replant = true end

local function detectTreeEnd() return not turtle.detect() end

function treelib.main()

    craplib.init(2)

    if turtle.getItemCount(saplingSlot) == 0 and replant then
        print("Please give me saplings in the first slot!")
        return false
    end

    print("Felling...")

    while not turtle.detect() do craplib.tryForwards() end

    craplib.tryForwards()
    if turtle.detect() then
        size = 2
    else
        size = 1
    end

    craplib.quarry(size, "up", detectTreeEnd)

    if size == 1 then
        turtle.placeDown()
    else
        for i = 0, 3 do
            turtle.placeDown()
            craplib.tryForwards()
            craplib.turnRight()
        end
    end

    craplib.endTour()

end

if package.loaded["tree"] then
    return treelib
else
    treelib.main()
end
