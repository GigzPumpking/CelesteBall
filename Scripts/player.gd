extends CharacterBody2D

# --------- VARIABLES ---------- #

@export_category("Player Properties") # You can tweak these changes according to your likings
@export var move_speed : float = 400
@export var jump_force : float = 800
@export var gravity : float = 30
@export var max_jump_count : int = 2
@export var max_dash_count : int = 3
var jump_count : int = 2
var dash_count : int = 3
@export var momentum : int = 0
var dash_direction = 1
var dashing = false
@export_category("Toggle Functions") # Double jump feature is disable by default (Can be toggled from inspector)
@export var double_jump : = true
@export var infinite_dash = true
@onready var score_texture = %Score/ScoreTexture
@onready var score_label = %Score/ScoreLabel
var is_grounded : bool = false

@onready var player_sprite = $AnimatedSprite2D
@onready var spawn_point = %SpawnPoint
@onready var particle_trails = $ParticleTrails
@onready var death_particles = $DeathParticles

# --------- BUILT-IN FUNCTIONS ---------- #

func _process(_delta):
	# Calling functions
	movement()
	player_animations()
	flip_player()
	score_label.text = "x %d" %momentum
	
# --------- CUSTOM FUNCTIONS ---------- #

# <-- Player Movement Code -->
func movement():
	# Gravity
	if !is_on_floor():
		velocity.y += gravity
	elif is_on_floor():
		jump_count = max_jump_count
		dash_count = max_dash_count
	
	if dashing:
		velocity.y = 0
	
	
	# Move Player
	if Input.is_action_pressed("Left"):
		player_sprite.flip_h = true
		velocity.x = momentum - move_speed
		dash_direction = -1
	elif Input.is_action_pressed("Right"):
		velocity.x = momentum + move_speed
		player_sprite.flip_h = false
		dash_direction = 1
	elif dashing:
		velocity.x = momentum + dash_direction * move_speed
	elif Input.is_action_pressed("Crouch"):
		crouch()
		if is_on_floor():
			velocity.x = lerp(velocity.x,0.,0.033)
		
	elif is_on_floor():
		velocity.x = lerp(velocity.x,0.,0.1)
	
	if is_on_floor() and !dashing:
		momentum = lerp(momentum * 1.0, 0., 0.1)
	
		
	handle_dashing()
	handle_jumping()
	move_and_slide()

# Handles jumping functionality (double jump or single jump, can be toggled from inspector)
func handle_jumping():
	if Input.is_action_just_pressed("Jump"):
		if dashing:
			dashing = false
		if is_on_floor() and !double_jump:
			jump()
		elif double_jump and jump_count > 0:
			jump()
			jump_count -= 1
		
func handle_dashing():
	if Input.is_action_just_pressed("dash"):
		if is_on_floor():
			velocity.y = -2
			dash()
		elif dash_count > 0:
			dash()
			if !infinite_dash:
				dash_count -= 1
			jump_count = max_jump_count
# Player jump
func jump():
	dashing = false
	jump_tween()
	AudioManager.jump_sfx.play()
	velocity.y = -jump_force
# Player dash
func dash():
	dash_tween()
	momentum += (move_speed + abs(momentum) * 0.2) * 1.2 * dash_direction
	velocity.x += momentum 
	if !dashing:
		dashing = true
		await get_tree().create_timer(0.12).timeout
		dashing = false
		
# Handle Player Animations
func crouch():
	dashing = false
	crouch_tween()
func player_animations():
	particle_trails.emitting = false
	
	if is_on_floor():
		if abs(velocity.x) > move_speed * 0.2:
			particle_trails.emitting = true
			player_sprite.play("birb", 1.5)
		else:
			player_sprite.play("birb")
	else:
		player_sprite.play("bird")
		if dashing:
			particle_trails.emitting = true

# Flip player sprite based on X velocity
func flip_player():
	pass

# Tween Animations
func death_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15)
	await tween.finished
	global_position = spawn_point.global_position
	await get_tree().create_timer(0.3).timeout
	AudioManager.respawn_sfx.play()
	respawn_tween()

func respawn_tween():
	var tween = create_tween()
	tween.stop(); tween.play()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15) 

func jump_tween():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.7, 1.4), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func dash_tween():
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1.2,0.7),0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
func crouch_tween():
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(0.99,0.5),0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
# --------- SIGNALS ---------- #

# Reset the player's position to the current level spawn point if collided with any trap
func _on_collision_body_entered(_body):
	if _body.is_in_group("Traps"):
		AudioManager.death_sfx.play()
		death_particles.emitting = true
		momentum = 0
		death_tween()
