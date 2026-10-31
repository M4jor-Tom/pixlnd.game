## Shared untyped ontology state and boundary operations; concrete public types stay in model.gd.
extends RefCounted
const Roles := preload("res://ontology/model_roles.gd")
const Equipment := preload("res://ontology/model_equipment.gd")
const Identity := preload("res://ontology/model_identity.gd")
const Presentation := preload("res://ontology/model_presentation.gd")
const Combat := preload("res://ontology/model_combat.gd")
const Encounters := preload("res://ontology/model_encounters.gd")
const World := preload("res://ontology/model_world.gd")
const Catalogs := preload("res://ontology/model_catalogs.gd")

const Movesets := preload("res://ontology/model_movesets.gd")

const Inputs := preload("res://ontology/model_inputs.gd")
const Provenance := preload("res://ontology/model_provenance.gd")

var races := {}
var classes := {}
var specs := {}
var abilities := {}
var weapon_types := {}
var materials := {}
var rarities := {}
var creatures := {}
var pet_foods := {}
var landscapes := {}
var status_effects := {}
var consumables := {}
var key_items := {}
var rulesets := {}
var configs := {}  # every other instances file, verbatim (ui, keybinds, generators…)
var errors: PackedStringArray = []

const SOURCE_SCOPES = Provenance.SOURCE_SCOPES
const SOURCE_CONTEXT_TAGS = Provenance.SOURCE_CONTEXT_TAGS
const SOURCE_TAGS = Provenance.SOURCE_TAGS
const SOURCE_FIELDS = Provenance.SOURCE_FIELDS


static func _source_tags_valid(tags: Variant) -> bool:
	return Provenance.source_tags_valid(tags)


static func _source_annotation_valid(path: String, field: String, tags: Variant) -> bool:
	return _source_tags_valid(tags) or Provenance.contextual_annotation(path, field, tags)


func _source_value(path: String) -> Variant:
	return Provenance.source_value(configs, path)


static func _within_source(path: String, scope: String) -> bool:
	return Provenance.within_source(path, scope)


## Resolve a raw fact's exact annotations and origin; empty tags mean unresolved, not A+S.
## No mutation of raw source text, no numeric-ID or referenced-definition ancestry.
func source_at(path: String) -> Dictionary:
	return Provenance.source_at(self, path)


# Build diagnostic paths only for failures; validation never caches mutable raw results.
func _source_annotation_errors(value: Variant) -> PackedStringArray:
	return Provenance.source_annotation_errors(self, value)


func _validate_source_annotations(value: Variant, path: String) -> void:
	Provenance.validate_source_annotations(self, value, path)


func _validate_provenance() -> void:
	Provenance.validate_provenance(self)


# §5's finite heterogeneous input inventory, not a schema inferred from current JSON.
const REQUIRED_INPUTS := {
	"catalog":
	"weapon-types materials item-types rarities status-effects creatures landscapes terrain-features flora deposits dungeon-types poi-types factions consumables ingredients crafting-stations key-items npc-roles slash-commands",
	"object":
	"stats.resources stats.stats stats.alpha-item-stat-formulas stats.alpha-character-formulas equipment-slots.extra creature-families.beetles creature-families.runners creature-families.slimes creature-families.alpacas creature-families.dogs creature-families.cats creature-families.golems creature-families.trolls creature-families.skeletons creature-families.sprouts creature-families.guardians creature-families.fish creature-families.landscape-rosters creature-families.forest-dungeon-rosters pet-food.foods pet-food.cut rarities.mob-strength-tiers-s rarities.alpha-relative-colors status-effects.ability-buffs key-items.counts-per-land-s key-items.special-accessories-x consumables.rules factions.realm-name-examples mission-types.alpha mission-types.steam mission-types.steam._shared block-types.alpha block-types.steam block-types.scale block-types.cub-format block-types.alpha.flags static-entities.by-id static-entities.behaviour static-entities.candles recipes.gear-armor-quantities recipes.gear-weapons recipes.refining recipes.recipe-sources recipes.customization recipes.cooking recipes.alchemy buildings.districts buildings.buildings buildings.settlement-styles buildings.population buildings.map-visibility economy.currency economy.incomes economy.prices economy.shops economy.rules economy.loot rulesets.ruleset-hybrid rulesets.ruleset-hybrid.flags keybinds.hybrid controller-profiles.android ui.hud ui.screens ui.options ui.camera slash-commands.chat-rules generators.world-scales generators.seed generators.time generators.climate generators.land generators.terrain generators.settlement generators.dungeon generators.spawns generators.boss generators.names generators.item generators.realm generators.npc-appearance generators.schedule generators.key-items-s generators.coarse-map-omega generators.network-alpha generators.design versions.alpha-to-steam-delta versions.reception generators.design.enemy-level generators.design.enemy-hp generators.design.terrain generators.design.climate generators.design.names generators.design.spawns generators.design.skill-point generators.design.abilities generators.design.resources generators.design.special-attack generators.design.status-effects generators.design.progression generators.design.crit generators.design.movement generators.design.camera generators.design.combat generators.design.defence generators.design.movesets generators.design.creature-roles generators.design.feel generators.design.frame-budget generators.design.prices generators.design.stack-cap generators.design.loot generators.design.starting-inventory generators.design.settlement generators.design.gear-hp generators.design.initial-encounters generators.design.artifact generators.design.artifacts-per-land generators.design.circle-of-power generators.design.recipes generators.design.pvp generators.design.time generators.design.terrain.height generators.design.terrain.heightfield generators.design.spawns.ai generators.design.names.land-suffix generators.design.resources.mp generators.design.movement.stamina generators.design.defence.dodge generators.design.defence.block generators.design.defence.stealth generators.design.defence.enemy-hit generators.design.creature-roles.any-class generators.design.creature-roles.melee generators.design.creature-roles.ranged generators.design.creature-roles.mage generators.design.creature-roles.species generators.design.feel.hit-stop generators.design.feel.shake generators.design.feel.numbers generators.design.feel.impact generators.design.feel.trail generators.design.feel.level-up generators.design.feel.events generators.design.feel.sfx generators.design.feel.numbers.colours generators.design.settlement.npc generators.design.settlement.npc.roles generators.design.settlement.style-by-landscape generators.design.settlement.style-colors generators.design.settlement.shop generators.design.settlement.inn generators.design.settlement.trainer generators.design.loot.coins generators.design.loot.rarity-weights generators.design.loot.gear-kinds generators.design.loot.ground",
	"array": "equipment-slots.slots versions.timeline generators.design.climate.rules",
	"strings":
	"equipment-slots.rules pet-food.rules pet-food.shop-set status-effects.not-found mission-types.steam.region-completion-order static-entities.s-additions recipes.crafting-tabs-a affixes.common affixes.uncommon affixes.rare affixes.epic affixes.legendary affixes.name-forms audio.sfx-alpha-ids slash-commands.cuwo-server-commands generators.design.names.syllables generators.design.abilities.runtimes generators.design.movesets.kinds generators.design.stack-cap.stackable generators.design.loot.consumable-pool generators.design.settlement.buildings",
	"string":
	"generators.design.item-stat-curve generators.design.block-reward generators.design.regeneration generators.loot generators.level-formulas-alpha generators.design.creature-roles.default",
	"bool": "rulesets.ruleset-hybrid.default"
}
const CATALOG_CONFIG := {
	"rarities": ["mob-strength-tiers-s", "alpha-relative-colors"],
	"status-effects": ["ability-buffs", "not-found"],
	"factions": ["realm-name-examples"],
	"consumables": ["rules"],
	"key-items": ["counts-per-land-s", "special-accessories-x"],
	"npc-roles": ["dialogue-corpus"],
	"slash-commands": ["cuwo-server-commands", "chat-rules"]
}


static func _object(value: Variant) -> Dictionary:
	return Inputs.object(value)


static func _array(value: Variant) -> Array:
	return Inputs.array(value)


func _input_shape(value: Variant, kind: String, path: String) -> bool:
	var valid := Inputs.matches(self, value, kind)
	if not valid:
		errors.append(
			path.trim_prefix("generators.") + ": required " + kind + " missing or malformed"
		)
	return valid


func _required_path(path: String, kind: String) -> bool:
	return Inputs.required_path(self, path, kind)


func _fields_valid(row: Variant, path: String, fields: Dictionary) -> bool:
	return Inputs.fields_valid(self, row, path, fields)


const TYPED_STRINGS = Inputs.TYPED_STRINGS
const TYPED_NUMBERS = Inputs.TYPED_NUMBERS
const NULLABLE_NUMBERS = Inputs.NULLABLE_NUMBERS
const TYPED_ARRAYS = Inputs.TYPED_ARRAYS
const TYPED_BOOLS = Inputs.TYPED_BOOLS
const TYPED_OBJECTS = Inputs.TYPED_OBJECTS


func _typed_fields_valid(name: String, row: Dictionary, path: String) -> bool:
	return Inputs.typed_fields_valid(self, name, row, path)


func _typed_rows(name: String, data: Variant) -> Dictionary:
	return Inputs.typed_rows(self, name, data)


func _optional_fields_valid(row: Dictionary, path: String, fields: Dictionary) -> bool:
	return Inputs.optional_fields_valid(self, row, path, fields)


func _rows(data: Variant) -> Dictionary:  # skip "$schema", "_doc", "_x" keys
	return Inputs.rows(data)


static func _is_selected_multiplier(value: Variant, selected: float) -> bool:
	return Inputs.selected_multiplier(value, selected)


static func _identity_integer(value: Variant, minimum: int, maximum: float = INF) -> bool:
	return Inputs.integer(value, minimum, maximum)


static func _identity_strings(value: Variant) -> bool:
	return Inputs.strings(value)


func _ability_fields_valid(row: Dictionary, path: String) -> bool:
	return Combat.ability_fields_valid(self, row, path)


func _role_fields_valid(row: Dictionary, path: String) -> bool:
	return Combat.role_fields_valid(self, row, path)


func _validate_required_inputs() -> void:
	Catalogs.validate_required_inputs(self)


func _validate_mapped_tables() -> void:
	Catalogs.validate_mapped_tables(self)


func _validate_settlement_references() -> void:
	World.validate_settlement_references(self)


func _role_errors(
	r: Dictionary, where: String, se: Dictionary, alpha_sfx: Array, feel_sfx: Dictionary
) -> Array:
	var out: Array = []
	if not _role_fields_valid(r, where):
		return out
	if str(r.get("kind", "")) != "projectile":
		out.append("%s: kind must be projectile" % where)
		return out
	return _role_numbers(r, where, se, alpha_sfx, feel_sfx, out)


func _validate_android() -> void:
	Presentation.validate_android(self)


func _selected_tree(value: Variant, expected: Variant, path: String) -> void:
	Encounters.selected_tree(self, value, expected, path)


func _validate_playable_sites(design: Dictionary) -> void:
	Encounters.validate_playable_sites(self, design)


func _validate_initial_encounter_config(design: Dictionary) -> void:
	Encounters.validate_initial_encounter_config(self, design)


func _moveset_fields_valid(row: Dictionary, path: String) -> bool:
	return Combat.moveset_fields_valid(self, row, path)


func _validate_races() -> void:
	Catalogs.validate_races(self)


func _validate_world_references() -> void:
	World.validate_world_references(self)


func _validate_identity() -> void:
	Identity.validate_identity_catalogs(self)


func _validate_equipment() -> void:
	Equipment.validate_slots(self)


func _validate_creature_roles(design: Dictionary, se: Dictionary, fl: Dictionary) -> bool:
	return Roles.validate_roles(self, design, se, fl)


func _validate_defence(
	design: Dictionary, ab: Dictionary, stamina_max: float, se: Dictionary
) -> bool:
	return Combat.validate_defence_dodge(self, design, ab, stamina_max, se)


static func load_file(o, dir_path: String, file: String) -> void:
	if not file.ends_with(".json"):
		return
	var text := FileAccess.get_file_as_string(dir_path.path_join(file))
	var data: Variant = JSON.parse_string(text)
	if data == null:
		o.errors.append("invalid JSON: %s" % file)
		return
	o._ingest(file.get_basename(), data)


static func _shot_errors(shot: Dictionary, where: String) -> Array:
	return Combat._shot_errors(shot, where)


func _validate_species_roles(
	cr: Dictionary, se: Dictionary, alpha_sfx: Array, feel_sfx: Dictionary, kinds: Array
) -> bool:
	var o = self
	for sid in _object(cr.get("species")):
		if not o._process_species_row(cr, sid, se, alpha_sfx, feel_sfx, kinds):
			return false
	return o._validate_defaults()


func _role_numbers(
	r: Dictionary, where: String, se: Dictionary, alpha_sfx: Array, feel_sfx: Dictionary, out: Array
) -> Array:
	if (
		float(r.get("range", -1)) <= float(r.get("keep-away", -1))
		or float(r.get("keep-away", -1)) < 0.0
	):
		out.append("%s: range must be > keep-away >= 0" % where)
	if float(r.get("windup-s", -1)) < 0.0:
		out.append("%s: windup-s must be >= 0" % where)
	if float(r.get("cooldown-s", 0)) <= 0.0:
		out.append("%s: cooldown-s must be > 0" % where)
	if float(r.get("damage-mult", 0)) <= 0.0:
		out.append("%s: damage-mult must be > 0" % where)
	out.append_array(_shot_errors(r.get("shot", {}), "%s.shot" % where))
	return Combat.role_statuses(r, where, se, alpha_sfx, feel_sfx, out)


func _validate_runtime_kind(a, r: Dictionary) -> bool:
	match str(r["runtime"]):
		"dash":
			return _validate_runtime_dash(a, r)
		"projectile":
			errors.append_array(_shot_errors(r, "design.abilities.%s" % a.id))
		"burst", "channel":
			return Combat.runtime_area(self, a, r)
		"buff":
			if float(r.get("duration-s", 0)) <= 0.0:
				errors.append("design.abilities.%s: duration-s must be > 0" % a.id)
		"heal":
			return Combat.runtime_heal(self, a, r)

	return true


func _validate_runtime_dash(a, r: Dictionary) -> bool:
	if float(r.get("distance", 0)) <= 0.0:
		errors.append("design.abilities.%s: dash distance must be > 0" % a.id)
	if r.has("strike") and float(r["strike"].get("radius", 0)) <= 0.0:
		errors.append("design.abilities.%s: strike radius must be > 0" % a.id)
	if r.has("throw"):
		errors.append_array(_shot_errors(r["throw"], "design.abilities.%s.throw" % a.id))

	return true


func _validate_moveset_kind(s: Dictionary, where: String, se: Dictionary) -> bool:
	match str(s["kind"]):
		"melee":
			Movesets.melee_slot(self, s, where, se)
		"projectile":
			errors.append_array(_shot_errors(s, where))
		_:
			if float(s.get("range", 0)) <= 0.0 or float(s.get("radius", 0)) <= 0.0:
				errors.append("%s: range and radius must be > 0" % where)

	return true


func _validate_ability_runtimes(design: Dictionary) -> bool:
	var ab_input: Variant = design.get("abilities")  # c-ability-runtime (D21)
	var ab: Dictionary = ab_input if ab_input is Dictionary else {}
	var runtimes := _array(ab.get("runtimes"))
	var stamina_max := Combat.stamina_max(self, design)
	var seen := {}
	var o = self
	for id in specs:
		if not o._validate_runtime_tree(id, ab, stamina_max, runtimes, seen):
			return false
	return Combat.validate_dot(self, design, ab, stamina_max)
