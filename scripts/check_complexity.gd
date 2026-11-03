extends SceneTree

# Use gdmetrics-g4's native C-COG, not cyclomatic or a custom scoring formula.
const SOURCE := "res://addons/gdscript_complexity/"
const MAX_COGNITIVE_COMPLEXITY := 15
const DEFERRED_FILE := "game/entities/test_android_controls.gd"
const DEFERRED_FUNCTION := "_competing_request"
const DEFERRED_MARKER := "# @cognitive-defer arrival-resource-recheck"
var _deferred := 0


func _initialize() -> void:
	var files: Array = JSON.parse_string(FileAccess.get_file_as_string("res://files.json"))
	var tokenizer = load(SOURCE + "src/tokenizer.gd").new()
	var flow = load(SOURCE + "src/core/control_flow_detector.gd").new()
	var functions = load(SOURCE + "src/core/function_detector.gd").new()
	var calculator = load(SOURCE + "src/core/cog_complexity_calculator.gd").new()
	var adapter = load(SOURCE + "version_adapter.gd").new()
	var failed := files.is_empty()
	if files.is_empty():
		print("gdmetrics-g4: no GDScript files found")
	for relative_path in files:
		var result := _check_file(relative_path, tokenizer, flow, functions, calculator, adapter)
		if result < 0:
			failed = true
	print(
		(
			"gdmetrics-g4: checked %d files; maximum cognitive complexity %d; %d owner-approved deferral(s)."
			% [files.size(), MAX_COGNITIVE_COMPLEXITY, _deferred]
		)
	)
	for tool in [tokenizer.file_helper, tokenizer, flow, functions, calculator, adapter]:
		tool.free()
	quit(1 if failed else 0)


func _check_file(relative_path: String, tokenizer, flow, functions, calculator, adapter) -> int:
	var path := "res://" + relative_path
	var tokens: Array = tokenizer.tokenize_file(path)
	var nodes: Array = flow.detect_control_flow(tokens, adapter)
	# The native boundary detector mistakes inline whitespace for a dedent.
	var boundary_tokens := tokens.filter(
		func(token): return token.type != tokenizer.TokenType.WHITESPACE or token.column == 1
	)
	var detected: Array = functions.detect_functions(boundary_tokens)
	var errors: Array = tokenizer.get_errors() + flow.get_errors() + functions.get_errors()
	if not errors.is_empty():
		print("%s: gdmetrics-g4 analysis failed: %s" % [path, errors])
		return -1
	var marked := _deferred_line(relative_path, tokens, detected, tokenizer.TokenType.COMMENT)
	if marked < 0:
		return -1
	return _check_functions(path, nodes, detected, calculator, marked)


# Only real COMMENT tokens can opt into the one exact owner-selected pending task.
func _deferred_line(path: String, tokens: Array, detected: Array, comment_type: int) -> int:
	var markers := _deferral_markers(tokens, comment_type)
	if markers.is_empty():
		return 0
	if markers.size() != 1:
		return _invalid_deferral(path)
	var marker = markers[0]
	if path != DEFERRED_FILE or marker.value != DEFERRED_MARKER or marker.column != 1:
		return _invalid_deferral(path)
	return _marked_function(path, marker.line + 1, detected)


func _deferral_markers(tokens: Array, comment_type: int) -> Array:
	var markers: Array = []
	for token in tokens:
		if token.type == comment_type and "@cognitive" in token.value.to_lower():
			markers.append(token)
	return markers


func _marked_function(path: String, line: int, detected: Array) -> int:
	for function in detected:
		if function.start_line == line and _is_deferred_function(function):
			return line
	return _invalid_deferral(path)


func _is_deferred_function(function) -> bool:
	return (
		function.name == DEFERRED_FUNCTION
		and function.start_column == 1
		and function.type == "func"
	)


func _invalid_deferral(path: String) -> int:
	print(
		"%s: Invalid cognitive deferral; only the adjacent owner-approved flag is permitted." % path
	)
	return -1


func _check_functions(path: String, nodes: Array, detected: Array, calculator, marked: int) -> int:
	var failed := false
	for function in detected:
		# Score separately so equally named methods cannot overwrite one another.
		var result = calculator.calculate_cog(nodes, [function])
		var score: int = result.per_function.get(function.name, 0)
		var location := "%s:%d: %s" % [path, function.start_line, function.name]
		if function.start_line == marked:
			if score <= MAX_COGNITIVE_COMPLEXITY:
				return _invalid_deferral(path)  # A stale flag must be removed, not silently retained.
			print(
				(
					"DEFERRED %s: cognitive complexity %d exceeds %d; %s; docs/HANDOFF.md"
					% [location, score, MAX_COGNITIVE_COMPLEXITY, DEFERRED_MARKER]
				)
			)
			_deferred += 1
		elif score > MAX_COGNITIVE_COMPLEXITY:
			print(
				(
					"%s: cognitive complexity %d exceeds %d"
					% [location, score, MAX_COGNITIVE_COMPLEXITY]
				)
			)
			failed = true
	return -1 if failed else 0
