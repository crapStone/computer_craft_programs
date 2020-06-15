-- https://pastebin.com/HKckLDnp
-- pastebin run HKckLDnp
local function download_file(url, path)
    local content = http.get(url).readAll()

    local fh = fs.open(path, "w")
    fh.write(content)
    fh.close()
end

print()
print("installing dependencies...")

download_file("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua",
              "libs/json.lua")
download_file(
    "https://raw.githubusercontent.com/crapStone/computer_craft_programs/master/install.lua",
    "install.lua")

shell.run("install")

fs.delete("install.lua")
