-- https://pastebin.com/HKckLDnp
-- pastebin run HKckLDnp

print()
print("installing dependencies...")

local lua_json = http.get("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua").readAll()

local fh = fs.open("libs/json.lua", "w")
fh.write(lua_json)
fh.close()

local json = require("libs.json")

local scripts = http.get("https://raw.githubusercontent.com/crapStone/computer_craft_programs/master/script_list.json").readAll()

print()
print("=======================")
print(" installing scripts...")
print("=======================")
print()

for _, script in pairs(json.decoce(scripts)) do
    local url = string.format("https://raw.githubusercontent.com/crapStone/computer_craft_programs/master/%s.lua", script)
    local content = http.get(url)

    local fh = fs.open(string.format("%s.lua", script), "w")

    fh.write(content.readAll())

    fh.close()

    print(string.format("installed %s", script))
end

print()
