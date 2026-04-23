extends CharacterBody3D

var direction : Vector3
var input_dir : Vector2
const SPEED = 13.0
const SSPEED = 10.0
const JUMP_VELOCITY = 9

@onready var camPiv = $CamPivot
@onready var model = $Character
@onready var mesh: MeshInstance3D = $Character/MeshInstance3D


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

@onready var stompJumpTimer: Timer = $Timers/StompJump

var on = true

var targetScale = Vector3(1,1,1)




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
	if not on:
		return
	
	dt = delta
	camForw = flatten($CamPivot.basis.z)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		jump()

	if Input.is_action_just_pressed("Stomp"):
		if not is_on_floor() and state != States.STOMPING:
			state = States.STOMPING
			velocity = Vector3.ZERO
			mesh.scale = Vector3(.4,1.7,.4)
			stomp()
		
	
	input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	direction = flatten($CamPivot.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	mesh.scale = mesh.scale.lerp(targetScale, dt * 5)
	
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
			mesh.scale = Vector3(1.1,.8,1.1)
		if state == States.STOMPING:
			mesh.scale = Vector3(1.7,.5,1.7)
			
		if input_dir.length() > 0:
			state = States.MOVE
		else:
			state = States.IDLE
		
		if jump_buffer.time_left > 0:
			#print(jump_buffer.time_left)
			print( state)
			if stompJumpTimer.time_left > 0:
				stompJump()
			else:	
				jump()
		
		moveControl = 8
	else:
		if state != States.STOMPING:
			state = States.FALLING
			moveControl = 1
			targetScale = Vector3(.9, 1.1, .9)
		else:
			targetScale = Vector3(.8,1.3,.8)
			stomp()
		


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
		canJump = false
		print("WANT")
		if is_on_floor():
			if stompJumpTimer.time_left == 0:
				manageTripleJump()
				print("AA")
			else:
				stompJump()
				return
		else:
			jump_buffer.start(.3)
		
			
			
	if canWJ or wall_jump_buffer.time_left > 0:
		var dir = wall_jump_ray.get_collision_normal()
		velocity = dir * 10
		velocity.y = 10
		mesh.scale = Vector3(.7,1.3,.7)
		
	
	#jump_buffer.start(.3)
	
	$Timers/JumpCooldown.start(.01)
	
	
func stomp() -> void:
	if stomp_ray.is_colliding() or is_on_floor():
		state = States.IDLE
		moveControl = 8
		mesh.scale = Vector3(1.4,.5,1.4)
		stompJumpTimer.start(.5)
		print("Start!!!")
		targetScale = Vector3(1,1,1)
	else: #keep goin
		velocity.y = -30
		moveControl = 1
		print("A")
		


func manageTripleJump() -> void:
	var newVel = direction * velocity.length()
	if triple_jump_grace.time_left == 0 or jumpNum == 0 or jumpNum > 2:
		newVel.y = JUMP_VELOCITY
		mesh.scale = Vector3(.8,1.2,.8)
		jumpNum = 0
	else:
		if jumpNum == 1:
			newVel.y = JUMP_VELOCITY * 1.4
			mesh.scale = Vector3(.75,1.3,.75)
		elif jumpNum == 2:
			newVel.y = JUMP_VELOCITY * 1.8
			mesh.scale = Vector3(.4,1.5,.4)
		
	jumpNum += 1
	print(jumpNum)
	velocity = newVel


func _on_jump_cooldown_timeout() -> void:
	canJump = true


func stompJump() -> void:
	var newVel = direction * velocity.length()
	newVel.y = JUMP_VELOCITY * 1.8
	velocity = newVel
	mesh.scale = Vector3(.1,2.5,.1)
	print("ya!")
	$Timers/JumpCooldown.start(.01)
	
	

func endGame() -> void:
	$"../CanvasLayer/Label".visible = true
	
	animPlr.play("yippe")
	$AnimationPlayer2.play("CHEEZ")
