extends Control

@onready var label = $Label

var pages := [
	"Summer vacation had finally arrived.",
	"Every year, the village children climbed the old mango tree.",
	"They picked dozens of mangos...",
	"...but nobody had ever reached the Supreme Mango.",
	"A legendary golden mango said to grow at the very top.",
	"Today, one determined kid decided to climb higher than anyone before.",
	"Reach the top.\nFind the Supreme Mango."
]

func _ready():
	show_intro()

func _unhandled_input(event):
	if event.is_pressed():
		get_tree().change_scene_to_file("uid://bu8d54vr7uty1")

func show_intro():
	for page in pages:
		label.text = page

		await get_tree().create_timer(3.0).timeout

	get_tree().change_scene_to_file("uid://bu8d54vr7uty1")