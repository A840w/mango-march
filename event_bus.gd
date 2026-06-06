extends Node

@warning_ignore("unused_signal")
signal display_text(text: String, duration: float)

@warning_ignore("unused_signal")
signal display_progess(value: float, max_value: float)

@warning_ignore("unused_signal")
signal change_to_night

@warning_ignore("unused_signal")
signal cut_sound(duration: float)

@warning_ignore("unused_signal")
signal black_screen

@warning_ignore("unused_signal")
signal can_control_player(can: bool)

@warning_ignore("unused_signal")
signal player_death()

@warning_ignore("unused_signal")
signal save_game_state()

@warning_ignore("unused_signal")
signal load_game_state()

@warning_ignore("unused_signal")
signal almost_there

@warning_ignore("unused_signal")
signal begin_final_sequence

@warning_ignore("unused_signal")
signal end_game

@warning_ignore("unused_signal")
signal threat_say_help_me

@warning_ignore("unused_signal")
signal is_censor_in_view(is_in_view: bool, large: bool)

@warning_ignore("unused_signal")
signal set_censor_position(screen_pos: Vector2)

@warning_ignore("unused_signal")
signal near_bottom