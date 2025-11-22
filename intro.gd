extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready():
	if video_player:
		video_player.stream = preload("res://Assets/abertura.ogv")
		video_player.play()
	else:
		push_error("❌ Nó VideoStreamPlayer não encontrado na cena!")

func _on_video_finished():
	get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://title_screen/title_screen.tscn")
