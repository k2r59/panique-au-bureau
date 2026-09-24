class_name OfficeRound
extends RefCounted

const DURATION := 60.0
const EXIT_DURATION := 0.24
const MONSTERS := ["ghost", "zombie", "vampire"]
const POOL := ["ghost", "ghost", "zombie", "vampire", "candy", "colleague", "pumpkin"]
var rng := RandomNumberGenerator.new()
var targets: Array[Dictionary] = []
var remaining := DURATION
var score := 0
var combo := 1
var streak := 0
var caught := 0
var mistakes := 0
var missed := 0
var best_combo := 1
var playing := false
var paused := false
var elapsed := 0.0
var spawn_in := 0.0

func start() -> void:
	targets.clear()
	for i in range(9):
		targets.append({})
	remaining = DURATION
	score = 0
	combo = 1
	streak = 0
	caught = 0
	mistakes = 0
	missed = 0
	best_combo = 1
	elapsed = 0.0
	spawn_in = 0.0
	playing = true
	paused = false

func reset_combo() -> void:
	combo = 1
	streak = 0

func advance(delta: float) -> bool:
	if not playing or paused:
		return false
	elapsed += delta
	remaining = maxf(0.0, DURATION - elapsed)
	if remaining <= 0.0:
		playing = false
		for i in range(9):
			targets[i] = {}
		return true
	for i in range(9):
		if targets[i].has("leaving"):
			if elapsed >= float(targets[i].leaving) + EXIT_DURATION:
				targets[i] = {}
			continue
		if not targets[i].is_empty() and float(targets[i].expires) <= elapsed:
			if targets[i].name in MONSTERS:
				missed += 1
				reset_combo()
			if targets[i].name in ["candy", "pumpkin"]:
				targets[i] = {}
			else:
				targets[i]["leaving"] = elapsed
	spawn_in -= delta
	if spawn_in <= 0.0:
		var empty: Array[int] = []
		for i in range(9):
			if targets[i].is_empty():
				empty.append(i)
		var difficulty := elapsed / DURATION
		if not empty.is_empty():
			var slot: int = empty[rng.randi_range(0, empty.size() - 1)]
			targets[slot] = {"name": POOL[rng.randi_range(0, POOL.size() - 1)], "born": elapsed, "expires": elapsed + 1.65 - difficulty * 0.65}
		spawn_in = 0.68 - difficulty * 0.36
	return false

func hit(index: int) -> Dictionary:
	if not playing or paused or index < 0 or index >= 9 or targets[index].is_empty() or targets[index].has("leaving"):
		return {}
	var target := targets[index]
	if target.name in ["candy", "pumpkin"]:
		targets[index] = {}
	else:
		targets[index]["leaving"] = elapsed
	var bad: bool = target.name in ["colleague", "pumpkin"]
	var points := -100 if bad else (100 if target.name == "candy" else 50) * combo
	score = maxi(0, score + points)
	if bad:
		mistakes += 1
		reset_combo()
	else:
		caught += 1
		streak += 1
		combo = mini(5, 1 + int(streak / 3.0))
		best_combo = maxi(best_combo, combo)
	return {"bad": bad, "points": points, "name": target.name}
