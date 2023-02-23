extends CharacterBody3D

@export_group("Movement Settings")
@export var mouse_sensitivity: float = 0.10
@export var max_speed: float = 100
@export var acceleration: float = 3.5
@export var deceleration: float = 16
@export var max_slope_angle: float = 89

@onready var camera_holder: Node3D = $CameraMount
@onready var camera: Camera3D = $CameraMount/Camera3D
@onready var cam_ref: WeakRef = weakref(camera)

var vel := Vector3()


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process_input(true)


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var ev := event as InputEventMouseMotion
		# Rotate camera holder on the X plane given changes to the Y mouse position (Vertical)
		camera_holder.rotate_x(deg_to_rad(ev.relative.y * mouse_sensitivity * -1))
		
		# Rotate cameras on the Y plane given changes to the X mouse position (Horizontal)
		rotate_y(deg_to_rad(ev.relative.x * mouse_sensitivity * -1))
	
		# Clamp the vertical look to +- 70 because we don't do back flips or tumbles
		var camera_rot: Vector3 = camera_holder.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -70, 70)
		camera_holder.rotation_degrees = camera_rot


func _physics_process(delta: float) -> void:
	# Intended direction of movement
	var dir := Vector3()
	
	# Check camera hasn't been freed
	# May not be necessary witout threading
	if not cam_ref.get_ref():
		camera = $CameraMount/Camera
		cam_ref = weakref(camera)
		return
	
	# Global camera transform
	var cam_xform: Transform3D = camera.get_global_transform()
	
	# Check the directional input and
	# get the direction orientated to the camera in the global coords
	# NB: The camera's Z axis faces backwards to the player
	dir += Input.get_axis("forward", "backward") * cam_xform.basis.z.normalized()
	dir += Input.get_axis("left", "right") * cam_xform.basis.x.normalized()
	dir += Input.get_axis("down", "up") * cam_xform.basis.y.normalized()

	# Remove any extra vertical movement from the direction
	# dir.y = 0
	dir = dir.normalized()
	
	# Get the current horizontal only movement
	var hvel = vel
	# hvel.y = 0
	
	# Get how far we can move horizontally
	var target: Vector3 = dir
	target *= max_speed
	
	# Set ac(de)celeration depending on input direction 
	var accel: float = acceleration if dir.dot(hvel) > 0 else deceleration
	
	# Interpolate between the current (horizontal) velocity and the intended velocity
	hvel = hvel.lerp(target, accel * delta)
	vel.x = hvel.x
	vel.z = hvel.z
	vel.y = hvel.y
	
	# Use the KinematicBody to control physics movement
	# Slide the first body (kinematic) then move the other bodies to match the movement
#	vel = camera_control.move_and_slide(vel, Vector3(0,1,0), 5.0, 4, deg_to_rad(max_slope_angle))
	velocity = vel
	move_and_slide()
