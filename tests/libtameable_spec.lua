-- The library's API on each client, with the data the client's Data file gives it.

local COWER, COWER_2, COWER_5, COWER_6 = 1742, 1753, 1756, 16697
local BITE_2 = 17255
local CLAW_5 = 16831
local DRYWALLOW_SNAPPER, MOTHER_FANG, TIMBER, BARNABUS = 4343, 471, 1132, 2753
local TOUGH_JERKY, DALARAN_SHARP, HEARTHSTONE = 117, 414, 6948

describe("LibTameable on Classic Era", function()
    local client, lib
    before_each(function()
        client = NewClient("era")
        lib = client.lib
    end)

    it("knows the client and has its data", function()
        assert.equal("era", lib:GetClient())
        assert.is_true(lib:HasData())
    end)

    it("gives a rank's ability, number and pet level", function()
        assert.same({ COWER, 2, 15 }, { lib:GetRank(COWER_2) })
        assert.equal(COWER, lib:GetRankInfo(COWER_5).ability)
    end)

    it("has nothing for a spell that is not a pet ability rank", function()
        assert.is_nil(lib:GetRank(133))
        assert.is_nil(lib:GetRankInfo(133))
        assert.is_nil(lib:GetAbilityRanks(133))
        assert.is_nil(lib:GetTeachers(133))
        assert.is_nil(lib:GetTeachers(133, lib.kinds.rare))
        assert.is_false(lib:CanLearn(lib.families.cat, 133))
    end)

    it("lists an ability's ranks lowest first, from any of them", function()
        local ranks = lib:GetAbilityRanks(COWER_5)
        assert.same({ COWER, COWER_2, 1754, 1755, COWER_5, COWER_6 }, ranks)
        assert.equal(ranks, lib:GetAbilityRanks(COWER), "built once, shared")
    end)

    it("says which families can learn a rank", function()
        assert.is_true(lib:CanLearn(lib.families.cat, CLAW_5))
        assert.is_false(lib:CanLearn(lib.families.crocolisk, CLAW_5))
        assert.is_true(lib:CanLearn(lib.families.crocolisk, COWER), "every family learns Cower")
    end)

    it("has a beast teach its spell set, even a rank its own family cannot learn", function()
        assert.truthy(lib:GetBeast(DRYWALLOW_SNAPPER))
        local found = false
        for _, npc in ipairs(lib:GetTeachers(CLAW_5)) do
            if npc == DRYWALLOW_SNAPPER then found = true end
        end
        assert.is_true(found)
    end)

    it("gives the ranks a beast teaches", function()
        local teaches = lib:GetTeaches(BARNABUS)
        assert.same({ 17259 }, teaches)
        assert.equal(teaches, lib:GetTeaches(BARNABUS), "built once, shared")
        assert.is_nil(lib:GetTeaches(1), "a beast that teaches nothing")
    end)

    it("filters a rank's teachers to rares or to the rest", function()
        local all, rare, normal =
            lib:GetTeachers(BITE_2), lib:GetTeachers(BITE_2, lib.kinds.rare), lib:GetTeachers(BITE_2, lib.kinds.normal)
        assert.equal(all, lib:GetTeachers(BITE_2, lib.kinds.all))
        assert.equal(#all, #rare + #normal)
        assert.same({ MOTHER_FANG, TIMBER }, rare)
        for _, npc in ipairs(normal) do
            assert.is_nil(lib:GetBeast(npc).rare)
        end
        assert.equal(rare, lib:GetTeachers(BITE_2, lib.kinds.rare), "built once, shared")
    end)

    it("knows where a beast is: map pins, or the instance's zone", function()
        local snapper = lib:GetBeast(DRYWALLOW_SNAPPER)
        assert.equal(lib.families.crocolisk, snapper.family)
        assert.truthy(snapper.pins[1445], "Dustwallow Marsh")
        assert.same({ 1977 }, lib:GetBeast(11370).zones, "Zul'Gurub")
    end)

    it("iterates every rank and every beast", function()
        local ranks, beasts = 0, 0
        for spellID, info in lib:IterateRanks() do
            assert.equal(info, lib:GetRankInfo(spellID))
            ranks = ranks + 1
        end
        for npc, beast in lib:IterateBeasts() do
            assert.equal(beast, lib:GetBeast(npc))
            beasts = beasts + 1
        end
        assert.equal(59, ranks)
        assert.equal(302, beasts)
    end)

    it("knows what kind of pet food an item is", function()
        assert.equal(lib.foodKinds.meat, lib:GetFoodKind(TOUGH_JERKY))
        assert.equal(lib.foodKinds.cheese, lib:GetFoodKind(DALARAN_SHARP))
        assert.is_nil(lib:GetFoodKind(HEARTHSTONE), "not food")
        assert.is_true(lib:HasFoodData())
    end)

    it("every teacher is a known beast", function()
        for _, info in lib:IterateRanks() do
            for _, npc in ipairs(info.teachers) do
                assert.truthy(lib:GetBeast(npc), npc)
            end
        end
    end)
end)

describe("LibTameable on other clients", function()
    it("has Burning Crusade's families on Burning Crusade Classic", function()
        local lib = NewClient("tbc").lib
        assert.equal("tbc", lib:GetClient())
        assert.equal(lib.families.dragonhawk, lib:GetBeast(15649).family)
        assert.equal(lib.foodKinds.meat, lib:GetFoodKind(TOUGH_JERKY))
    end)

    it("has WoW: Forever's data on WoW: Forever", function()
        local lib = NewClient("forever").lib
        assert.equal("forever", lib:GetClient())
        assert.same({ COWER, 1, 5 }, { lib:GetRank(COWER) })
        assert.is_false(lib:HasFoodData(), "the client says what a pet eats (C_PetInfo.CanPetEatItem)")
        assert.is_nil(lib:GetFoodKind(TOUGH_JERKY))
    end)

    for _, project in ipairs({ "retail", "mists" }) do
        it("has no data where pets learn by themselves (" .. project .. ")", function()
            local lib = NewClient(project).lib
            assert.is_nil(lib:GetClient())
            assert.is_false(lib:HasData())
            assert.is_nil(lib:GetRank(COWER))
            assert.is_nil(lib:GetTeaches(BARNABUS))
        end)
    end
end)

describe("LibTameable's versions", function()
    it("keeps its data when a second addon embeds the same version", function()
        local client = NewClient("era")
        local lib = client:loadAgain()
        assert.equal(client.lib, lib)
        assert.same({ COWER, 2, 15 }, { lib:GetRank(COWER_2) })
    end)

    it("takes data only for its client and its own version", function()
        local lib = NewClient("era").lib
        assert.is_nil(lib:NewData("tbc", 1))
        assert.is_nil(lib:NewData("era", 0), "an older copy's data file")
        assert.is_nil(lib:NewFoods("tbc", 1))
        assert.is_nil(lib:NewFoods("era", 0))
        assert.is_true(lib:HasData(), "refused data leaves the tables alone")
        assert.is_true(lib:HasFoodData())
    end)

    it("starts afresh when its data is given again", function()
        local lib = NewClient("era").lib
        lib:GetTeaches(BARNABUS)
        local ranks = lib:NewData("era", 1)
        assert.same({}, ranks)
        assert.is_false(lib:HasData())
        assert.is_nil(lib:GetTeaches(BARNABUS))
    end)
end)
