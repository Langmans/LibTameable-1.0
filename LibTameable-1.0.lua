-- LibTameable-1.0: the hunter pet abilities a tameable beast teaches, per game client. Each rank
-- of a pet ability (by spell ID) has its ability (the rank 1 spell ID), rank, the pet level it
-- needs, the families that learn it and the beasts that teach it; each teaching beast (by NPC ID)
-- has its name, family, levels, rarity and where it spawns.
--
-- The data is per client, one file each in Data\: Classic Era (Season of Discovery too), Burning
-- Crusade Classic and WoW: Forever. Every file is in lib.xml, but only the running client's one
-- fills the tables; on any other client the library has no data (HasData).
--
--   local Tameable = LibStub("LibTameable-1.0")
--   local ability, rank, level = Tameable:GetRank(17253)      -- Bite, 1, 1
--   for _, npc in ipairs(Tameable:GetTeachers(17255)) do ... end
--
-- Lists and tables the library returns are its own: read them, never change them.

-- MINOR goes up by one with every release, and the release tag is the same number (README). The
-- data files carry the MINOR they were built for.
local MAJOR, MINOR = "LibTameable-1.0", 1

---@type LibTameable?
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

---The clients with data, by WOW_PROJECT_ID.
lib.clients = {
    [2] = "era", -- WOW_PROJECT_CLASSIC
    [5] = "tbc", -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC
    [18] = "forever", -- WOW_PROJECT_CAMELOT
}

---Hunter pet families by name, as CreatureFamily IDs (the game's UnitCreatureFamily numbering).
---The ID is the same on every client, the name not always: 26 is the Owl on Classic Era and
---Burning Crusade, the Bird of Prey on WoW: Forever. Show the client's own name.
lib.families = {
    wolf = 1,
    cat = 2,
    spider = 3,
    bear = 4,
    boar = 5,
    crocolisk = 6,
    carrionBird = 7,
    crab = 8,
    gorilla = 9,
    raptor = 11,
    tallstrider = 12,
    scorpid = 20,
    turtle = 21,
    bat = 24,
    hyena = 25,
    birdOfPrey = 26,
    windSerpent = 27,
    dragonhawk = 30,
    ravager = 31,
    warpStalker = 32,
    sporebat = 33,
    netherRay = 34,
    serpent = 35,
    fox = 40,
}

---The kinds of pet food an item can be (a family eats some of them).
lib.foodKinds = {
    meat = "meat",
    fish = "fish",
    cheese = "cheese",
    bread = "bread",
    fungus = "fungus",
    fruit = "fruit",
    rawFish = "rawFish",
}

lib.client = lib.clients[WOW_PROJECT_ID]

-- Each food item's kind, by item ID: only where the client cannot say what a pet eats (Classic Era
-- and Burning Crusade; WoW: Forever has C_PetInfo.CanPetEatItem).
---@type table<number, LibTameableFoodKind>
lib.foods = {}
-- Per family the kinds of food it eats, as the client's CreatureFamily.PetFoodMask says (on the
-- same clients).
---@type table<number, table<LibTameableFoodKind, true>>
lib.diets = {}

---@type table<number, LibTameableRank>
lib.ranks = {}
---@type table<number, LibTameableBeast>
lib.beasts = {}
-- Built on first use from the data: per NPC its ranks, per ability its ranks in order, per kind of
-- teacher (rare or normal) each rank's teachers of that kind.
---@type table<number, number[]>?
lib.teaches = nil
---@type table<number, number[]>?
lib.abilityRanks = nil
---@type table<string, table<number, number[]>>
lib.byKind = {}

---Fresh tables for a data file to fill, or nil when it is not the running client's or was built
---for another version of the library (an older copy embedded by another addon).
---@param client string
---@param minor number
---@return table<number, LibTameableRank>? ranks
---@return table<number, LibTameableBeast>? beasts
function lib:NewData(client, minor)
    if client ~= self.client or minor ~= MINOR then return nil, nil end
    self.ranks, self.beasts, self.teaches, self.abilityRanks, self.byKind = {}, {}, nil, nil, {}
    return self.ranks, self.beasts
end

---Fresh tables for a food data file to fill (each item's kind, each family's diet), on the same
---terms as NewData.
---@param client string
---@param minor number
---@return table<number, LibTameableFoodKind>? foods
---@return table<number, table<LibTameableFoodKind, true>>? diets
function lib:NewFoods(client, minor)
    if client ~= self.client or minor ~= MINOR then return nil, nil end
    self.foods, self.diets = {}, {}
    return self.foods, self.diets
end

---Whether a pet family eats an item: false for one that is no pet food, nil where the library
---cannot say (a family not on this client, a client without food data).
---@param family number CreatureFamily ID
---@param itemID number
---@return boolean?
function lib:CanEat(family, itemID)
    local diet = self.diets[family]
    if not diet then return nil end
    local kind = self.foods[itemID]
    return kind ~= nil and diet[kind] == true
end

---The kind of pet food an item is (lib.foodKinds), nil for an item that is no pet food or on a
---client without food data (HasFoodData).
---@param itemID number
---@return LibTameableFoodKind?
function lib:GetFoodKind(itemID)
    return self.foods[itemID]
end

---Whether the library knows the food kinds on this client.
---@return boolean
function lib:HasFoodData()
    return next(self.foods) ~= nil
end

---The running client's name in the library ("era", "tbc", "forever"), nil on one it has no data
---for.
---@return string?
function lib:GetClient()
    return self.client
end

---Whether the library has data on this client.
---@return boolean
function lib:HasData()
    return next(self.ranks) ~= nil
end

---A pet ability rank: its ability (the rank 1 spell ID), rank number and the pet level it needs.
---@param spellID number
---@return number? ability
---@return number? rank
---@return number? level
function lib:GetRank(spellID)
    local info = self.ranks[spellID]
    if not info then return nil end
    return info.ability, info.rank, info.level
end

---Everything about a pet ability rank.
---@param spellID number
---@return LibTameableRank?
function lib:GetRankInfo(spellID)
    return self.ranks[spellID]
end

---The ranks of an ability, lowest first, by any of its ranks' spell IDs.
---@param spellID number
---@return number[]?
function lib:GetAbilityRanks(spellID)
    local info = self.ranks[spellID]
    if not info then return nil end
    if not self.abilityRanks then
        local byAbility = {}
        for id, rank in pairs(self.ranks) do
            local list = byAbility[rank.ability]
            if not list then
                list = {}
                byAbility[rank.ability] = list
            end
            list[#list + 1] = id
        end
        local ranks = self.ranks
        local function lower(a, b)
            return ranks[a].rank < ranks[b].rank
        end
        for _, list in pairs(byAbility) do
            table.sort(list, lower)
        end
        self.abilityRanks = byAbility
    end
    return self.abilityRanks[info.ability]
end

---Whether a pet family can learn a rank.
---@param family number CreatureFamily ID
---@param spellID number
---@return boolean
function lib:CanLearn(family, spellID)
    local info = self.ranks[spellID]
    if not info then return false end
    if #info.families == 0 then return true end
    for _, f in ipairs(info.families) do
        if f == family then return true end
    end
    return false
end

---Which teachers GetTeachers gives: every one, only rares (a long wait at one spawn point), or
---only beasts that are not rare.
lib.kinds = { all = "all", rare = "rare", normal = "normal" }

---The beasts that teach a rank, by NPC ID: an empty list for a rank no beast (of that kind)
---teaches, nil for a spell that is not a rank.
---@param spellID number
---@param kind LibTameableKind? lib.kinds: all (the default), rare or normal
---@return number[]?
function lib:GetTeachers(spellID, kind)
    local info = self.ranks[spellID]
    if not info or not kind or kind == "all" then return info and info.teachers end
    local byKind = self.byKind[kind]
    if not byKind then
        byKind = {}
        self.byKind[kind] = byKind
    end
    local list = byKind[spellID]
    if not list then
        local rare = kind == "rare"
        list = {}
        for _, npc in ipairs(info.teachers) do
            if (self.beasts[npc].rare == true) == rare then list[#list + 1] = npc end
        end
        byKind[spellID] = list
    end
    return list
end

---The ranks a beast teaches, by spell ID, or nil for a beast that teaches none.
---@param npcID number
---@return number[]?
function lib:GetTeaches(npcID)
    if not self.teaches then
        local teaches = {}
        for id, rank in pairs(self.ranks) do
            for _, npc in ipairs(rank.teachers) do
                local list = teaches[npc]
                if not list then
                    list = {}
                    teaches[npc] = list
                end
                list[#list + 1] = id
            end
        end
        for _, list in pairs(teaches) do
            table.sort(list)
        end
        self.teaches = teaches
    end
    return self.teaches[npcID]
end

---A beast that teaches a rank.
---@param npcID number
---@return LibTameableBeast?
function lib:GetBeast(npcID)
    return self.beasts[npcID]
end

---Every rank, by spell ID (pairs order).
---@return fun(t: table, k: number?): number, LibTameableRank
---@return table<number, LibTameableRank>
function lib:IterateRanks()
    return next, self.ranks
end

---Every teaching beast, by NPC ID (pairs order).
---@return fun(t: table, k: number?): number, LibTameableBeast
---@return table<number, LibTameableBeast>
function lib:IterateBeasts()
    return next, self.beasts
end
