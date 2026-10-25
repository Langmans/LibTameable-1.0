-- The library's MINOR, and whether a release tag matches it: a release's tag is its MINOR
-- (README). tests/check.lua checks the tag a CI run builds; the specs check the rest.

local sh = require("tests.sh")

local M = {}

---The MINOR a library file declares (`local MAJOR, MINOR = "Name-1.0", 3`), nil without one.
---@param file string
---@return number?
function M.minor(file)
    return tonumber(sh.read(file):match('local MAJOR, MINOR = "[^"]+", (%d+)'))
end

---Whether a release tag names this MINOR, and if not, what is wrong.
---@param tag string
---@param minor number?
---@return boolean ok
---@return string message
function M.checkTag(tag, minor)
    if tag == tostring(minor) then return true, ("tag %s is MINOR %s"):format(tag, tag) end
    return false, ("tag %s, but MINOR is %s: raise MINOR first, the tag is its number"):format(tag, tostring(minor))
end

return M
