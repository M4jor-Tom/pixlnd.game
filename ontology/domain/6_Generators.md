## 6. Generators

Procedural systems. Config + invariants in `instances/generators.json`. Reproducibility assumes
equal relevant seed, coordinates, input data, design/configuration and generator/engine revision;
stateful rolls also require the same RNG state and call context. Each generator lists invariants
that a test can assert. Seed equality alone neither identifies a saved world nor restores its
mutable history (kills, claims, purchases or current incarnations). Current saves retain generated
land/site assignments separately from mutable state and validate them against current generation;
they do not serialize generator/engine revision pins or promise cross-version bit identity.
For the initial hybrid families, settlement/terrain, dungeon/mission, spawn/boss and loot
generation must jointly satisfy the [encounter contracts](encounter-contracts.md) and
`c-initial-encounters`, including persistent special/spirit assignments, shared rewards, safe
renewal and the initial permanent-source exclusion. These scoped rules override generic/reference
rows below where applicable; documentation does not authorize implementation.

| id | input | output | invariants |
|---|---|---|---|
| gen-world | seed | hybrid: finite 1024×1024 grid of internal regions → lands; reference generation neighbourhood: region data 3×3 around player, region seeds 7×7 | same seed and relevant generation inputs/revisions (above) = same generation/geography, not mutable saved-world identity (§3.7); hybrid coordinates −512..511 on each horizontal axis, no wrapping (c-world-bounds); active `design.terrain.lands-per-axis` specifies the finite width; `world-scales` retains historical scales |
| gen-climate | seed, x, y | temperature, humidity, continent, relief → landscape choice (rules: `design.climate`) | equal-sized lands; hybrid v1 includes Wetlands, never a separate Swamp Lands biome (§3.1 landscape); features can appear off-biome (volcano in snow) |
| gen-terrain | land, zone coords | heightfield columns, caves, rivers+waterfalls, lakes, mountains/plateaus, mesas, overhangs; per-voxel RGB by block type & landscape palette | walkable roads with tunnels/bridges; water at rivers/lakes/oceans; own-design water level and noise: `design.terrain` (D12); the fBm heightfield-only slice is not the final terrain ceiling |
| gen-coarse-map `Ω` | land seed | coarse map placing streets, buildings, rivers, bridges, trees, caves logically before voxel detail | every structure reachable by road |
| gen-flora | landscape, zone | trees (procedural, unique), bushes, scrubs, cacti, flowers, mushrooms, fields | per-landscape rosters |
| gen-settlement | land | 1 (hybrid / A) / n (S) settlements: districts, procedural buildings (rooms, sizes, roofs), styles, NPC population + schedules, shops, inn, trainers, flight master (S) | ≥1 inn (A several, S exactly 1); shops per district; hybrid placement/layout tuning `design.settlement` (D22), slice limits under [settlement](3_Classes.md#settlement) |
| gen-dungeon | land, dungeon-type, tier | layout (A linear + dead end; S room gauntlet), traps `A`, chests, spawns in groups 2–4, boss(es), artifact `S`, locks needing key items | entrance rules per type; at least one boss; artifact at end (S castles always); hybrid enemy refresh eligibility/timing and permanent claims follow c-midnight-reset; future required content obeys c-required-content-solvability |
| gen-poi | land | campsites, arenas, towers ≤5, circles, portals, pumps, trees, shrines, lore sites, spawner nests, hidden treasure, sky islands | counts in `c-land-count` |
| gen-missions | land, day | A: 8×8 cell boss missions; S: typed missions with icons and tiers, daily regeneration | tier ladder white→yellow present; S: gnomes/books once per land; hybrid daily regeneration obeys [site stability](3_Classes.md#mission-type); refresh, rescue completion and source claims follow c-midnight-reset / c-supplier-rescue / §3.7 save-data; future required content obeys c-required-content-solvability |
| gen-spawns | zone, land level/tier | creature spawns: species by landscape roster, group sizes, hostility, humanoid class/spec, `+1..+4` multipliers (A), boss-ification chance; open-world numbers `design.spawns` (D14); role per group: creature combat-role, unset resolves to `design.creature-roles.default` (melee), any-class rolled from weighted `design.creature-roles.any-class` (D26) | dungeon mobs above surface tier; farm animals white |
| gen-boss | spawn | named, enlarged, coloured-tier variant; generic/reference 1–2 random special moves, but initial hybrid bosses use the [single-special profile](encounter-contracts.md#boss-specials-and-breakable-rubble); always-boss species; one fixed-type/level spirit cube per eligible non-mission boss kill (A / hybrid) | size scaling and scoped terrain breaking; mission bosses, including Saurians, drop no spirit cube; initial hybrid [guaranteed gear/spirits](encounter-contracts.md#guaranteed-boss-gear-and-spirits) convert distinct current-boss gear and initial-boss spirit source levels to [item power](3_Classes.md#item), without spread |
| gen-name | seed, kind | land names (`<Name> Plains…`, syllables and landscape suffixes: `design.names`), dungeon names ("Castle ___"), realm/leader/capital names, item names (affix + material + type + of-name), boss names, NPC names, quarter names | epic/legendary items always named |
| gen-item | hybrid bounded item power (source level already converted), rarity roll, type, material, land (S reference) | `item` with modifier roll; stats via `gen-item-stats` | rarity ≤ legendary except mythical bug |
| gen-item-stats `A` base / hybrid | item | damage/HP/armor/resi/regen/tempo/crit from coremaze base curves: `curve(n,rarity) = 2^((1 − 1/((n−1)·0.05+1))·3) · 2^(rarity·0.25)`, `curve2 = curve/8`, `n = level + 0.1·upgrade_count`; per-type k and material multipliers; hybrid HP uses `design.gear-hp` plus material/slot inputs under the fixed rule in [§3.4 item](3_Classes.md#item), other stat rules unchanged | item `level` is bounded item power, not source level; base curve monotone in item power and rarity; modifier roll ∈ 0..20, normalized roll = roll/20, distinct from rarity; modifier roll never affects hybrid gear HP |
| gen-loot | source level, species, seed | drops per `loot-rule`: coins, gear via `gen-item`, consumables, species items; numbers `design.loot` (D18) | hybrid gear/consumables: convert source level first, then spread in power points and clamp +1…+100 under [item power](3_Classes.md#item); coins/XP retain source-level units; rarity ≤ legendary; same seed = same drops; bosses +1 rarity (S) |
| gen-realm `S` | region cluster seed | realm kind, names, leader bio, capital, lore sites, artifact set | 100 % lore ⇒ all artifacts revealed |
| gen-npc-appearance | race, gender, seed | head/hair model ids, hair RGB, part scales (Ω: fully procedural bodies, expressions) | asset counts in `races.json` |
| gen-schedule | settlement | daily A* paths for villagers; lantern at night; campsite rests | sleep at night |
| gen-key-items `S` | land | subset of the 9 key items consistent with locks present | `c-key-item-need`; future hybrid required-content dependencies also obey c-required-content-solvability |

### Future required-content solvability

Hybrid future dungeon/mission completion objectives and their guaranteed rewards must each
have at least one lawful, noncircular progression route for a **fresh solo character of any
class within the same saved world** (`c-required-content-solvability`). Training, respecializing
and visiting other lands may be necessary; importing capabilities from another world must not
be necessary. Routes must respect existing key acquisition, [training](3_Classes.md#skill-tree-a),
[equipment eligibility](3_Classes.md#power-gate-a), the single special slot and stamina costs.
A required key cannot be obtainable only behind its own lock; a required gliding route is valid
only if the character can first obtain, train for and equip the glider. A route cannot require
Boat and Hang Glider equipped together or treat Climbing Spikes as removing stamina costs.

This guarantees eventual accessibility, not immediate access or easy combat. Optional secrets
outside completion requirements are excluded. The same guarantee applies to artifact/book
sources **when their separately authorized placement contracts arrive**; it adds no sources or
acquisition/numerical defaults now. Existing [six-site access](encounter-contracts.md#placement-and-access)
and [initial permanent-source exclusion](encounter-contracts.md#initial-permanent-source-scope)
remain unchanged. Generated-output/runtime verification remains deferred; this is not proof
of enforcement by the current validator.

---

