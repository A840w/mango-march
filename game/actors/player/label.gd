extends Label

func _ready():
	var player = get_tree().get_first_node_in_group("player")

	if player:
		player.interaction_text_changed.connect(update_text)

func update_text(text: String):
	self.text = text