extends "res://Node3D.gd"

const BOSS_POS = Vector3(0, 0, -6)
const SOCKET = Vector3(0, 0, 3)
const TOP = Vector3(0, 5.3, -3.5)
const BOSS_MAX_HP = 420.0
var boss_mode = false
var boss: Node3D
var head: MeshInstance3D
var boss_hp = BOSS_MAX_HP
var phase = "warning"
var phase_time = 2.5
var rain: Array[Dictionary] = []
var rain_tick = 0.0
var ladder: Node3D
var ladder_placed = false
var climbing = false
var climb_progress = 0.0
var prompt: Label
var boss_bar: ProgressBar
var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var muted = false
var cycle = 0

func _ready():
	super._ready()
	camera.position = Vector3(24, 26, 24)
	camera.look_at(Vector3(0, 1, 0))
	camera.size = 37
	build_boss()
	ladder = Node3D.new()
	add_child(ladder)
	var socket = box(self, SOCKET+Vector3(0,0.06,0), Vector3(2.5,0.1,2.5),Color("ffd166"),true)
	socket.name="ZonaEscalera"
	var canvas = hud.get_parent()
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -100
	prompt.offset_bottom = -20
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size",23)
	canvas.add_child(prompt)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(820,28)
	boss_bar.size = Vector2(420,24)
	boss_bar.max_value = BOSS_MAX_HP
	boss_bar.show_percentage=false
	canvas.add_child(boss_bar)
	music=AudioStreamPlayer.new()
	music.stream=load("res://audio/battle.wav")
	music.volume_db=-15
	add_child(music)
	effects=AudioStreamPlayer.new()
	effects.volume_db=-9
	add_child(effects)
	boss.hide()
	boss_bar.hide()

func show_menu():
	clear_menu()
	label("NEON // TITÁN DEL TIEMPO",30)
	label("Un gigante. Una escalera. Ocho segundos.",19)
	label("WASD / Flechas · Mover   |   Ratón + clic · Atacar\nE · Colocar escalera / subir / bajar\nEspacio · Dash   |   1 / 2 · Espada / arco\nEsc · Pausa   |   M · Música y efectos",17)
	button("DESAFIAR AL TITÁN",start_boss)
	button("ARENA DE OLEADAS",start_game)
	label("Esquiva la lluvia roja. Ataca su cabeza al congelarse.",16)

func build_boss():
	boss=Node3D.new()
	add_child(boss)
	boss.position=BOSS_POS
	box(boss,Vector3(-1.1,1.4,0),Vector3(1.2,2.8,1.2),Color("146b46"))
	box(boss,Vector3(1.1,1.4,0),Vector3(1.2,2.8,1.2),Color("146b46"))
	box(boss,Vector3(0,3.7,0),Vector3(3.7,2.5,2),Color("178856"))
	box(boss,Vector3(-2.5,3.6,0),Vector3(1.1,3.5,1.1),Color("31f09c"))
	box(boss,Vector3(2.5,3.6,0),Vector3(1.1,3.5,1.1),Color("31f09c"))
	var skull=SphereMesh.new()
	skull.radius=1.6
	skull.height=3.2
	head=mesh_at(boss,skull,Vector3(0,6.5,0),Color("31f09c"),true)
	box(boss,Vector3(-0.6,6.7,1.45),Vector3(0.45,0.22,0.15),Color("ffffff"),true)
	box(boss,Vector3(0.6,6.7,1.45),Vector3(0.45,0.22,0.15),Color("ffffff"),true)
	box(boss,Vector3(0,5.95,1.48),Vector3(1.0,0.15,0.14),Color("082521"))

func start_game():
	boss_mode=false
	camera.position=Vector3(0,27,23)
	camera.look_at(Vector3.ZERO)
	if is_instance_valid(boss):
		boss.hide()
		boss_bar.hide()
		prompt.text=""
	clear_rain()
	clear_ladder()
	if is_instance_valid(music):
		music.stop()
	super.start_game()

func start_boss():
	super.start_game()
	boss_mode=true
	camera.position=Vector3(24,26,24)
	camera.look_at(Vector3(0,1,0))
	pending=0
	player.position=Vector3(0,0,10)
	player.velocity=Vector3.ZERO
	boss_hp=BOSS_MAX_HP
	boss.show()
	boss_bar.show()
	phase="warning"
	phase_time=2.5
	rain_tick=0
	cycle=0
	clear_rain()
	clear_ladder()
	music.stream_paused=false
	music.play()
	play_effect("warning")

func clear_rain():
	for b in rain:
		b.node.queue_free()
		b.marker.queue_free()
	rain.clear()

func clear_ladder():
	if is_instance_valid(ladder):
		for n in ladder.get_children():
			ladder.remove_child(n)
			n.queue_free()
	ladder_placed=false
	climbing=false
	climb_progress=0

func play_effect(effect: String):
	if muted:
		return
	effects.stream=load("res://audio/"+effect+".wav")
	effects.play()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_M:
			muted=not muted
			music.volume_db=-80 if muted else -15
			if muted:
				effects.stop()
		if boss_mode and state=="playing" and event.keycode==KEY_E:
			use_ladder()
	super._unhandled_input(event)
	if boss_mode and state=="paused" and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		clear_menu()
		label("TIEMPO EN PAUSA",30)
		button("CONTINUAR",func(): state="playing"; overlay.hide(); music.stream_paused=false)
		button("REINTENTAR BOSS",start_boss)
	if is_instance_valid(music):
		music.stream_paused=state=="paused"

func use_ladder():
	if phase!="frozen":
		return
	if climbing or player.position.y>4:
		climbing=false
		player.position=SOCKET+Vector3(0,0,1)
		player.velocity=Vector3.ZERO
		return
	if player.position.distance_to(SOCKET)>3.0:
		return
	if not ladder_placed:
		place_ladder()
	else:
		climbing=true
		climb_progress=0
		play_effect("climb")

func place_ladder():
	ladder_placed=true
	for i in range(12):
		var t=float(i)/11.0
		box(ladder,SOCKET.lerp(TOP,t)+Vector3(0,0.12,0),Vector3(2,0.2,0.6),Color("ffd166"),true)
	for x in [-1.05,1.05]:
		var rail=box(ladder,(SOCKET+TOP)*0.5+Vector3(x,0.45,0),Vector3(0.12,0.12,SOCKET.distance_to(TOP)),Color("48c6ff"),true)
		rail.rotation.x=atan2(TOP.y-SOCKET.y,SOCKET.z-TOP.z)
	box(ladder,TOP+Vector3(0,-0.1,0),Vector3(3,0.2,2),Color("ffd166"),true)
	play_effect("climb")

func spawn_rain():
	# Telegraphs stay on the floor; projectiles freeze before reaching it.
	var target=Vector3(rng.randf_range(-13,13),0,rng.randf_range(-12,14))
	if rng.randf()<0.45:
		target=Vector3(player.position.x+rng.randf_range(-2,2),0,player.position.z+rng.randf_range(-2,2))
	var n=Node3D.new()
	add_child(n)
	n.position=target+Vector3(0, rng.randf_range(10,14),0)
	var ball=SphereMesh.new()
	ball.radius=0.35
	ball.height=0.7
	mesh_at(n,ball,Vector3.ZERO,Color("ff354d"),true)
	var marker=box(self,target+Vector3(0,0.035,0),Vector3(1.2,0.04,1.2),Color("9a283f"),true)
	rain.append({"node":n,"marker":marker,"speed":rng.randf_range(3.0,4.5)})

func set_phase(next: String, duration: float):
	phase=next
	phase_time=duration
	if next=="warning":
		clear_rain()
		clear_ladder()
		player.position.y=0
		player.velocity=Vector3.ZERO
		cycle+=1
		play_effect("warning")
	elif next=="frozen":
		play_effect("freeze")
	elif next=="resume":
		climbing=false
		play_effect("warning")
		hp=minf(100,hp+8)

func _physics_process(delta):
	if not boss_mode:
		super._physics_process(delta)
		return
	if state!="playing":
		return
	time_alive+=delta
	attack_cd=maxf(0,attack_cd-delta)
	dash_cd=maxf(0,dash_cd-delta)
	dash_time=maxf(0,dash_time-delta)
	phase_time-=delta
	if phase_time<=0:
		match phase:
			"warning": set_phase("rain",3.0)
			"rain": set_phase("frozen",8.0)
			"frozen": set_phase("resume",2.2)
			"resume": set_phase("warning",2.5)
	if phase=="rain":
		rain_tick-=delta
		if rain_tick<=0:
			for i in range(3):
				spawn_rain()
			rain_tick=0.28
	update_rain(delta)
	var axis=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))).normalized()
	# Screen-relative movement for the diagonal isometric camera.
	var move=(Vector3(1,0,-1)*axis.x+Vector3(1,0,1)*axis.y).normalized()
	var ray=camera.project_ray_origin(get_viewport().get_mouse_position())
	var rd=camera.project_ray_normal(get_viewport().get_mouse_position())
	if absf(rd.y)>0.001:
		var target=ray+rd*((player.position.y+0.9-ray.y)/rd.y)
		var diff=target-player.position
		diff.y=0
		if diff.length()>0.1:
			aim=diff.normalized()
	player.rotation.y=atan2(-aim.x,-aim.z)
	if climbing:
		climb_progress=minf(1,climb_progress+delta/1.8)
		player.position=SOCKET.lerp(TOP,climb_progress)
		player.velocity=Vector3.ZERO
		if climb_progress>=1:
			climbing=false
	elif phase=="frozen" and player.position.y>=5:
		# A stable attack platform lets the player aim at the exposed head.
		player.position.x=clampf(player.position.x+move.x*delta*2,-1.2,1.2)
		player.position.z=clampf(player.position.z+move.z*delta*2,TOP.z-0.7,TOP.z+0.7)
	else:
		var current_speed=speed*(1.45 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
		if dash_time>0:
			move=move if move.length()>0 else aim
			current_speed=28
		player.velocity.x=move.x*current_speed
		player.velocity.z=move.z*current_speed
		player.velocity.y-=20*delta
		player.move_and_slide()
		player.position.x=clampf(player.position.x,-ARENA,ARENA)
		player.position.z=clampf(player.position.z,-ARENA,ARENA)
		# Prevent clipping through the giant's solid footprint.
		var flat=Vector2(player.position.x-BOSS_POS.x,player.position.z-BOSS_POS.z)
		if flat.length()<2.7 and player.position.y<4:
			flat=flat.normalized()*2.7 if flat.length()>0.01 else Vector2(0,2.7)
			player.position.x=BOSS_POS.x+flat.x
			player.position.z=BOSS_POS.z+flat.y
	blade.visible=weapon==0
	blade.rotation.y=-attack_cd*5 if weapon==0 else 0.0
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and attack_cd<=0 and not climbing:
		attack()
	update_boss_shots(delta)
	head.material_override=mat(Color("ffd166") if phase=="frozen" else Color("31f09c"),true)
	boss_bar.value=boss_hp
	var title={"warning":"PREPÁRATE: LLUVIA ROJA","rain":"ESQUIVA LAS BALAS","frozen":"TIEMPO CONGELADO: CABEZA VULNERABLE","resume":"¡BAJA! LAS BALAS VUELVEN A CAER"}
	hud.text="TITÁN DEL TIEMPO  ·  VIDA %d / 100\n%s  ·  %.1fs\n%s  ·  DASH %s  ·  M: sonido %s" % [maxi(0,int(hp)),title[phase],maxf(0,phase_time),"ESPADA" if weapon==0 else "ARCO","LISTO" if dash_cd<=0 else "%.1f" % dash_cd,"OFF" if muted else "ON"]
	prompt.text="Busca el cuadrado dorado frente al boss."
	if phase=="frozen":
		if climbing:
			prompt.text="SUBIENDO… ¡apunta a la cabeza!"
		elif player.position.y>=5:
			prompt.text="¡CLIC A LA CABEZA!   ·   E: bajar   ·   %.1fs" % maxf(0,phase_time)
		elif player.position.distance_to(SOCKET)<3:
			prompt.text="E: subir la escalera" if ladder_placed else "E: colocar escalera   →   E otra vez: subir"
		else:
			prompt.text="¡Al cuadrado dorado! Coloca la escalera con E."
	if hp<=0:
		finish_boss(false)
	elif boss_hp<=0:
		finish_boss(true)

func update_rain(delta):
	if phase=="frozen":
		return
	for i in range(rain.size()-1,-1,-1):
		var b=rain[i]
		b.node.position.y-=b.speed*delta*(2.3 if phase=="resume" else 1.0)
		var center=player.position+Vector3(0,0.9,0)
		if b.node.position.distance_to(center)<1.1 and dash_time<=0 and not climbing:
			hp-=14
			play_effect("hurt")
			b.node.position.y=-1
		if b.node.position.y<=0.25:
			if Vector2(b.node.position.x-player.position.x,b.node.position.z-player.position.z).length()<1.3 and player.position.y<1 and dash_time<=0:
				hp-=8
			b.node.queue_free()
			b.marker.queue_free()
			rain.remove_at(i)

func head_hit(amount: float) -> bool:
	if phase!="frozen" or player.position.y<5:
		return false
	boss_hp=maxf(0,boss_hp-amount)
	play_effect("hit")
	return true

func attack():
	if not boss_mode:
		super.attack()
		return
	attack_cd=0.36 if weapon==0 else 0.25
	play_effect("swing")
	var center=BOSS_POS+Vector3(0,6.5,0)
	var direction=center-(player.position+Vector3(0,0.9,0))
	if weapon==0:
		var flat=Vector3(direction.x,0,direction.z).normalized()
		if direction.length()<4 and flat.dot(aim)>0.25:
			head_hit(24)
	else:
		var shot=Node3D.new()
		add_child(shot)
		shot.position=player.position+Vector3(0,0.9,0)+aim*0.7
		box(shot,Vector3.ZERO,Vector3(0.18,0.18,0.6),Color("ffd166"),true)
		shot.rotation.y=atan2(-aim.x,-aim.z)
		shots.append({"node":shot,"dir":aim,"life":1.8})

func update_boss_shots(delta):
	for i in range(shots.size()-1,-1,-1):
		var s=shots[i]
		s.node.position+=s.dir*25*delta
		s.life-=delta
		if s.node.position.distance_to(BOSS_POS+Vector3(0,6.5,0))<1.8:
			head_hit(16)
			s.life=0
		if s.life<=0:
			s.node.queue_free()
			shots.remove_at(i)

func finish_boss(won: bool):
	state="victory" if won else "gameover"
	music.stop()
	play_effect("victory" if won else "hurt")
	clear_menu()
	label("¡TITÁN DERROTADO!" if won else "EL TIEMPO TE ALCANZÓ",30)
	label("Tiempo: %ds  ·  Ciclos: %d" % [int(time_alive),cycle+1],21)
	label("Congela, construye, sube y golpea.",18)
	button("VOLVER A DESAFIAR",start_boss)
	button("ARENA DE OLEADAS",start_game)
