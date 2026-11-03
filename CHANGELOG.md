# Changelog

## Unreleased

- GetRank, GetRankInfo, GetAbilityRanks, CanLearn, GetTeachers, GetTeaches,
  GetBeast, IterateRanks, IterateBeasts, HasData and GetClient.
- GetTeachers takes a kind: every teacher, only rares or only the rest.
- Data for Classic Era, Burning Crusade Classic and WoW: Forever.
- Each beast's attack speed on Classic Era and WoW: Forever (beast.speed, from
  CMaNGOS' MeleeBaseAttackTime; on Forever for the beasts with Classic's NPC
  ID): a tamed beast keeps it on those clients.
- GetFoodKind and HasFoodData: each item's kind of pet food on Classic Era and
  Burning Crusade; CanEat: whether a family eats an item, by the client's own
  diets.
