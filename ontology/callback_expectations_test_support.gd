## Independent original-source/platform expectations; never imports the production model.
extends RefCounted

const CASES := [
	"tree-owner",
	"tree-replace",
	"channel",
	"catalog-key",
	"catalog-shape",
	"event-key",
	"event-shape",
	"event-failure",
	"sound-shape",
	"sound-failure",
	"weight-negative",
	"weight-failure",
	"species-alias",
	"species-shape",
	"species-replace",
	"numeric-hit-stop:time-scale",
	"numeric-shake:decay-per-s",
	"numeric-numbers:life-s",
	"numeric-impact:impact-s",
	"numeric-trail:trail-s",
	"numeric-level-up:pop-s",
	"weight-key",
	"species-mutated-alias",
	"diagnostic-sound-slot",
	"diagnostic-sound-alias",
	"diagnostic-event",
	"variant-hit-stop:time-scale:array",
	"variant-hit-stop:time-scale:object",
	"variant-hit-stop:time-scale:null",
	"variant-hit-stop:time-scale:string",
	"variant-hit-stop:time-scale:negative",
	"variant-shake:decay-per-s:array",
	"variant-shake:decay-per-s:object",
	"variant-shake:decay-per-s:null",
	"variant-shake:decay-per-s:string",
	"variant-shake:decay-per-s:negative",
	"variant-numbers:life-s:array",
	"variant-numbers:life-s:object",
	"variant-numbers:life-s:null",
	"variant-numbers:life-s:string",
	"variant-numbers:life-s:negative",
	"variant-impact:impact-s:array",
	"variant-impact:impact-s:object",
	"variant-impact:impact-s:null",
	"variant-impact:impact-s:string",
	"variant-impact:impact-s:negative",
	"variant-trail:trail-s:array",
	"variant-trail:trail-s:object",
	"variant-trail:trail-s:null",
	"variant-trail:trail-s:string",
	"variant-trail:trail-s:negative",
	"variant-level-up:pop-s:array",
	"variant-level-up:pop-s:object",
	"variant-level-up:pop-s:null",
	"variant-level-up:pop-s:string",
	"variant-level-up:pop-s:negative"
]

const CONTROL := {
	"tree-owner": ["tree-owner", 1, [], 1],
	"tree-replace": ["tree-replace", 1, [], 1],
	"channel": ["channel", true, [], ["ability.turns-per-s", "ability.drain-per-s"]],
	"event-key":
	[
		"event-key",
		false,
		[
			"design.feel.events.key.sfx  is not an audio.json sfx-alpha-ids entry",
			"exactly one ruleset must be default (found 0)"
		]
	],
	"weight-key":
	[
		"weight-key",
		false,
		[
			"design.creature-roles.any-class.melee must be >= 0",
			"design.creature-roles.any-class weights must sum > 0",
			"exactly one ruleset must be default (found 0)"
		]
	],
	"diagnostic-sound-slot":
	[
		"diagnostic-sound-slot",
		false,
		["design.feel.sfx.key.hz must be > 0", "exactly one ruleset must be default (found 0)"]
	],
	"diagnostic-sound-alias":
	[
		"diagnostic-sound-alias",
		false,
		["design.feel.sfx.key.hz must be > 0", "exactly one ruleset must be default (found 0)"]
	],
	"diagnostic-event":
	[
		"diagnostic-event",
		false,
		[
			"design.feel.events.key.hit-stop-s outside [0, max-s]",
			"exactly one ruleset must be default (found 0)"
		]
	]
}

const MUTATION := {
	"tree-owner": ["tree-owner", 0, [], 1],
	"tree-replace": ["tree-replace", 0, [], 1],
	"channel": ["channel", false, [], ["ability.turns-per-s"]],
	"catalog-key":
	[
		"catalog-key",
		false,
		["ingredients.key: empty content row", "exactly one ruleset must be default (found 0)"]
	],
	"catalog-shape":
	[
		"catalog-shape",
		false,
		["ingredients.probe: empty content row", "exactly one ruleset must be default (found 0)"]
	],
	"event-key":
	[
		"event-key",
		false,
		[
			"design.feel.events.key.trauma outside [0,1]",
			"design.feel.events.key.sfx  is not an audio.json sfx-alpha-ids entry",
			"exactly one ruleset must be default (found 0)"
		]
	],
	"event-shape": ["event-shape", false, []],
	"event-failure": ["event-failure", false, []],
	"sound-shape":
	[
		"sound-shape",
		false,
		["design.feel.sfx.hit.hz must be > 0", "exactly one ruleset must be default (found 0)"]
	],
	"sound-failure": ["sound-failure", false, []],
	"weight-negative":
	[
		"weight-negative",
		false,
		[
			"design.creature-roles.any-class.melee must be >= 0",
			"design.creature-roles.any-class weights must sum > 0",
			"exactly one ruleset must be default (found 0)"
		]
	],
	"weight-failure": ["weight-failure", false, []],
	"species-alias": ["species-alias", false, ["exactly one ruleset must be default (found 0)"]],
	"species-shape": ["species-shape", false, []],
	"species-replace":
	["species-replace", false, ["exactly one ruleset must be default (found 0)"]],
	"weight-key":
	[
		"weight-key",
		false,
		[
			"design.creature-roles.any-class.melee must be >= 0",
			"exactly one ruleset must be default (found 0)"
		]
	],
	"species-mutated-alias":
	[
		"species-mutated-alias",
		false,
		[
			"design.creature-roles.species.collie: unknown override key kind",
			"design.creature-roles.species.collie (merged): kind must be melee",
			"exactly one ruleset must be default (found 0)"
		]
	],
	"diagnostic-sound-slot":
	[
		"diagnostic-sound-slot",
		false,
		["design.feel.sfx.key.hz must be > 0", "exactly one ruleset must be default (found 0)"]
	],
	"diagnostic-sound-alias":
	["diagnostic-sound-alias", false, ["design.feel.sfx.key.hz must be > 0"]],
	"diagnostic-event":
	["diagnostic-event", false, ["design.feel.events.key.hit-stop-s outside [0, max-s]"]]
}

const NUMERIC_ERRORS := {
	"hit-stop": "design.feel.hit-stop.time-scale outside (0,1)",
	"shake": "design.feel.shake.decay-per-s must be > 0",
	"numbers": "design.feel.numbers.life-s must be > 0",
	"impact": "design.feel.impact.impact-s must be > 0",
	"trail": "design.feel.trail.trail-s must be > 0",
	"level-up": "design.feel.level-up.pop-s must be > 0"
}

const HEADER_MUTATION := {
	"channel": ["SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor."],
	"event-shape":
	["SCRIPT ERROR: Trying to assign value of type 'Array' to a variable of type 'Dictionary'."],
	"event-failure": ["SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor."],
	"sound-failure": ["SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor."],
	"weight-failure": ["SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor."],
	"species-shape":
	["SCRIPT ERROR: Trying to assign value of type 'Array' to a variable of type 'Dictionary'."],
	"diagnostic-sound-alias": ["SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor."],
	"diagnostic-event": ["SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor."]
}

const LATE := "exactly one ruleset must be default (found 0)"
const FLOAT_ERROR := "SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor."
const DICTIONARY_ERROR := "SCRIPT ERROR: Trying to assign value of type 'Array' to a variable of type 'Dictionary'."


static func record(name: String, enabled: bool) -> Array:
	if not enabled:
		return CONTROL.get(name, [name, false, [LATE]])
	if name.begins_with("numeric-"):
		return [name, false, []]
	if name.begins_with("variant-"):
		return numeric_record(name)
	return MUTATION[name]


static func numeric_record(name: String) -> Array:
	var kind := name.get_slice(":", 2)
	if kind in ["array", "object", "null"]:
		return [name, false, []]
	if kind == "negative":
		return [name, false, [NUMERIC_ERRORS[name.get_slice(":", 0).trim_prefix("variant-")], LATE]]
	return [name, false, [LATE]]


static func headers(name: String, enabled: bool) -> Array:
	if not enabled:
		return []
	if name.begins_with("numeric-"):
		return [
			(
				"SCRIPT ERROR: Invalid access to property or key '%s' on a base object of type 'Dictionary'."
				% name.get_slice(":", 1)
			)
		]
	if name.begins_with("variant-"):
		return [FLOAT_ERROR] if name.get_slice(":", 2) in ["array", "object", "null"] else []
	return HEADER_MUTATION.get(name, [])


static func expected_group(first: int, prefix: String) -> Array:
	var out: Array = []
	for enabled in [false, true]:
		for index in range(first, mini(first + 8, CASES.size())):
			var name: String = CASES[index]
			if prefix == "PROBE ":
				out.append(JSON.stringify(record(name, enabled), "", false, true))
			else:
				out.append_array(headers(name, enabled))
	return out


static func observations(text: String, prefix: String) -> Array:
	if prefix == "SCRIPT ERROR:":
		return diagnostics(text)
	var out: Array = []
	for line in text.split("\n"):
		if line.begins_with(prefix):
			out.append(line.trim_prefix(prefix))
	return out


static func diagnostics(text: String) -> Array:
	var out: Array = []
	for line in text.split("\n"):
		if (
			line.begins_with("SCRIPT ERROR:")
			or line.begins_with("ERROR:")
			or line.begins_with("ontology INVALID")
		):
			out.append(line)
	return out


static func capture_group(first: int) -> Array:
	var output: Array = []
	var old := OS.get_environment("CALLBACK_GROUP")
	OS.set_environment("CALLBACK_GROUP", str(first))
	var status := OS.execute(
		"timeout",
		[
			"30",
			OS.get_executable_path(),
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"-s",
			"res://ontology/callback_probe_test_support.gd"
		],
		output,
		true
	)
	OS.set_environment("CALLBACK_GROUP", old)
	var text := "\n".join(output)
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if directory.is_absolute_path() and DirAccess.dir_exists_absolute(directory):
		var file := FileAccess.open(
			directory.path_join("callback-boundary-%d.log" % first), FileAccess.WRITE
		)
		file.store_string("exit=%d\n%s" % [status, text])
	return [status, observations(text, "PROBE "), observations(text, "SCRIPT ERROR:")]


static func capture_species() -> Array:
	var output: Array = []
	var status := OS.execute(
		"timeout",
		[
			"30",
			OS.get_executable_path(),
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"-s",
			"res://ontology/validation_boundary_test_support.gd"
		],
		output,
		true
	)
	var text := "\n".join(output)
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if directory.is_absolute_path() and DirAccess.dir_exists_absolute(directory):
		var file := FileAccess.open(directory.path_join("species-boundary.log"), FileAccess.WRITE)
		file.store_string("exit=%d\n%s" % [status, text])
	return [status, observations(text, "BOUNDARY "), observations(text, "SCRIPT ERROR:")]


static func capture_role() -> Array:
	var output: Array = []
	var status := OS.execute(
		"timeout",
		[
			"30",
			OS.get_executable_path(),
			"--headless",
			"--path",
			ProjectSettings.globalize_path("res://"),
			"-s",
			"res://ontology/role_boundary_test_support.gd"
		],
		output,
		true
	)
	var text := "\n".join(output)
	var directory := OS.get_environment("PIXLND_TEST_DIR")
	if directory.is_absolute_path() and DirAccess.dir_exists_absolute(directory):
		var file := FileAccess.open(directory.path_join("role-boundary.log"), FileAccess.WRITE)
		file.store_string("exit=%d\n%s" % [status, text])
	return [status, observations(text, "ROLEBOUNDARY "), observations(text, "SCRIPT ERROR:")]


# Literal current-id timelines, independent of production validation implementation.
const RUNTIME_EXPECTED := [
	[
		"selected-buff",
		false,
		false,
		["design.abilities.cyclone: duration-s must be > 0"],
		"cyclone",
		[2],
		["design.abilities.cyclone"]
	],
	[
		"selected-buff",
		true,
		false,
		["design.abilities.selected2: duration-s must be > 0"],
		"selected2",
		[2],
		["design.abilities.selected1"]
	],
	[
		"selected-unknown",
		false,
		false,
		["design.abilities.cyclone: missing or unknown runtime"],
		"cyclone",
		[1],
		[]
	],
	[
		"selected-unknown",
		true,
		false,
		["design.abilities.selected1: missing or unknown runtime"],
		"selected1",
		[1],
		[]
	],
	["id-cost", false, false, ["design.abilities.cyclone: duration-s must be > 0"], "cyclone", [2]],
	["id-cost", true, false, ["design.abilities.changed: duration-s must be > 0"], "changed", [2]],
	[
		"id-cost-errors",
		false,
		false,
		[
			"design.abilities.cyclone: cost mp = -1 outside [0, 100] / 'all'",
			"design.abilities.cyclone: cost mp = -1 outside [0, 100] / 'all'",
			"design.abilities.cyclone: duration-s must be > 0"
		],
		"cyclone",
		[3, 3]
	],
	[
		"id-cost-errors",
		true,
		false,
		[
			"design.abilities.first: cost mp = -1 outside [0, 100] / 'all'",
			"design.abilities.third: cost mp = -1 outside [0, 100] / 'all'",
			"design.abilities.fourth: duration-s must be > 0"
		],
		"fourth",
		[3, 3]
	],
	[
		"id-amount",
		false,
		false,
		[
			"design.abilities.cyclone: cost mp = not-all outside [0, 100] / 'all'",
			"design.abilities.cyclone: duration-s must be > 0"
		],
		"cyclone",
		[2]
	],
	[
		"id-amount",
		true,
		false,
		[
			"design.abilities.amount1: cost mp = not-all outside [0, 100] / 'all'",
			"design.abilities.amount2: duration-s must be > 0"
		],
		"amount2",
		[2]
	],
	[
		"id-cooldown",
		false,
		false,
		[
			"design.abilities.cyclone: cooldown-s must be > 0",
			"design.abilities.cyclone: duration-s must be > 0"
		],
		"cyclone",
		[]
	],
	[
		"id-cooldown",
		true,
		false,
		[
			"design.abilities.shaped: cooldown-s must be > 0",
			"design.abilities.shaped: duration-s must be > 0"
		],
		"shaped",
		[]
	],
	[
		"selector-dash",
		false,
		false,
		[
			"design.abilities.cyclone: dash distance must be > 0",
			"design.abilities.cyclone: strike radius must be > 0",
			"design.abilities.cyclone.throw: speed, radius, life-s must be > 0"
		],
		"cyclone",
		[1]
	],
	[
		"selector-dash",
		true,
		false,
		[
			"design.abilities.selector1: dash distance must be > 0",
			"design.abilities.selector1: strike radius must be > 0",
			"design.abilities.selector1.throw: speed, radius, life-s must be > 0"
		],
		"selector1",
		[1]
	],
	[
		"selector-projectile",
		false,
		false,
		["design.abilities.cyclone: speed, radius, life-s must be > 0"],
		"cyclone",
		[1]
	],
	[
		"selector-projectile",
		true,
		false,
		["design.abilities.selector1: speed, radius, life-s must be > 0"],
		"selector1",
		[1]
	],
	[
		"selector-burst",
		false,
		false,
		["design.abilities.cyclone: radius must be > 0"],
		"cyclone",
		[2]
	],
	[
		"selector-burst",
		true,
		false,
		["design.abilities.selector1: radius must be > 0"],
		"selector2",
		[2]
	],
	[
		"selector-channel",
		false,
		false,
		[
			"design.abilities.cyclone: radius must be > 0",
			"design.abilities.cyclone: duration-s must be > 0"
		],
		"cyclone",
		[2]
	],
	[
		"selector-channel",
		true,
		false,
		[
			"design.abilities.selector1: radius must be > 0",
			"design.abilities.selector2: duration-s must be > 0"
		],
		"selector2",
		[2]
	],
	[
		"selector-buff",
		false,
		false,
		["design.abilities.cyclone: duration-s must be > 0"],
		"cyclone",
		[1]
	],
	[
		"selector-buff",
		true,
		false,
		["design.abilities.selector1: duration-s must be > 0"],
		"selector1",
		[1]
	],
	[
		"selector-heal",
		false,
		false,
		["design.abilities.cyclone: heal needs cast-s >= 0 and heal-pct > 0"],
		"cyclone",
		[1]
	],
	[
		"selector-heal",
		true,
		false,
		["design.abilities.selector1: heal needs cast-s >= 0 and heal-pct > 0"],
		"selector1",
		[1]
	]
]
