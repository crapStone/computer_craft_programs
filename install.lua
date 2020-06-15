-- https://pastebin.com/HKckLDnp
-- pastebin run HKckLDnp
local function download_file(url, path)
    local content = http.get(url).readAll()

    local fh = fs.open(path, "w")
    fh.write(content)
    fh.close()
end

local json = require("libs.json")

local scripts = http.get(
                    "https://raw.githubusercontent.com/crapStone/computer_craft_programs/master/script_list.json")
                    .readAll()

local install_data = json.decode(scripts)

local install_array = install_data["scripts"]

for _, lib in pairs(install_data["libs"]) do
    install_array[#install_array + 1] = string.format("libs/%s", lib)
end

print()
print("=======================")
print(" installing scripts...")
print("=======================")
print()

for _, script in pairs(install_array) do
    local url = string.format(
                    "https://raw.githubusercontent.com/crapStone/computer_craft_programs/master/%s.lua",
                    script)

    download_file(url, string.format("%s.lua", script))

    print(string.format("installed %s", script))
end

print()
