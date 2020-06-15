-- https://pastebin.com/HKckLDnp
-- pastebin run HKckLDnp

local scripts = http.get("https://raw.githubusercontent.com/crapStone/computer_craft_programs/master/script_list").readAll()

print("=======================")
print(" installing scripts...")
print("=======================")

for script in string.gmatch(scripts, "%a+") do
    local url = string.format("https://raw.githubusercontent.com/crapStone/computer_craft_programs/master/%s.lua", script)
    local content = http.get(url)

    local fh = fs.open(string.format("%s.lua", script), "w")

    fh.write(content.readAll())

    fh.close()

    print(string.format("installed %s", script))
end
