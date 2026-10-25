# LibTameable-1.0

[![CI](https://github.com/Langmans/LibTameable-1.0/actions/workflows/ci.yml/badge.svg)](https://github.com/Langmans/LibTameable-1.0/actions/workflows/ci.yml)
![Coverage](https://img.shields.io/badge/coverage-100%25-brightgreen)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue)](https://github.com/Langmans/LibTameable-1.0/blob/main/LICENSE)

A library with the hunter pet abilities each tameable beast teaches, and where
to find that beast. On the clients where a hunter learns pet abilities from the
beasts they tame (Beast Training, removed in patch 3.0.2):

| Client | Ranks | Teaching beasts |
|---|---|---|
| Classic Era (Season of Discovery, Hardcore) | 59 | 302 |
| Burning Crusade Classic | 97 | 357 |
| WoW: Forever | 106 | 409 |

On any other client (Wrath and later, where pets learn by themselves) the
library loads but has no data: `HasData()` is false.

## Use

```lua
local Tameable = LibStub("LibTameable-1.0")

if Tameable:HasData() then
    -- A rank: its ability (the rank 1 spell ID), rank number, the pet level it needs.
    local ability, rank, level = Tameable:GetRank(17255) -- Bite 2: 17253, 2, 8

    -- The ranks of an ability, lowest first, from any of its spell IDs.
    local ranks = Tameable:GetAbilityRanks(17253)

    -- Who teaches it: every beast, only rares (a wait at one spawn point), or only the rest.
    local all = Tameable:GetTeachers(17255)
    local rares = Tameable:GetTeachers(17255, Tameable.kinds.rare)
    local noCamping = Tameable:GetTeachers(17255, Tameable.kinds.normal)

    -- What a beast teaches, and the beast itself: name, family, levels, rare/elite, where, and its
    -- display ID (beast.display) for a model that needs no creature in the client's cache.
    local teaches = Tameable:GetTeaches(2753) -- Barnabus: { 17259 } (Bite 6)
    local beast = Tameable:GetBeast(2753)
    -- beast.pins[uiMapID] = { x1, y1, x2, y2, ... } in percent; beast.radii[uiMapID] = { r1, r2, ... },
    -- each pin's area (the circle that holds its spawns), in percent; beast.zones = { areaID } in an instance

    -- Whether a family can learn a rank (Tameable.families.cat, ...).
    local can = Tameable:CanLearn(Tameable.families.crocolisk, 16831) -- Claw 5: false

    for spellID, info in Tameable:IterateRanks() do end
    for npcID, beast in Tameable:IterateBeasts() do end
end

-- What kind of pet food an item is (Tameable.foodKinds: meat, fish, cheese, bread, fungus,
-- fruit, rawFish), on Classic Era and Burning Crusade, which have no API for it. WoW: Forever
-- has C_PetInfo.CanPetEatItem: HasFoodData() is false there.
if Tameable:HasFoodData() then
    local kind = Tameable:GetFoodKind(117) -- Tough Jerky: "meat"
    -- Whether a family eats it, by the client's own diets: true, false, or nil when unknown.
    local eats = Tameable:CanEat(Tameable.families.wolf, 414) -- Dalaran Sharp: false
end
```

Lists and tables the library returns are its own: read them, never change them.
A beast teaches its pet spells even when its own family cannot learn them: the
Drywallow Snapper, a crocolisk, teaches Claw 5 to a hunter who trains it to a cat.

## Embedding

Include `lib.xml` after LibStub. It loads the library and every client's data
file; only the running client's fills the tables, so the others cost no memory.
An addon with a .toc per client can load less: `LibTameable-1.0.lua`, then only
its client's `Data\<Client>.lua` (and `Data\<Client>Food.lua` for Era and TBC).
When several addons embed the library, the newest copy (MINOR) wins and takes
only data files of its own version.

## Where the data comes from

- **Classic Era and Burning Crusade.** A tamed beast keeps the pet spells it had
  in the wild, its `CreatureSpellData` set, and the hunter learns them from it.
  The sets and the ranks (name, rank, pet level, which families learn it) are the
  client's own game tables. Which beast has which set, and the beasts' level,
  rarity and spawn points, is server data: it comes from the
  [CMaNGOS](https://github.com/cmangos) `classic-db` and `tbc-db` databases
  (GPL-3.0), which is why this library is GPL-3.0 too. Spawn points become map
  pins through the client's map tables. Where CMaNGOS has no spawn for a beast,
  the [Tamed](https://github.com/moody/Tamed) addon's (MIT, `Data\Tamed-LICENSE.txt`)
  are used.
- **Food kinds** (Classic Era, Burning Crusade): `item_template.FoodType` from
  the same CMaNGOS databases.
- **WoW: Forever.** From Wowhead's Forever database, with the teachers it does
  not link taken from comments on its spell pages and from Tamed.

The data files are generated; they are not edited by hand.

## License

GPL-3.0-or-later (`LICENSE`). World of Warcraft content is Blizzard's.

## Development

```sh
lua tests/check.lua          # StyLua, WoW Lua LS, the tests with 100% line coverage
lua tests/check.lua test     # the tests only
lua tests/check.lua format   # format all Lua
```

`tests/setup-lua.ps1` sets up Lua 5.1 and the test tools on Windows inside
`.lua\`. The language server must resolve every symbol (type coverage 100%).

Releases: MINOR in `LibTameable-1.0.lua` goes up by one with every release and
the tag is the same number; the data files carry the MINOR they were built for,
so they are regenerated with each release. Raise MINOR, regenerate, commit, then
tag: CI fails on a tag that is not MINOR, and a spec on a data file built for
another MINOR. Between releases MINOR stays: an addon embedding the library
pins a commit, and every addon pins the same one while MINOR is unchanged.
