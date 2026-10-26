## Ordinary eligibility through real Spawner.plan, with dry ground and no village exclusions.
extends SceneTree

const Model := preload("res://ontology/model.gd")
const WorldGen := preload("res://game/world/world_gen.gd")
const Spawner := preload("res://game/world/spawner.gd")

var failed := 0


func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: ", label)


func _init() -> void:
	var o := Model.Ontology.load_dir("res://ontology/instances")
	check(o.validate(), "ontology valid")
	var d: Dictionary = o.configs.generators.design.duplicate(true)
	# Isolate eligibility, not random group absence, terrain or settlement rejection.
	d.spawns["groups-per-zone"] = [2, 2]
	d.settlement = {}
	var g := WorldGen.new(26879, d, o.landscapes)
	g._h_base = 255
	g._h_amp = 0
	check(g.height_at(32, 32) > g.sea_level, "fixture ground is dry")
	var zone := Vector2i.ZERO
	var land = g.land_of_block(32, 32)
	var rosters := {land.landscape: ["hell-demon"]}
	check(
		(
			o.creatures["hell-demon"].boss_species
			and o.creatures["hell-demon"].category == Model.CreatureCategory.DEMON
		),
		"Hell Demon is always boss independently of category"
	)
	check(
		Spawner.plan(g, zone, d, o.creatures, rosters, 6, 10).is_empty(),
		"Hell Demon-only roster produces no ordinary groups"
	)
	rosters[land.landscape] = ["wolf"]
	var ordinary := Spawner.plan(g, zone, d, o.creatures, rosters, 6, 10)
	check(ordinary.size() == 2, "dry ordinary control actually produces both groups")
	rosters[land.landscape] = ["hell-demon", "wolf"]
	check(
		Spawner.plan(g, zone, d, o.creatures, rosters, 6, 10) == ordinary,
		"mixed roster retains wolf groups, positions, role, levels, stats and RNG draws"
	)
	rosters[land.landscape] = ["witch"]
	check(
		o.creatures["witch"].boss_capable and not o.creatures["witch"].boss_species,
		"witch control is boss-capable, not always boss"
	)
	var capable := Spawner.plan(g, zone, d, o.creatures, rosters, 6, 10)
	check(capable.size() == 2, "ordinary boss-capable witch remains eligible")
	for group in capable:
		check(
			group.species == &"witch" and group.role == "mage", "witch identity and role retained"
		)
	# Clear only the boss flag in a copied troll: category alone must still exclude it.
	var creatures: Dictionary = o.creatures.duplicate()
	creatures["troll"] = o.creatures["troll"].duplicate()
	creatures["troll"].boss_species = false
	for id in ["troll", "scarecrow", "egg", "missing-species"]:
		rosters[land.landscape] = [id]
		check(
			Spawner.plan(g, zone, d, creatures, rosters, 6, 10).is_empty(),
			"retained category/unknown-species exclusion: " + id
		)
		rosters[land.landscape] = [id, "wolf"]
		check(
			Spawner.plan(g, zone, d, creatures, rosters, 6, 10) == ordinary,
			"excluded entry leaves ordinary plan unchanged: " + id
		)
	print("spawner eligibility ok" if failed == 0 else "spawner eligibility FAILED %d" % failed)
	quit(0 if failed == 0 else 1)
