extends SceneTree

# Use gdmetrics-g4's native C-COG, not cyclomatic or a custom scoring formula.
const SOURCE := "res://addons/gdscript_complexity/"
const MAX_COGNITIVE_COMPLEXITY := 15


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
		var path: String = "res://" + relative_path
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
			failed = true
			continue
		for function in detected:
			# Score separately so equally named methods in different classes cannot overwrite one another.
			var result = calculator.calculate_cog(nodes, [function])
			var score: int = result.per_function.get(function.name, 0)
			if score > MAX_COGNITIVE_COMPLEXITY:
				var location := "%s:%d: %s" % [path, function.start_line, function.name]
				print(
					(
						"%s: cognitive complexity %d exceeds %d"
						% [location, score, MAX_COGNITIVE_COMPLEXITY]
					)
				)
				failed = true
	print(
		(
			"gdmetrics-g4: checked %d files; maximum cognitive complexity %d."
			% [files.size(), MAX_COGNITIVE_COMPLEXITY]
		)
	)
	for tool in [tokenizer.file_helper, tokenizer, flow, functions, calculator, adapter]:
		tool.free()
	quit(1 if failed else 0)
