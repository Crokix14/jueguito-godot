extends SceneTree
var g
var failures=0
func check(ok: bool, text: String):
	if not ok:
		failures+=1
		push_error(text)
func _initialize():
	call_deferred("run")
func run():
	g=load("res://node_3d.tscn").instantiate()
	root.add_child(g)
	await process_frame
	check(g.state=="menu","Boss menu")
	g.start_boss()
	check(g.boss_mode and g.boss.visible and g.pending==0,"Boss starts")
	check(g.music.playing and g.music.stream.loop_mode==1,"Music plays and loops")
	g.set_phase("rain",3)
	g.spawn_rain()
	var y=g.rain[0].node.position.y
	g.update_rain(0.1)
	check(g.rain[0].node.position.y<y,"Rain falls")
	g.set_phase("frozen",8)
	y=g.rain[0].node.position.y
	g.update_rain(0.5)
	check(is_equal_approx(g.rain[0].node.position.y,y),"Freeze holds bullets")
	g.player.position=Vector3(10,0,10)
	g.use_ladder()
	check(not g.ladder_placed,"Cannot place ladder away from socket")
	g.player.position=g.SOCKET
	g.use_ladder()
	check(g.ladder_placed,"Place ladder")
	g.use_ladder()
	check(g.climbing,"Start climbing")
	g._physics_process(1.9)
	check(g.player.position.y>=5 and not g.climbing,"Climb reaches platform")
	g.aim=Vector3.FORWARD
	var hp=g.boss_hp
	g.weapon=0
	g.attack()
	check(g.boss_hp<hp,"Sword hits vulnerable head")
	g.weapon=1
	g.attack()
	for i in range(12):
		g.update_boss_shots(0.016)
	check(g.boss_hp<hp-24,"Arrow hits exposed head")
	g.set_phase("resume",2.2)
	hp=g.boss_hp
	check(not g.head_hit(100) and g.boss_hp==hp,"Boss shield after freeze")
	y=g.rain[0].node.position.y
	g.update_rain(0.1)
	check(g.rain[0].node.position.y<y,"Rain resumes")
	g.player.position=g.SOCKET
	g.use_ladder()
	check(not g.climbing,"No climbing outside freeze")
	g.set_phase("warning",2.5)
	check(g.rain.is_empty() and not g.ladder_placed and g.player.position.y==0,"Cycle resets safely")
	g.set_phase("frozen",8)
	g.player.position=g.TOP
	g.boss_hp=10
	g.head_hit(20)
	g._physics_process(0.016)
	check(g.state=="victory" and not g.music.playing,"Victory")
	g.start_boss()
	g.hp=0
	g._physics_process(0.016)
	check(g.state=="gameover","Defeat")
	g.start_boss()
	check(g.hp==100 and g.boss_hp==g.BOSS_MAX_HP,"Restart resets health")
	var key=InputEventKey.new()
	key.keycode=KEY_ESCAPE
	key.pressed=true
	g._unhandled_input(key)
	var before=g.phase_time
	g._physics_process(1)
	check(g.state=="paused" and g.phase_time==before and g.music.stream_paused,"Pause stops cycle and music")
	g._unhandled_input(key)
	check(g.state=="playing" and not g.music.stream_paused,"Resume")
	key.keycode=KEY_M
	g._unhandled_input(key)
	check(g.muted,"Mute")
	g.start_game()
	check(not g.boss_mode and not g.boss.visible and g.wave==1,"Original arena preserved")
	print("BOSS_TESTS: failures=",failures)
	g.music.stop()
	g.effects.stop()
	await create_timer(0.3).timeout
	g.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)
