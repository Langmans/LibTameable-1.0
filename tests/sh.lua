-- Small file and process helpers for the tooling scripts (check.lua, libs.lua), working the same
-- on Windows (cmd.exe) and on Linux (CI). Commands are argument lists, quoted here, because the
-- repository path may contain spaces ("My Games").

local lfs = require("lfs")

local M = {}

M.windows = package.config:sub(1, 1) == "\\"

local function quote(arg)
    if M.windows then return '"' .. arg .. '"' end
    return "'" .. arg:gsub("'", "'\\''") .. "'"
end

---The command line for argv. cmd.exe drops the first and last quote of a line that starts with
---one, so on Windows the whole line gets an extra pair.
---@param argv string[]
---@return string
function M.commandLine(argv)
    local parts = {}
    for i, arg in ipairs(argv) do
        parts[i] = quote(arg)
    end
    local line = table.concat(parts, " ")
    return M.windows and '"' .. line .. '"' or line
end

---Runs argv with its output going to the terminal. Returns whether it exited with 0.
---@param argv string[]
---@param allowFailure boolean? return false instead of raising
---@return boolean
function M.run(argv, allowFailure)
    local result = os.execute(M.commandLine(argv))
    -- Lua 5.1 returns the exit code, 5.2+ true/nil.
    local ok = result == 0 or result == true
    if not ok and not allowFailure then error("failed: " .. table.concat(argv, " "), 2) end
    return ok
end

---Runs argv and returns its output (stdout and stderr together) and whether it exited with 0.
---@param argv string[]
---@return string output
---@return boolean ok
function M.capture(argv)
    -- The exit status comes back as a last line: `&& ... ||` reads the same in cmd.exe and sh
    -- (cmd's %errorlevel% would be expanded before the command runs).
    local marker = "__exit:"
    local line = M.commandLine(argv)
    local tail = " 2>&1 && echo " .. marker .. "0 || echo " .. marker .. "1"
    if M.windows then
        line = '"' .. line:sub(2, -2) .. tail .. '"'
    else
        line = line .. tail
    end
    local pipe = assert(io.popen(line))
    local output = pipe:read("*a")
    pipe:close()
    local code = tonumber(output:match(marker .. "(%d+)%s*$"))
    return (output:gsub(marker .. "%d+%s*$", "")), code == 0
end

---@param path string
---@return boolean
function M.exists(path)
    return lfs.attributes(path) ~= nil
end

---@param path string
---@return string
function M.read(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a")
    file:close()
    return text
end

---@param path string
---@param text string
function M.write(path, text)
    local file = assert(io.open(path, "wb"))
    file:write(text)
    file:close()
end

---Creates path and any missing parents.
---@param path string
function M.mkdir(path)
    local sofar = ""
    for part in path:gmatch("[^/\\]+") do
        sofar = sofar == "" and part or sofar .. "/" .. part
        if part:match(":$") == nil and not M.exists(sofar) then assert(lfs.mkdir(sofar)) end
    end
end

---Deletes path and everything under it, if it exists. Through the shell, because git leaves
---read-only files that os.remove cannot delete on Windows.
---@param path string
function M.rmtree(path)
    if not M.exists(path) then return end
    if M.windows then
        -- rmdir is a cmd.exe builtin, so its name must not be quoted.
        os.execute('rmdir /s /q "' .. path:gsub("/", "\\") .. '"')
    else
        M.run({ "rm", "-rf", path })
    end
end

---The entries of a directory, sorted, without . and ..
---@param path string
---@return string[]
function M.list(path)
    local names = {}
    if lfs.attributes(path, "mode") ~= "directory" then return names end
    for name in lfs.dir(path) do
        if name ~= "." and name ~= ".." then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

return M
