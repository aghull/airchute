extends Node2D

const thrust: float = 0.08
const max_speed = 5
const yaw_speed = 0.05
const wind_drag = .01
const drag = .005
const stall_thresh = 0.2
const gravity = 0.15
const cooldownLength = 0.3
const bullet_speed = 20
const max_bullets = 15
const wind_shake_thresh = 2
const wind_shake_factor = .5
const max_shake = 6
const camera_lead = 40
const camera_max_lead = 200

var vel: Vector2 = Vector2.RIGHT * 2
var turbo_factor = 1
var firing = false
var bullets = []
var fireCooldown = 0
var shake = 20
var camera_zoom = Vector2.ONE
var Bullet = preload("res://bullet.tscn")

func _process(delta: float) -> void:
	#rotation += .1
	if Input.is_action_pressed("turbo"):
		turbo_factor = 5
	else:
		turbo_factor = 1
	if Input.is_action_pressed("ui_right"):
		rotation += yaw_speed / turbo_factor
	if Input.is_action_pressed("ui_left"):
		rotation -= yaw_speed / turbo_factor
	firing = Input.is_action_pressed("Fire")
	if firing && fireCooldown <= 0:
		var bullet = Bullet.instantiate()
		bullet.position = self.position
		bullet.direction = Vector2.from_angle(rotation) * bullet_speed + vel
		get_tree().root.get_child(0).add_child(bullet)
		fireCooldown = cooldownLength
		bullets.push_front(bullet)
		if len(bullets) > max_bullets:
			bullets[max_bullets].queue_free()
			

	fireCooldown -= delta

	vel += Vector2.from_angle(rotation) * thrust * turbo_factor
	var dir = vel.angle()
	
	var wind_angle = fposmod(rotation - dir,  PI * 2)

	var wind = (
		Vector2.from_angle(rotation + PI / 2) *
		sin(wind_angle) * 2 * vel.length()
	)
	$Wind.rotation = PI / (-2 if wind_angle > PI else 2)
	$Wind.scale = Vector2(wind.length(), 1) * .2

	vel += wind * wind_drag

	# stalling and gravity		
	var effectiveness = cos(wind_angle) * abs(cos(rotation))
	if effectiveness < stall_thresh:
		vel += Vector2.DOWN * gravity
	elif effectiveness < stall_thresh * 2:
		vel += Vector2.DOWN * gravity * (stall_thresh * 2 - effectiveness) / stall_thresh
	else:
		vel += Vector2.DOWN * gravity * 0.1
		
	# drag at terminal speeds
	var speed = vel.length()
	if speed > max_speed * turbo_factor:
		vel *= (1 - drag)

	position += vel * delta * 60
	
	if turbo_factor > 1:
		shake = 10
	else:
		shake = min(max_shake, (wind.length() - wind_shake_thresh) * wind_shake_factor)
	
	$Camera2D.offset = (vel * camera_lead).limit_length(camera_max_lead)
	var target_zoom = (Vector2.ONE * clamp(10 / vel.length(), 0.75, 3))
	$Camera2D.zoom += (target_zoom - $Camera2D.zoom).clampf(-0.005, 0.005)
	
	if shake > 0:
		$Camera2D.offset += Vector2(randf() * shake, randf() * shake)
		rotation += .01 * (randf() - 0.5) * shake
