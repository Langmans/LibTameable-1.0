-- A simulated WoW client for the library: only the project ID the library reads to know which
-- client it runs on. NewClient() resets the globals and loads the .toc's files (LibStub included)
-- into a fresh state, so tests never share it.

-- The clients by name, as their WOW_PROJECT_ID.
PROJECTS = { era = 2, tbc = 5, forever = 18, retail = 1, mists = 19 }

---Loads every file of the .toc into the current globals.
local function LoadToc()
    for _, file in ipairs(TOC_FILES) do
        assert(loadfile(file))("LibTameable-1.0", {})
    end
end

---@param project string? a PROJECTS key, Classic Era by default
function NewClient(project)
    local client = {}
    WOW_PROJECT_ID = PROJECTS[project or "era"]

    -- LibStub keeps its libraries in a global; a fresh client starts without one.
    LibStub = nil
    LoadToc()
    client.lib = LibStub("LibTameable-1.0")

    ---Loads the library's files again, as a second addon embedding the same version would.
    function client:loadAgain()
        LoadToc()
        return LibStub("LibTameable-1.0")
    end

    return client
end
