extends Area3D

var t = 0.0

@onready var sY = position.y

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y = sY + sin(t)/4
	t += delta




func _on_area_entered(area: Area3D) -> void:
	if area.get_parent().name == "Player":
		area.get_parent().on = false
		area.get_parent().position = position
		
		monitoring = false
		monitorable = false
		sY += 3
		
		area.get_parent().endGame()
