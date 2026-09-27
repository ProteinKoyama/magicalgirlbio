class_name BattleSpecialEffect
extends Control

const EXPAND_DURATION := 0.5
const MAX_DIAMETER := 300.0
const PULSE_DIAMETER := 98.0
const PULSE_FRAMES := 60
const LINE_COUNT := 24
const LINE_OUTER_RADIUS := 230.0

var effect_center := Vector2.ZERO
var circle_diameter := 0.0
var gather_progress := 0.0
var draw_gather_lines := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func play_effect(global_center: Vector2) -> void:
	effect_center = get_global_transform_with_canvas().affine_inverse() * global_center
	circle_diameter = 0.0
	gather_progress = 0.0
	draw_gather_lines = true
	show()
	queue_redraw()

	var started_at_msec: int = Time.get_ticks_msec()
	while gather_progress < 1.0:
		await get_tree().process_frame
		var elapsed_seconds: float = float(Time.get_ticks_msec() - started_at_msec) / 1000.0
		gather_progress = clampf(elapsed_seconds / EXPAND_DURATION, 0.0, 1.0)
		circle_diameter = lerpf(0.0, MAX_DIAMETER, gather_progress)
		queue_redraw()

	draw_gather_lines = false
	for frame_index: int in PULSE_FRAMES:
		circle_diameter = PULSE_DIAMETER if frame_index % 2 == 0 else MAX_DIAMETER
		queue_redraw()
		await get_tree().process_frame

	hide()


func _draw() -> void:
	if draw_gather_lines:
		_draw_gathering_lines()
	draw_circle(effect_center, circle_diameter * 0.5, Color.BLACK)


func _draw_gathering_lines() -> void:
	var circle_radius: float = circle_diameter * 0.5
	for line_index: int in LINE_COUNT:
		var angle: float = TAU * float(line_index) / float(LINE_COUNT)
		var direction := Vector2.from_angle(angle)
		var length_variation: float = float((line_index * 17) % 45)
		var outer_radius: float = LINE_OUTER_RADIUS + length_variation
		var start_radius: float = lerpf(outer_radius + 70.0, outer_radius, gather_progress)
		var end_radius: float = lerpf(outer_radius - 30.0, circle_radius + 8.0, gather_progress)
		var line_width: float = lerpf(2.0, 5.0, gather_progress)
		draw_line(
			effect_center + direction * start_radius,
			effect_center + direction * end_radius,
			Color.BLACK,
			line_width,
			true
		)
