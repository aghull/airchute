extends Node2D

const thrust: float = 0.07
const turbo_ignition_time = .5
const turbo_cooldown = 3
const min_turbo_duration = 3
const max_speed = 5
const pitch_speed = 0.03
const wind_drag = .005
const drag = .005
const stall_thresh = 0.2
const gravity = 0.15
const fire_cooldown = 0.3
const bullet_speed = 20
const max_bullets = 15
const wind_shake_thresh = 2
const wind_shake_factor = .5
const max_shake = 6
const camera_lead = 40
const camera_max_lead = 200
const camera_speed = 0.05

var vel: Vector2 = Vector2.RIGHT * 2
var thrust_factor = 1
var turbo_burn_countdown = 0
var turbo_idle_countdown = turbo_cooldown
var pitch_factor = 1
var firing = false
var bullets = []
var fire_countdown = 0
var shake = 20
var camera_zoom = Vector2.ONE
var Bullet = preload("res://bullet.tscn")
var wind = Vector2.ZERO

@onready var screen_size = get_viewport_rect().size

func _process(delta: float) -> void:

	fire_countdown -= delta
	turbo_idle_countdown -= delta

	if (Input.is_action_pressed("turbo") or turbo_burn_countdown > 0) and turbo_idle_countdown <= 0:
		if thrust_factor == 1:
			turbo_burn_countdown = min_turbo_duration
		turbo_burn_countdown -= delta
		if turbo_burn_countdown <= min_turbo_duration - turbo_ignition_time:
			if turbo_burn_countdown + delta > min_turbo_duration - turbo_ignition_time:
				vel *= 0.5 # kill momentum as turbo kicks in
			thrust_factor = 5
			pitch_factor = 0.2
		else:
			thrust_factor = 0
			pitch_factor = 0
	elif thrust_factor > 1:
		thrust_factor = 1
		pitch_factor = 1
		turbo_idle_countdown = turbo_cooldown


	if Input.is_action_pressed("ui_right"):
		rotation += pitch_speed * pitch_factor
	if Input.is_action_pressed("ui_left"):
		rotation -= pitch_speed * pitch_factor

	firing = Input.is_action_pressed("Fire")
	if firing && fire_countdown <= 0:
		var bullet = Bullet.instantiate()
		bullet.position = self.position
		bullet.direction = Vector2.from_angle(rotation) * bullet_speed + vel
		get_tree().root.get_child(0).add_child(bullet)
		fire_countdown = fire_cooldown
		bullets.push_front(bullet)
		if len(bullets) > max_bullets:
			bullets[max_bullets].queue_free()

	vel += Vector2.from_angle(rotation) * thrust * thrust_factor
	var dir = vel.angle()
	
	var wind_angle = fposmod(rotation - dir,  PI * 2)

	wind = (
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
	elif effectiveness < stall_thresh * 1.8:
		vel += Vector2.DOWN * gravity * (stall_thresh * 2 - effectiveness) / stall_thresh
	else:
		vel += Vector2.DOWN * gravity * max(0.1, 0.6 / vel.length())

	# drag at terminal speeds
	var speed = vel.length()
	if speed > max_speed * thrust_factor:
		vel *= (1 - drag)

	position += vel * delta * 60
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)

	$Flame.scale += (Vector2.ONE * pow(thrust_factor, 0.8) * 3 - $Flame.scale).clampf(-0.5, 0.5)

	if thrust_factor > 1:
		shake = 10
	else:
		shake = min(max_shake, (wind.length() - wind_shake_thresh) * wind_shake_factor)

	$Camera2D.offset = (vel * camera_lead).limit_length(camera_max_lead)
	var target_zoom = (Vector2.ONE * clamp(10 / vel.length(), 0.75, 3))
	$Camera2D.zoom += (target_zoom - $Camera2D.zoom).clampf(-camera_speed, camera_speed)

	if shake > 0:
		$Camera2D.offset += Vector2(randf() * shake, randf() * shake)
		rotation += .01 * (randf() - 0.5) * shake
