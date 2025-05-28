extends Node2D

func _process(delta: float) -> void:
	$Jet.volume_linear = pow($Glider.thrust_factor, 0.5) / 4
	$Jet.pitch_scale = ($Glider.thrust_factor / 2.5) + 1.5
	$Wind.volume_linear = max(0, $Glider.vel.length() - 10) / 150 + $Glider.wind.length() / 32
	$Wind.pitch_scale = $Glider.wind.length() / 4
