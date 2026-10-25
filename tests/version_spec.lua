-- The library's version: a release tag must be its MINOR, and every data file must be built for
-- that MINOR, or no copy of the library would take it (NewData, NewFoods).

local sh = require("tests.sh")
local version = require("tests.version")

describe("LibTameable's version", function()
    local minor = version.minor("LibTameable-1.0.lua")

    it("is a whole number in the library file", function()
        assert.is_number(minor)
    end)

    it("takes only a release tag that is its MINOR", function()
        assert.is_true((version.checkTag(tostring(minor), minor)))
        local ok, message = version.checkTag(tostring(minor + 1), minor)
        assert.is_false(ok)
        assert.truthy(message:find("raise MINOR first", 1, true))
    end)

    it("is the MINOR every data file was built for", function()
        local files = 0
        for _, name in ipairs(sh.list("Data")) do
            if name:match("%.lua$") then
                local built = sh.read("Data/" .. name):match('lib:New%a+%("%a+", (%d+)%)')
                assert.equal(tostring(minor), built, name)
                files = files + 1
            end
        end
        assert.equal(5, files)
    end)
end)
