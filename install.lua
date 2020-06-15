-- https://pastebin.com/HKckLDnp
-- pastebin run HKckLDnp
local json = require("libs.json")

local scripts = http.get(
                    "https://raw.githubusercontent.com/crapStone/computer_craft_programs/master/script_list.json")
                    .readAll()

print()
print("=======================")
print(" installing scripts...")
print("=======================")
print()

for _, script in pairs(json.decode(scripts)) do
    local url = string.format(
                    "https://raw.githubusercontent.com/crapStone/computer_craft_programs/master/%s.lua",
                    script)
    local content = http.get(url)

    local fh = fs.open(string.format("%s.lua", script), "w")

    fh.write(content.readAll())

    fh.close()

    print(string.format("installed %s", script))
end

print()
