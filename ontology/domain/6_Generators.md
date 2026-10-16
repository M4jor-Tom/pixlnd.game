## 6. Generators

Procedural systems. Config + invariants in `instances/generators.json`. Seeds make output
reproducible; each generator lists invariants that a test can assert.

| id | input | output | invariants |
|---|---|---|---|
| gen-world | seed | hybrid: finite 1024×1024 grid of internal regions → lands; reference generation neighbourhood: region data 3×3 around player, region seeds 7×7 | same seed = same generation/geography, not mutable saved-world identity (§3.7); hybrid coordinates −512..511 on each horizontal axis, no wrapping (c-world-bounds); live `world-scales.invariants` “no borders” wording is not hybrid authority |
| gen-climate | seed, x, y | temperature, humidity, continent, relief → landscape choice (rules: `design.climate`) | equal-sized lands; hybrid v1 includes Wetlands, never a separate Swamp Lands biome (§3.1 landscape); features can appear off-biome (volcano in snow) |
| gen-terrain | land, zone coords | heightfield columns, caves, rivers+waterfalls, lakes, mountains/plateaus, mesas, overhangs; per-voxel RGB by block type & landscape palette | walkable roads with tunnels/bridges; water at rivers/lakes/oceans |
| gen-coarse-map `Ω` | land seed | coarse map placing streets, buildings, rivers, bridges, trees, caves logically before voxel detail | every structure reachable by road |
| gen-flora | landscape, zone | trees (procedural, unique), bushes, scrubs, cacti, flowers, mushrooms, fields | per-landscape rosters |
| gen-settlement | land | 1 (hybrid / A) / n (S) settlements: districts, procedural buildings (rooms, sizes, roofs), styles, NPC population + schedules, shops, inn, trainers, flight master (S) | ≥1 inn (A several, S exactly 1); shops per district; hybrid numbers `design.settlement` (D22) |
| gen-dungeon | land, dungeon-type, tier | layout (A linear + dead end; S room gauntlet), traps `A`, chests, spawns in groups 2–4, boss(es), artifact `S`, locks needing key items | entrance rules per type; at least one boss; artifact at end (S castles always); hybrid enemy refresh eligibility/timing and permanent claims follow c-midnight-reset |
| gen-poi | land | campsites, arenas, towers ≤5, circles, portals, pumps, trees, shrines, lore sites, spawner nests, hidden treasure, sky islands | counts in `c-land-count` |
| gen-missions | land, day | A: 8×8 cell boss missions; S: typed missions with icons and tiers, daily regeneration | tier ladder white→yellow present; S: gnomes/books once per land; hybrid refresh and source claims follow c-midnight-reset / §3.7 save-data |
| gen-spawns | zone, land level/tier | creature spawns: species by landscape roster, group sizes, hostility, humanoid class/spec, `+1..+4` multipliers (A), boss-ification chance; open-world numbers `design.spawns` (D14); role per group: creature combat-role, any-class rolled from `design.creature-roles.any-class` (D26) | dungeon mobs above surface tier; farm animals white |
| gen-boss | spawn | named, enlarged, coloured-tier variant with 1–2 random special moves; always-boss species; one fixed-type/level spirit cube per eligible non-mission boss kill (A / hybrid) | size scaling rule; terrain breaking; mission bosses, including Saurians, drop no spirit cube; normal mission rewards unchanged |
| gen-name | seed, kind | land names (`<Name> Plains…`), dungeon names ("Castle ___"), realm/leader/capital names, item names (affix + material + type + of-name), boss names, NPC names, quarter names | epic/legendary items always named |
| gen-item | tier/level, rarity roll, type, material, land (S) | `item` with modifier roll; stats via `gen-item-stats` | rarity ≤ legendary except mythical bug |
| gen-item-stats `A` base / hybrid | item | damage/HP/armor/resi/regen/tempo/crit from coremaze base curves: `curve(n,rarity) = 2^((1 − 1/((n−1)·0.05+1))·3) · 2^(rarity·0.25)`, `curve2 = curve/8`, `n = level + 0.1·upgrade_count`; per-type k and material multipliers; hybrid HP uses the fixed rule in [§3.4 item](3_Classes.md#item), other stat rules unchanged | base curve monotone in level and rarity; modifier roll ∈ 0..20, normalized roll = roll/20, distinct from rarity; modifier roll never affects hybrid gear HP |
| gen-loot | source level, species, seed | drops per `loot-rule`: coins, gear via `gen-item`, consumables, species items; numbers `design.loot` (D18) | level = source ± spread, ≥ 1; rarity ≤ legendary; same seed = same drops; bosses +1 rarity (S) |
| gen-realm `S` | region cluster seed | realm kind, names, leader bio, capital, lore sites, artifact set | 100 % lore ⇒ all artifacts revealed |
| gen-npc-appearance | race, gender, seed | head/hair model ids, hair RGB, part scales (Ω: fully procedural bodies, expressions) | asset counts in `races.json` |
| gen-schedule | settlement | daily A* paths for villagers; lantern at night; campsite rests | sleep at night |
| gen-key-items `S` | land | subset of the 9 key items consistent with locks present | `c-key-item-need` |

---

