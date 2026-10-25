-- Loaded once by busted before the spec files (see .busted). Reads LibTameable-1.0.toc the way the
-- client does, every .xml in it expanded to the Lua files it names, and defines NewClient
-- (tests/wow.lua).
-- busted runs from the repository root, so paths are relative to it.

local sh = require("tests.sh")

---The Lua files an .xml loads, in order, following <Include>s. Comments are skipped.
---@param file string
---@return string[]
local function expandXml(file)
    local text = sh.read(file):gsub("<!%-%-.-%-%->", "")
    local dir = file:match("^(.*)/") or "."
    local files = {}
    for tag, path in text:gmatch('<(%a+)%s+file="([^"]+)"') do
        -- A file next to the .toc keeps a bare path, as the coverage report names it.
        local target = (dir == "." and "" or dir .. "/") .. path:gsub("\\", "/")
        if tag == "Include" then
            for _, f in ipairs(expandXml(target)) do
                files[#files + 1] = f
            end
        elseif tag == "Script" then
            files[#files + 1] = target
        end
    end
    return files
end

local toc = sh.read("LibTameable-1.0.toc")

-- The load order: every file the .toc names, .xml files expanded.
TOC_FILES = {}
for line in toc:gmatch("[^\r\n]+") do
    line = line:match("^%s*(.-)%s*$")
    if line ~= "" and not line:match("^#") then
        line = line:gsub("\\", "/")
        if line:match("%.xml$") then
            for _, file in ipairs(expandXml(line)) do
                TOC_FILES[#TOC_FILES + 1] = file
            end
        else
            TOC_FILES[#TOC_FILES + 1] = line
        end
    end
end

-- The "## Key: value" lines, for GetAddOnMetadata, and the SavedVariables name.
TOC_METADATA = {}
for key, value in toc:gmatch("## ([^:\r\n]+):%s*([^\r\n]-)%s*\r?\n") do
    TOC_METADATA[key] = value
end
TOC_SAVED = TOC_METADATA.SavedVariables

dofile("tests/wow.lua")
