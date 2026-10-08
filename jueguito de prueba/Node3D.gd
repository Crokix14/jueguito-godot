extends Node3D

const ARENA = 18.0
var player: CharacterBody3D
var camera: Camera3D
var enemies: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var wave = 0
var hp = 100.0
var kills = 0
var damage = 30.0
var speed = 7.0
var weapon = 0
var attack_cd = 0.0
var dash_cd = 0.0
var dash_time = 0.0
var spawn_cd = 0.0
var pending = 0
var state = "menu"
var hud: Label
var overlay: PanelContainer
var menu_box: VBoxContainer
var blade: MeshInstance3D
var aim = Vector3.FORWARD
var rng = RandomNumberGenerator.new()
var time_alive = 0.0
var shake = 0.0
var floor_mat: StandardMaterial3D

func mat(color: Color, glow = false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.65
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 2.0
	return m

func mesh_at(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, glow = false) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = mesh
	n.position = pos
	n.material_override = mat(color, glow)
	parent.add_child(n)
	return n

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow = false) -> MeshInstance3D:
	var m = BoxMesh.new()
	m.size = size
	return mesh_at(parent, m, pos, color, glow)

func _ready():
	rng.randomize()
	var world = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("080e24")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("829ccc")
	env.ambient_light_energy = 0.65
	world.environment = env
	add_child(world)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("c3dcff")
	sun.shadow_enabled = true
	add_child(sun)
	var ground = StaticBody3D.new()
	add_child(ground)
	box(ground, Vector3(0,-0.5,0), Vector3(40,1,40), Color("121d35"))
	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(40,1,40)
	collider.shape = shape
	collider.position.y = -0.5
	ground.add_child(collider)
	for i in range(-18,19,3):
		box(self, Vector3(i,0.015,0), Vector3(0.035,0.025,36), Color("22395d"))
		box(self, Vector3(0,0.015,i), Vector3(36,0.025,0.035), Color("22395d"))
	for side in [-1,1]:
		box(self, Vector3(side*19,0.35,0), Vector3(0.18,0.7,38), Color("26dacb"), true)
		box(self, Vector3(0,0.35,side*19), Vector3(38,0.7,0.18), Color("26dacb"), true)
	for x in [-19,19]:
		for z in [-19,19]:
			box(self, Vector3(x,2,z), Vector3(1,4,1), Color("233352"))
			box(self, Vector3(x,4.1,z), Vector3(1.2,0.3,1.2), Color("fa4da5"), true)
	player = CharacterBody3D.new()
	add_child(player)
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	mesh_at(player,capsule,Vector3(0,0.9,0),Color("43e8d8"),true)
	box(player,Vector3(0,1.15,-0.43),Vector3(0.65,0.22,0.1),Color("ffffff"),true)
	var col = CollisionShape3D.new()
	var cs = CapsuleShape3D.new()
	cs.radius = 0.45
	cs.height = 1.8
	col.shape = cs
	col.position.y = 0.9
	player.add_child(col)
	blade = box(player,Vector3(0.7,0.9,-0.7),Vector3(0.14,0.14,1.5),Color("ffd166"),true)
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 32
	camera.position = Vector3(0,27,23)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var canvas = CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(24,20)
	hud.add_theme_font_size_override("font_size",22)
	canvas.add_child(hud)
	overlay = PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.position = Vector2(-290,-230)
	overlay.custom_minimum_size = Vector2(580,460)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.045,0.10,0.96)
	style.border_color = Color("43e8d8")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	overlay.add_theme_stylebox_override("panel",style)
	canvas.add_child(overlay)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation",14)
	overlay.add_child(menu_box)
	show_menu()

func clear_menu():
	for child in menu_box.get_children():
		menu_box.remove_child(child)
		child.queue_free()
	overlay.show()

func label(text: String, size = 20):
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",size)
	menu_box.add_child(l)

func button(text: String, action: Callable):
	var b = Button.new()
	b.text = text
	b.custom_minimum_size.y = 48
	b.add_theme_font_size_override("font_size",20)
	b.pressed.connect(action)
	menu_box.add_child(b)

func show_menu():
	clear_menu()
	label("NEON // LAST GUARD",34)
	label("Una arena. Cientos de drones. Tú.",20)
	label("WASD / Flechas · Mover\nRatón · Apuntar   |   Clic · Atacar\n1 · Espada   |   2 · Arco\nEspacio · Dash   |   Shift · Correr\nEsc · Pausa",19)
	button("ENTRAR A LA ARENA",start_game)
	label("Sobrevive y elige una mejora entre oleadas.",16)

func start_game():
	for e in enemies:
		e.node.queue_free()
	for s in shots:
		s.node.queue_free()
	enemies.clear()
	shots.clear()
	hp = 100
	wave = 0
	kills = 0
	damage = 30
	speed = 7
	dash_cd = 0
	attack_cd = 0
	time_alive = 0
	player.position = Vector3.ZERO
	overlay.hide()
	state = "playing"
	next_wave()

func next_wave():
	wave += 1
	pending = 4 + wave * 3
	spawn_cd = 0.3
	state = "playing"
	overlay.hide()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and state in ["playing","paused"]:
			if state == "paused":
				state = "playing"
				overlay.hide()
			else:
				state = "paused"
				clear_menu()
				label("EN PAUSA",32)
				button("CONTINUAR",func(): state = "playing"; overlay.hide())
				button("REINICIAR",start_game)
		if event.keycode == KEY_1:
			weapon = 0
		if event.keycode == KEY_2:
			weapon = 1
		if event.keycode == KEY_SPACE and state == "playing" and dash_cd <= 0:
			dash_time = 0.16
			dash_cd = 2.0

func _physics_process(delta):
	if state != "playing":
		return
	time_alive += delta
	attack_cd = maxf(0,attack_cd-delta)
	dash_cd = maxf(0,dash_cd-delta)
	dash_time = maxf(0,dash_time-delta)
	shake = maxf(0,shake-delta*3)
	var move = Vector3(float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),0,float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))).normalized()
	var mouse = get_viewport().get_mouse_position()
	var ray = camera.project_ray_origin(mouse)
	var ray_dir = camera.project_ray_normal(mouse)
	if absf(ray_dir.y)>0.001:
		var target = ray + ray_dir * ((0.9-ray.y)/ray_dir.y)
		var diff = target-player.position
		diff.y=0
		if diff.length()>0.1:
			aim=diff.normalized()
	player.rotation.y = atan2(-aim.x,-aim.z)
	var current_speed = speed * (1.45 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	if dash_time > 0:
		move = move if move.length()>0 else aim
		current_speed=28
	player.velocity=move*current_speed
	player.velocity.y=-4
	player.move_and_slide()
	player.position.x=clampf(player.position.x,-ARENA,ARENA)
	player.position.z=clampf(player.position.z,-ARENA,ARENA)
	blade.rotation.y = -attack_cd*5 if weapon==0 else 0.0
	blade.visible=weapon==0
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and attack_cd<=0:
		attack()
	spawn_cd-=delta
	if pending>0 and spawn_cd<=0:
		spawn_enemy()
		pending-=1
		spawn_cd=maxf(0.2,0.8-wave*0.04)
	for e in enemies:
		var n: Node3D=e.node
		var diff = player.position-n.position
		diff.y=0
		e.hit=maxf(0,e.hit-delta)
		if diff.length()>0.01:
			n.position+=diff.normalized()*e.speed*delta
			n.rotation.y=atan2(-diff.x,-diff.z)
		if diff.length()<1.3 and e.hit<=0 and dash_time<=0:
			hp-=e.damage
			e.hit=0.7
			shake=0.7
	for i in range(shots.size()-1,-1,-1):
		var s = shots[i]
		s.node.position+=s.dir*25*delta
		s.life-=delta
		for e in enemies:
			if e.node.position.distance_to(s.node.position-Vector3(0,0.8,0))<1.1:
				e.hp-=damage*0.8
				s.life=0
				break
		if s.life<=0:
			s.node.queue_free()
			shots.remove_at(i)
	for i in range(enemies.size()-1,-1,-1):
		if enemies[i].hp<=0:
			enemies[i].node.queue_free()
			enemies.remove_at(i)
			kills+=1
			hp=minf(100,hp+1.5)
	camera.position=Vector3(player.position.x*0.25,27,23+player.position.z*0.25)+Vector3(rng.randf_range(-shake,shake),0,0)
	hud.text="NEON // LAST GUARD\nVIDA %d / 100   ·   OLEADA %d   ·   BAJAS %d\n%s   ·   DASH %s" % [maxi(0,int(hp)),wave,kills,"ESPADA" if weapon==0 else "ARCO","LISTO" if dash_cd<=0 else "%.1fs" % dash_cd]
	if hp<=0:
		state="gameover"
		clear_menu()
		label("FIN DE LA GUARDIA",32)
		label("Oleada %d  ·  %d bajas\nTiempo: %ds" % [wave,kills,int(time_alive)],22)
		button("OTRA PARTIDA",start_game)
	elif pending==0 and enemies.is_empty():
		state="upgrade"
		clear_menu()
		label("OLEADA COMPLETADA",30)
		label("Elige una mejora para seguir",20)
		button("PODER  ·  +12 daño",func(): damage+=12; next_wave())
		button("AGILIDAD  ·  +1 velocidad",func(): speed+=1; next_wave())
		button("RECUPERACIÓN  ·  +40 vida",func(): hp=minf(100,hp+40); next_wave())

func attack():
	attack_cd=0.36 if weapon==0 else 0.22
	if weapon==0:
		for e in enemies:
			var diff: Vector3=e.node.position-player.position
			if diff.length()<3.5 and (diff.normalized().dot(aim)>-0.2 or diff.length()<1.4):
				e.hp-=damage
				e.node.position+=diff.normalized()*0.8
	else:
		var shot = Node3D.new()
		add_child(shot)
		shot.position=player.position+Vector3(0,0.8,0)+aim
		box(shot,Vector3.ZERO,Vector3(0.18,0.18,0.65),Color("ffd166"),true)
		shot.rotation.y=atan2(-aim.x,-aim.z)
		shots.append({"node":shot,"dir":aim,"life":1.8})

func spawn_enemy():
	var n = Node3D.new()
	add_child(n)
	var angle=rng.randf()*TAU
	n.position=Vector3(cos(angle)*17,0,sin(angle)*17)
	var brute = wave>=3 and rng.randf()<0.25
	var color = Color("fa4da5") if not brute else Color("ff9c38")
	var m = SphereMesh.new()
	m.radius=0.65 if brute else 0.42
	m.height=1.3 if brute else 0.84
	mesh_at(n,m,Vector3(0,0.8,0),color,true)
	box(n,Vector3(0,0.85,-0.4),Vector3(0.55,0.14,0.12),Color("ffffff"),true)
	enemies.append({"node":n,"hp":(95 if brute else 45)+wave*7,"speed":(1.6 if brute else 2.6)+wave*0.12,"damage":18 if brute else 9,"hit":0.0})
