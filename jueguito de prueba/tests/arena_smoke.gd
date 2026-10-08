extends SceneTree
var game
func check(ok: bool, message: String):
	if not ok:
		push_error(message)
		quit(1)
		assert(ok,message)
func _initialize():
	call_deferred("run")
func run():
	game=load("res://node_3d.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.state=="menu","Initial menu")
	game.start_game()
	check(game.wave==1 and game.pending==7,"First wave")
	game.pending=0
	game.spawn_enemy()
	var enemy=game.enemies[0]
	enemy.hp=200
	enemy.node.position=game.player.position+Vector3(0,0,-2)
	game.aim=Vector3.FORWARD
	var old_hp=enemy.hp
	game.attack()
	check(enemy.hp<old_hp,"Sword damage")
	game.weapon=1
	game.attack()
	check(game.shots.size()==1,"Bow projectile")
	enemy.node.position=game.player.position+Vector3(0,0,-2)
	game.shots[0].node.position=enemy.node.position+Vector3(0,0.8,0)
	game.shots[0].dir=Vector3.ZERO
	old_hp=enemy.hp
	game._physics_process(0.016)
	check(enemy.hp<old_hp,"Projectile collision")
	game.enemies[0].hp=0
	game._physics_process(0.016)
	check(game.kills==1 and game.state=="upgrade","Kill and upgrade")
	game.next_wave()
	check(game.wave==2 and game.state=="playing","Next wave")
	var key=InputEventKey.new()
	key.keycode=KEY_SPACE
	key.pressed=true
	game._unhandled_input(key)
	check(game.dash_time>0 and game.dash_cd>0,"Dash cooldown")
	key.keycode=KEY_ESCAPE
	game._unhandled_input(key)
	check(game.state=="paused","Pause")
	game._unhandled_input(key)
	check(game.state=="playing","Resume")
	game.hp=0
	game._physics_process(0.016)
	check(game.state=="gameover","Game over")
	game.start_game()
	check(game.hp==100 and game.wave==1 and game.enemies.is_empty(),"Restart")
	for i in range(300):
		game._physics_process(0.016)
	check(not game.enemies.is_empty(),"Timed enemy spawning")
	print("NEON_TESTS_OK: menu, wave, sword, bow, hits, upgrades, dash, pause, death, restart, spawning")
	game.queue_free()
	await process_frame
	quit(0)
