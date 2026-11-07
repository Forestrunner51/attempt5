extends Node3D

@onready var ray = $RayCast3D

func _input(_delta):
    # I'm using ui_home key for testing, use your real action button
    if Input.is_action_pressed("interact"):
        check_interaction()

# if the object we are colliding with has interact() function, call it
func check_interaction():
    if ray.is_colliding():
        var collider = ray.get_collider()
        if collider.has_method("interact"):
            collider.interact()
