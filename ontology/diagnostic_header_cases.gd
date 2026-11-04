## Captured child output must enforce the same anchored families as the outer quality gate.
extends RefCounted
const Cases := preload("res://ontology/callback_expectations_test_support.gd")
const SAMPLES := [
	["PROBE unchanged\nordinary text\n", []],
	["SCRIPT ERROR: intentional\n", ["SCRIPT ERROR: intentional"]],
	["ERROR: injected engine diagnostic\nPROBE unchanged\n", ["ERROR: injected engine diagnostic"]],
	[
		"ontology INVALID injected validator diagnostic\n",
		["ontology INVALID injected validator diagnostic"]
	],
	[
		"ERROR: first\nSCRIPT ERROR: intentional\nERROR: first\nontology INVALID last\n",
		["ERROR: first", "SCRIPT ERROR: intentional", "ERROR: first", "ontology INVALID last"]
	],
	[" ERROR: not anchored\nxSCRIPT ERROR: not anchored\nontology VALID\n", []]
]


static func run(test) -> void:
	for index in SAMPLES.size():
		var sample: Array = SAMPLES[index]
		test.check(
			Cases.observations(sample[0], "SCRIPT ERROR:") == sample[1],
			"captured diagnostic exact family/order/multiplicity " + str(index)
		)
	test.check(
		Cases.observations("ERROR: injected\nPROBE unchanged\n", "PROBE ") == ["unchanged"],
		"child diagnostic collection keeps semantic records independent"
	)
