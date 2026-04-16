extends CharacterBody3D

var direction : Vector3
var input_dir : Vector2
const SPEED = 13.0
const SSPEED = 10.0
const JUMP_VELOCITY = 8

@onready var camPiv = $CamPivot
@onready var model = $Character

var dt : float
var targetRot = 0
@export var health = 99

@export var score : int = 0

@onready var animPlr: AnimationPlayer = $AnimationPlayer

var camForw : Vector3

enum States {IDLE, MOVE, FALLING, STOMPING}

var state = States.MOVE

@onready var wall_jump_ray: RayCast3D = $Character/WallJump

var canWJ = false
var moveControl = 8

@onready var jump_buffer: Timer = $Timers/JumpBuffer
@onready var wall_jump_buffer: Timer = $Timers/WallJumpBuffer

@onready var stomp_ray: RayCast3D = $Stomp

@onready var triple_jump_grace: Timer = $Timers/TripleJumpGrace

var jumpNum = 0

var canJump := true

func flatten(vector: Vector3) -> Vector3:
	return Vector3( vector.x, 0, vector.z)

func move() -> void:
	model.rotation.y = lerp_angle(model.rotation.y, targetRot, .5)
	#var canMove = state != States.STUNNED and state != States.RECOVERING
	
	
	if direction:
		velocity.x = lerp(velocity.x, direction.x * SPEED, dt * moveControl)
		velocity.z = lerp(velocity.z, direction.z * SPEED, dt * moveControl)
		targetRot = atan2(-direction.x, -direction.z)
		
	else:
		if is_on_floor():
			velocity = lerp(velocity, Vector3.ZERO + Vector3(0,velocity.y,0), 8 * dt)

func _physics_process(delta: float) -> void:
	dt = delta
	camForw = flatten($CamPivot.basis.z)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		canJump = false
		jump()

	if Input.is_action_just_pressed("Stomp"):
		if not is_on_floor() and state != States.STOMPING:
			state = States.STOMPING
			velocity = Vector3.ZERO
			stomp()
		
	
	input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	direction = flatten($CamPivot.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	checkState()
	runState()
	
	move_and_slide()
	
	manageRays()
	
	

func runState() -> void:
	move()
	#print(state)

func checkState() -> void:
	if is_on_floor():
		if state == States.FALLING: #prev state
			triple_jump_grace.start(.2)
			
		if input_dir.length() > 0:
			state = States.MOVE
		else:
			state = States.IDLE
		
		if jump_buffer.time_left > 0:
			#print(jump_buffer.time_left)
			jump()
		
		moveControl = 8
	else:
		if state != States.STOMPING:
			state = States.FALLING
			moveControl = 1
		


func manageRays() -> void:
	wallSlideCheck()
	

func wallSlideCheck() -> void:
	var couldWJ = canWJ #could WJ before
	canWJ = false
	if wall_jump_ray.is_colliding():
		var dot = wall_jump_ray.get_collision_normal().dot(direction)
		#print(velocity.y)
		if dot < -.65:
			if not is_on_floor(): #
				canWJ = true
				
	if couldWJ == true && couldWJ != canWJ: 
		wall_jump_buffer.start(.3)


func jump() -> void:
	
	
	if canJump:
		print("WANT")
		if is_on_floor():
			manageTripleJump()
			
		if canWJ or wall_jump_buffer.time_left > 0:
			var dir = wall_jump_ray.get_collision_normal()
			velocity = dir * 5
			velocity.y = 10
	
	jump_buffer.start(.3)
	
	$Timers/JumpCooldown.start(.01)
	
	
func stomp() -> void:
	if stomp_ray.is_colliding() or is_on_floor():
		state = States.IDLE
		moveControl = 8
	else: #keep goin
		velocity.y = -30
		moveControl = 1


func manageTripleJump() -> void:
	var newVel = direction * velocity.length()
	if triple_jump_grace.time_left == 0 or jumpNum == 0 or jumpNum > 2:
		newVel.y = JUMP_VELOCITY
		
		jumpNum = 0
	else:
		if jumpNum == 1:
			newVel.y = JUMP_VELOCITY * 1.2
		elif jumpNum == 2:
			newVel.y = JUMP_VELOCITY * 2	
		
	jumpNum += 1
	print(jumpNum)
	velocity = newVel


func _on_jump_cooldown_timeout() -> void:
	canJump = true
