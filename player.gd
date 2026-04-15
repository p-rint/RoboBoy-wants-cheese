extends CharacterBody3D

var direction : Vector3
var input_dir : Vector2
const SPEED = 10.0
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

enum States {IDLE, MOVE, STUNNED, ATTACKING, RECOVERING}

var state = States.MOVE

@onready var wall_jump_ray: RayCast3D = $Character/WallJump


var canWJ = false


func flatten(vector: Vector3) -> Vector3:
	return Vector3( vector.x, 0, vector.z)

func move() -> void:
	model.rotation.y = lerp_angle(model.rotation.y, targetRot, .5)
	
	#$CollisionShape3D.rotation.y = model.rotation.y
	var canMove = state != States.STUNNED and state != States.RECOVERING
	if direction and canMove:
		state = States.MOVE
		velocity.x = lerp(velocity.x, direction.x * SPEED, dt * 8)
		velocity.z = lerp(velocity.z, direction.z * SPEED, dt * 8)
		targetRot = atan2(-direction.x, -direction.z)
		
	else:
		state = States.IDLE
		velocity = lerp(velocity, Vector3.ZERO + Vector3(0,velocity.y,0), 8 * dt)

func _physics_process(delta: float) -> void:
	dt = delta
	camForw = flatten($CamPivot.basis.z)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		jump()

	input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	direction = flatten($CamPivot.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	runState()
	move_and_slide()
	
	manageRays()
	
	

func runState() -> void:
	move()
	#print(state)



func manageRays() -> void:
	wallSlideCheck()
	

func wallSlideCheck() -> void:
	canWJ = false
	if wall_jump_ray.is_colliding():
		var dot = wall_jump_ray.get_collision_normal().dot(direction)
		if dot < -.7:
			if velocity.y <= 1 and not is_on_floor(): #
				canWJ = true
				print("canWJ")

func jump() -> void:
	print(canWJ)
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
	if canWJ:
		var dir = wall_jump_ray.get_collision_normal()
		velocity = dir * 10
		velocity.y = 5
