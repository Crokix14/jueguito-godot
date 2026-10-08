extends Node3D

#region VARIABLES


var player : CharacterBody3D
var camera : Camera3D

const SPEED = 6.0
const SPRINT_SPEED = 10.0
const JUMP_FORCE = 5.0

# DASH
const DASH_SPEED = 18.0
const DASH_TIME = 0.2
const DASH_COOLDOWN = 3.0

var is_dashing = false
var can_dash = true

var dash_timer = 0.0
var dash_cooldown_timer = 0.0

var dash_direction = Vector3.ZERO

# UI
var dash_label : Label
var weapon_label : Label

# WEAPONS
var sword_mesh : MeshInstance3D
var bow_mesh : MeshInstance3D

var attack_timer = 0.0
var is_attacking = false

var current_weapon = "sword"

# GRAVITY
var gravity = ProjectSettings.get_setting(
	"physics/3d/default_gravity"
)

# CAMERA
var camera_target_offset = Vector3(0, 8, 8)
var camera_smooth_speed = 5.0
#endregion
#region START


func _ready():

	create_environment()
	create_light()

	create_floor()
	create_walls()

	create_player()

	create_weapons()

	create_enemies()

	create_ui()

#endregion
#region UPDATE

func _physics_process(delta):

	if player == null:
		return

	# GRAVEDAD
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	else:
		player.velocity.y = 0

	# SALTO
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		player.velocity.y = JUMP_FORCE

	# INPUT
	var input_dir = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	var direction = Vector3(
		input_dir.x,
		0,
		input_dir.y
	)

	# DASH INPUT
	if Input.is_key_pressed(KEY_Z) \
	and direction != Vector3.ZERO \
	and not is_dashing \
	and can_dash:

		is_dashing = true
		can_dash = false

		dash_timer = DASH_TIME

		dash_direction = direction.normalized()

	# DASH
	if is_dashing:

		player.velocity.x = (
			dash_direction.x
			* DASH_SPEED
		)

		player.velocity.z = (
			dash_direction.z
			* DASH_SPEED
		)

		dash_timer -= delta

		if dash_timer <= 0:
			is_dashing = false

	# NORMAL MOVE
	else:

		var current_speed = SPEED

		# SPRINT
		if Input.is_key_pressed(KEY_SHIFT):
			current_speed = SPRINT_SPEED

		if direction:

			player.velocity.x = (
				direction.x
				* current_speed
			)

			player.velocity.z = (
				direction.z
				* current_speed
			)

			player.look_at(
				player.global_position
				+ direction,
				Vector3.UP
			)

		else:

			player.velocity.x = move_toward(
				player.velocity.x,
				0,
				current_speed
			)

			player.velocity.z = move_toward(
				player.velocity.z,
				0,
				current_speed
			)

	player.move_and_slide()

	update_camera(delta)
	update_dash_cooldown(delta)
	update_ui()
	update_attack(delta)
#endregion
#region ATTACK


func update_attack(delta):

	# CAMBIAR ARMA
	if Input.is_key_pressed(KEY_1):
		current_weapon = "sword"

	if Input.is_key_pressed(KEY_2):
		current_weapon = "bow"

	# ATAQUE
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
	and not is_attacking:

		is_attacking = true
		attack_timer = 0.25

	# ESPADA
	if is_attacking and current_weapon == "sword":

		sword_mesh.rotation_degrees.z += 900 * delta

	# ARCO
	if is_attacking and current_weapon == "bow":

		bow_mesh.scale.x = lerp(
			bow_mesh.scale.x,
			0.5,
			12 * delta
		)

	# RESET
	if is_attacking:

		attack_timer -= delta

		if attack_timer <= 0:

			is_attacking = false

			sword_mesh.rotation_degrees = Vector3.ZERO

			bow_mesh.scale = Vector3.ONE
#endregion
#region CREATE WEAPONS


func create_weapons():

	# ESPADA
	sword_mesh = MeshInstance3D.new()

	var sword = BoxMesh.new()

	sword.size = Vector3(
		0.2,
		1.5,
		0.2
	)

	sword_mesh.mesh = sword

	sword_mesh.position = Vector3(
		0.7,
		0.5,
		0
	)

	player.add_child(sword_mesh)

	# ARCO
	bow_mesh = MeshInstance3D.new()

	var bow = CylinderMesh.new()

	bow.top_radius = 0.2
	bow.bottom_radius = 0.2
	bow.height = 1.2

	bow_mesh.mesh = bow

	bow_mesh.rotation_degrees.z = 90

	bow_mesh.position = Vector3(
		-0.7,
		0.5,
		0
	)

	player.add_child(bow_mesh)
#endregion
#region DASH CD


func update_dash_cooldown(delta):

	if can_dash:
		return

	if not is_dashing:

		dash_cooldown_timer += delta

		if dash_cooldown_timer >= DASH_COOLDOWN:

			can_dash = true
			dash_cooldown_timer = 0.0
#endregion
#region CAMERA

func update_camera(delta):

	if camera == null:
		return

	var target_position = (
		player.global_position
		+ camera_target_offset
	)

	camera.global_position = (
		camera.global_position.lerp(
			target_position,
			camera_smooth_speed * delta
		)
	)

	camera.look_at(
		player.global_position,
		Vector3.UP
	)
#endregion
#region UI

func create_ui():

	var canvas = CanvasLayer.new()
	add_child(canvas)

	# DASH LABEL
	dash_label = Label.new()

	dash_label.position = Vector2(20, 20)

	dash_label.scale = Vector2(2, 2)

	dash_label.text = "⚡ DASH READY"

	canvas.add_child(dash_label)

	# WEAPON LABEL
	weapon_label = Label.new()

	weapon_label.position = Vector2(20, 70)

	weapon_label.scale = Vector2(2, 2)

	weapon_label.text = "🗡 WEAPON: SWORD"

	canvas.add_child(weapon_label)


func update_ui():

	if dash_label == null:
		return

	# DASH UI
	if can_dash:

		dash_label.text = "⚡ DASH READY"

	else:

		var remaining = snapped(
			DASH_COOLDOWN - dash_cooldown_timer,
			0.1
		)

		dash_label.text = (
			"DASH CD: "
			+ str(remaining)
		)

	# WEAPON UI
	if weapon_label != null:

		if current_weapon == "sword":
			weapon_label.text = "🗡 WEAPON: SWORD"

		if current_weapon == "bow":
			weapon_label.text = "🏹 WEAPON: BOW"
#endregion
#region ENVIRONMENT
# ====================================

func create_environment():

	var env = WorldEnvironment.new()

	var environment = Environment.new()

	environment.background_mode = (
		Environment.BG_COLOR
	)

	environment.background_color = Color(
		0.4,
		0.6,
		1.0
	)

	env.environment = environment

	add_child(env)
#endregion
#region LIGHT


func create_light():

	var sun = DirectionalLight3D.new()

	sun.rotation_degrees.x = -45
	sun.rotation_degrees.y = 45

	add_child(sun)
#endregion
#region FLOOR

func create_floor():

	var floor = StaticBody3D.new()

	floor.name = "Floor"

	var mesh = MeshInstance3D.new()

	var box_mesh = BoxMesh.new()

	mesh.mesh = box_mesh

	mesh.scale = Vector3(20, 0.5, 20)

	var collision = CollisionShape3D.new()

	var shape = BoxShape3D.new()

	shape.size = Vector3(40, 1, 40)

	collision.shape = shape

	floor.add_child(mesh)
	floor.add_child(collision)

	add_child(floor)
#endregion
#region WALLS

func create_walls():

	create_wall(
		Vector3(0, 2.5, -10),
		Vector3(20, 5, 1)
	)

	create_wall(
		Vector3(0, 2.5, 10),
		Vector3(20, 5, 1)
	)

	create_wall(
		Vector3(-10, 2.5, 0),
		Vector3(1, 5, 20)
	)

	create_wall(
		Vector3(10, 2.5, 0),
		Vector3(1, 5, 20)
	)


func create_wall(pos, size):

	var wall = StaticBody3D.new()

	var mesh = MeshInstance3D.new()

	var box_mesh = BoxMesh.new()

	mesh.mesh = box_mesh

	mesh.scale = size / 2.0

	var collision = CollisionShape3D.new()

	var shape = BoxShape3D.new()

	shape.size = size

	collision.shape = shape

	wall.position = pos

	wall.add_child(mesh)
	wall.add_child(collision)

	add_child(wall)

#endregion
#region PLAYER

func create_player():

	player = CharacterBody3D.new()

	player.name = "Player"

	player.position = Vector3(0, 3, 0)

	var mesh = MeshInstance3D.new()

	var capsule = CapsuleMesh.new()

	mesh.mesh = capsule

	var collision = CollisionShape3D.new()

	var shape = CapsuleShape3D.new()

	collision.shape = shape

	camera = Camera3D.new()

	camera.current = true

	camera.position = (
		player.position
		+ camera_target_offset
	)

	camera.look_at(
		player.global_position,
		Vector3.UP
	)

	player.add_child(mesh)
	player.add_child(collision)

	add_child(player)

	add_child(camera)
#endregion
#region ENEMIES

func create_enemies():

	create_enemy(Vector3(0, 1, -5))
	create_enemy(Vector3(8, 1, -8))
	create_enemy(Vector3(-4, 1, -6))


func create_enemy(pos):

	var enemy = StaticBody3D.new()

	enemy.name = "Enemy"

	var mesh = MeshInstance3D.new()

	var sphere = SphereMesh.new()

	mesh.mesh = sphere

	var collision = CollisionShape3D.new()

	var shape = SphereShape3D.new()

	collision.shape = shape

	enemy.position = pos

	enemy.add_child(mesh)
	enemy.add_child(collision)

	add_child(enemy)
#endregion
