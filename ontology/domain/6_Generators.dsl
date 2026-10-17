// Authoritative domain records. source.* coordinates refer only to baseline 175e0c59b6a05ead62d29bd851085cd5a3818378.
r_6_6_generators = element "6-6-generators" "SectionNote" {
    tags "SectionNote,Overview"
    properties {
        "id" "6-6-generators"
        "kind" "SectionNote"
        "order" "1"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "1"
        "source.end" "29"
        "title" "6. Generators"
        "heading.level" "2"
        "heading.slug" "6-generators"
        "section" "Overview"
        "note.001.kind" "paragraph"
        "note.001.line.001.state" "text"
        "note.001.line.001.text" "Procedural systems. Config + invariants in `instances/generators.json`. Seeds make output"
        "note.001.line.002.state" "text"
        "note.001.line.002.text" "reproducible; each generator lists invariants that a test can assert."
        "note.001.source.file" "6_Generators.md"
        "note.001.source.start" "3"
        "note.001.source.end" "4"
        "note.002.kind" "catalog-table"
        "note.002.column.001.text" "id"
        "note.002.column.002.text" "input"
        "note.002.column.003.text" "output"
        "note.002.column.004.text" "invariants"
        "note.002.row.001.target" "gen-world"
        "note.002.row.002.target" "gen-climate"
        "note.002.row.003.target" "gen-terrain"
        "note.002.row.004.target" "gen-coarse-map"
        "note.002.row.005.target" "gen-flora"
        "note.002.row.006.target" "gen-settlement"
        "note.002.row.007.target" "gen-dungeon"
        "note.002.row.008.target" "gen-poi"
        "note.002.row.009.target" "gen-missions"
        "note.002.row.010.target" "gen-spawns"
        "note.002.row.011.target" "gen-boss"
        "note.002.row.012.target" "gen-name"
        "note.002.row.013.target" "gen-item"
        "note.002.row.014.target" "gen-item-stats"
        "note.002.row.015.target" "gen-loot"
        "note.002.row.016.target" "gen-realm"
        "note.002.row.017.target" "gen-npc-appearance"
        "note.002.row.018.target" "gen-schedule"
        "note.002.row.019.target" "gen-key-items"
        "note.002.source.file" "6_Generators.md"
        "note.002.source.start" "6"
        "note.002.source.end" "26"
    }
}

r_gen_world = element "gen-world" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-world"
        "kind" "Generator"
        "order" "8"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "8"
        "source.end" "8"
        "display.state" "text"
        "display.text" "gen-world"
        "input.state" "text"
        "input.text" "seed"
        "output.state" "text"
        "output.text" "hybrid: finite 1024×1024 grid of internal regions → lands; reference generation neighbourhood: region data 3×3 around player, region seeds 7×7"
        "invariants.state" "text"
        "invariants.text" "same seed = same generation/geography, not mutable saved-world identity (§3.7); hybrid coordinates −512..511 on each horizontal axis, no wrapping (c-world-bounds); live `world-scales.invariants` “no borders” wording is not hybrid authority"
    }
}

r_gen_climate = element "gen-climate" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-climate"
        "kind" "Generator"
        "order" "9"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "9"
        "source.end" "9"
        "display.state" "text"
        "display.text" "gen-climate"
        "input.state" "text"
        "input.text" "seed, x, y"
        "output.state" "text"
        "output.text" "temperature, humidity, continent, relief → landscape choice (rules: `design.climate`)"
        "invariants.state" "text"
        "invariants.text" "equal-sized lands; hybrid v1 includes Wetlands, never a separate Swamp Lands biome (§3.1 landscape); features can appear off-biome (volcano in snow)"
    }
}

r_gen_terrain = element "gen-terrain" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-terrain"
        "kind" "Generator"
        "order" "10"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "10"
        "source.end" "10"
        "display.state" "text"
        "display.text" "gen-terrain"
        "input.state" "text"
        "input.text" "land, zone coords"
        "output.state" "text"
        "output.text" "heightfield columns, caves, rivers+waterfalls, lakes, mountains/plateaus, mesas, overhangs; per-voxel RGB by block type & landscape palette"
        "invariants.state" "text"
        "invariants.text" "walkable roads with tunnels/bridges; water at rivers/lakes/oceans; own-design water level and noise: `design.terrain` (D12); the fBm heightfield-only slice is not the final terrain ceiling"
    }
}

r_gen_coarse_map = element "gen-coarse-map" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-coarse-map"
        "kind" "Generator"
        "order" "11"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "11"
        "source.end" "11"
        "display.state" "text"
        "display.text" "gen-coarse-map `Ω`"
        "input.state" "text"
        "input.text" "land seed"
        "output.state" "text"
        "output.text" "coarse map placing streets, buildings, rivers, bridges, trees, caves logically before voxel detail"
        "invariants.state" "text"
        "invariants.text" "every structure reachable by road"
    }
}

r_gen_flora = element "gen-flora" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-flora"
        "kind" "Generator"
        "order" "12"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "12"
        "source.end" "12"
        "display.state" "text"
        "display.text" "gen-flora"
        "input.state" "text"
        "input.text" "landscape, zone"
        "output.state" "text"
        "output.text" "trees (procedural, unique), bushes, scrubs, cacti, flowers, mushrooms, fields"
        "invariants.state" "text"
        "invariants.text" "per-landscape rosters"
    }
}

r_gen_settlement = element "gen-settlement" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-settlement"
        "kind" "Generator"
        "order" "13"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "13"
        "source.end" "13"
        "display.state" "text"
        "display.text" "gen-settlement"
        "input.state" "text"
        "input.text" "land"
        "output.state" "text"
        "output.text" "1 (hybrid / A) / n (S) settlements: districts, procedural buildings (rooms, sizes, roofs), styles, NPC population + schedules, shops, inn, trainers, flight master (S)"
        "invariants.state" "text"
        "invariants.text" "≥1 inn (A several, S exactly 1); shops per district; hybrid placement/layout tuning `design.settlement` (D22), slice limits under [settlement (locator=settlement)](3_Classes.dsl)"
    }
}

r_gen_dungeon = element "gen-dungeon" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-dungeon"
        "kind" "Generator"
        "order" "14"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "14"
        "source.end" "14"
        "display.state" "text"
        "display.text" "gen-dungeon"
        "input.state" "text"
        "input.text" "land, dungeon-type, tier"
        "output.state" "text"
        "output.text" "layout (A linear + dead end; S room gauntlet), traps `A`, chests, spawns in groups 2–4, boss(es), artifact `S`, locks needing key items"
        "invariants.state" "text"
        "invariants.text" "entrance rules per type; at least one boss; artifact at end (S castles always); hybrid enemy refresh eligibility/timing and permanent claims follow c-midnight-reset"
    }
}

r_gen_poi = element "gen-poi" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-poi"
        "kind" "Generator"
        "order" "15"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "15"
        "source.end" "15"
        "display.state" "text"
        "display.text" "gen-poi"
        "input.state" "text"
        "input.text" "land"
        "output.state" "text"
        "output.text" "campsites, arenas, towers ≤5, circles, portals, pumps, trees, shrines, lore sites, spawner nests, hidden treasure, sky islands"
        "invariants.state" "text"
        "invariants.text" "counts in `c-land-count`"
    }
}

r_gen_missions = element "gen-missions" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-missions"
        "kind" "Generator"
        "order" "16"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "16"
        "source.end" "16"
        "display.state" "text"
        "display.text" "gen-missions"
        "input.state" "text"
        "input.text" "land, day"
        "output.state" "text"
        "output.text" "A: 8×8 cell boss missions; S: typed missions with icons and tiers, daily regeneration"
        "invariants.state" "text"
        "invariants.text" "tier ladder white→yellow present; S: gnomes/books once per land; hybrid refresh and source claims follow c-midnight-reset / §3.7 save-data"
    }
}

r_gen_spawns = element "gen-spawns" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-spawns"
        "kind" "Generator"
        "order" "17"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "17"
        "source.end" "17"
        "display.state" "text"
        "display.text" "gen-spawns"
        "input.state" "text"
        "input.text" "zone, land level/tier"
        "output.state" "text"
        "output.text" "creature spawns: species by landscape roster, group sizes, hostility, humanoid class/spec, `+1..+4` multipliers (A), boss-ification chance; open-world numbers `design.spawns` (D14); role per group: creature combat-role, unset resolves to `design.creature-roles.default` (melee), any-class rolled from weighted `design.creature-roles.any-class` (D26)"
        "invariants.state" "text"
        "invariants.text" "dungeon mobs above surface tier; farm animals white"
    }
}

r_gen_boss = element "gen-boss" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-boss"
        "kind" "Generator"
        "order" "18"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "18"
        "source.end" "18"
        "display.state" "text"
        "display.text" "gen-boss"
        "input.state" "text"
        "input.text" "spawn"
        "output.state" "text"
        "output.text" "named, enlarged, coloured-tier variant with 1–2 random special moves; always-boss species; one fixed-type/level spirit cube per eligible non-mission boss kill (A / hybrid)"
        "invariants.state" "text"
        "invariants.text" "size scaling rule; terrain breaking; mission bosses, including Saurians, drop no spirit cube; normal mission rewards unchanged"
    }
}

r_gen_name = element "gen-name" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-name"
        "kind" "Generator"
        "order" "19"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "19"
        "source.end" "19"
        "display.state" "text"
        "display.text" "gen-name"
        "input.state" "text"
        "input.text" "seed, kind"
        "output.state" "text"
        "output.text" "land names (`<Name> Plains…`, syllables and landscape suffixes: `design.names`), dungeon names (\"Castle ___\"), realm/leader/capital names, item names (affix + material + type + of-name), boss names, NPC names, quarter names"
        "invariants.state" "text"
        "invariants.text" "epic/legendary items always named"
    }
}

r_gen_item = element "gen-item" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-item"
        "kind" "Generator"
        "order" "20"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "20"
        "source.end" "20"
        "display.state" "text"
        "display.text" "gen-item"
        "input.state" "text"
        "input.text" "tier/level, rarity roll, type, material, land (S)"
        "output.state" "text"
        "output.text" "`item` with modifier roll; stats via `gen-item-stats`"
        "invariants.state" "text"
        "invariants.text" "rarity ≤ legendary except mythical bug"
    }
}

r_gen_item_stats = element "gen-item-stats" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-item-stats"
        "kind" "Generator"
        "order" "21"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "21"
        "source.end" "21"
        "display.state" "text"
        "display.text" "gen-item-stats `A` base / hybrid"
        "input.state" "text"
        "input.text" "item"
        "output.state" "text"
        "output.text" "damage/HP/armor/resi/regen/tempo/crit from coremaze base curves: `curve(n,rarity) = 2^((1 − 1/((n−1)·0.05+1))·3) · 2^(rarity·0.25)`, `curve2 = curve/8`, `n = level + 0.1·upgrade_count`; per-type k and material multipliers; hybrid HP uses the fixed rule in [§3.4 item (locator=item)](3_Classes.dsl), other stat rules unchanged"
        "invariants.state" "text"
        "invariants.text" "base curve monotone in level and rarity; modifier roll ∈ 0..20, normalized roll = roll/20, distinct from rarity; modifier roll never affects hybrid gear HP"
    }
}

r_gen_loot = element "gen-loot" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-loot"
        "kind" "Generator"
        "order" "22"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "22"
        "source.end" "22"
        "display.state" "text"
        "display.text" "gen-loot"
        "input.state" "text"
        "input.text" "source level, species, seed"
        "output.state" "text"
        "output.text" "drops per `loot-rule`: coins, gear via `gen-item`, consumables, species items; numbers `design.loot` (D18)"
        "invariants.state" "text"
        "invariants.text" "level = source ± spread, ≥ 1; rarity ≤ legendary; same seed = same drops; bosses +1 rarity (S)"
    }
}

r_gen_realm = element "gen-realm" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-realm"
        "kind" "Generator"
        "order" "23"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "23"
        "source.end" "23"
        "display.state" "text"
        "display.text" "gen-realm `S`"
        "input.state" "text"
        "input.text" "region cluster seed"
        "output.state" "text"
        "output.text" "realm kind, names, leader bio, capital, lore sites, artifact set"
        "invariants.state" "text"
        "invariants.text" "100 % lore ⇒ all artifacts revealed"
    }
}

r_gen_npc_appearance = element "gen-npc-appearance" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-npc-appearance"
        "kind" "Generator"
        "order" "24"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "24"
        "source.end" "24"
        "display.state" "text"
        "display.text" "gen-npc-appearance"
        "input.state" "text"
        "input.text" "race, gender, seed"
        "output.state" "text"
        "output.text" "head/hair model ids, hair RGB, part scales (Ω: fully procedural bodies, expressions)"
        "invariants.state" "text"
        "invariants.text" "asset counts in `races.json`"
    }
}

r_gen_schedule = element "gen-schedule" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-schedule"
        "kind" "Generator"
        "order" "25"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "25"
        "source.end" "25"
        "display.state" "text"
        "display.text" "gen-schedule"
        "input.state" "text"
        "input.text" "settlement"
        "output.state" "text"
        "output.text" "daily A* paths for villagers; lantern at night; campsite rests"
        "invariants.state" "text"
        "invariants.text" "sleep at night"
    }
}

r_gen_key_items = element "gen-key-items" "Generator" {
    tags "Generator,Catalog"
    properties {
        "id" "gen-key-items"
        "kind" "Generator"
        "order" "26"
        "source.commit" "175e0c59b6a05ead62d29bd851085cd5a3818378"
        "source.status" "historical baseline coordinates"
        "source.file" "6_Generators.md"
        "source.start" "26"
        "source.end" "26"
        "display.state" "text"
        "display.text" "gen-key-items `S`"
        "input.state" "text"
        "input.text" "land"
        "output.state" "text"
        "output.text" "subset of the 9 key items consistent with locks present"
        "invariants.state" "text"
        "invariants.text" "`c-key-item-need`"
    }
}
