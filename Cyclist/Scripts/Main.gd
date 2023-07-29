extends Node2D

var speed: float = 0.0001
var speed_max: float = 0.06
var speed_increment: float = 0.001

var enemy_speed: float = 0.05
var enemy_max_speed: float = 0.07
var coin: int = 0

# bools
var can_left: bool = true
var can_right: bool = true
var game_start: bool = false
var upgrade_pepe: bool = true
var upgrade_rock: bool = true
var upgrade_sonic: bool = true
var sonic_mode: bool = false
var timer_done: bool = false
var already_buy_pepe: bool = false
var already_buy_rock: bool = false
var already_buy_sonic: bool = false

# lap
var lap: int = 1
var enemy_lap: int = 2
var win: bool = false

# node declaration
@onready var main := $"."
@onready var player := $Game_state/Player
@onready var lap_num_label := $Game_state/Lap_placeholder/Lap_num_label
@onready var button_a := $Buttons/Button_A
@onready var button_b := $Buttons/Button_B
@onready var timer_label := $Game_state/Lap_placeholder/Timer_label
@onready var player_path_follow := $Game_state/Map/Path2D/PathFollow2D
@onready var start_button := $Menu_state/VBoxContainer/Start_button
@onready var enemy_path_follow := $Game_state/Map/Path2D/enemy_pathfollow
@onready var result_texture_rect := $Result_state/Result_textureRect
@onready var coin_label := $Coin/coin_label
@onready var hat_sprite := $Game_state/Hat_sprite
@onready var light := $Light

# labels
@onready var pepe_price := $Shops_state/VBoxContainer/HBoxContainer/Label2
@onready var rock_price := $Shops_state/VBoxContainer/HBoxContainer2/Label2
@onready var sonic_price := $Shops_state/VBoxContainer/HBoxContainer3/Label2

# buttons
@onready var back_settings_button := $Settings_state/VBoxContainer/Back_Settings_button
@onready var restart_button := $Result_state/VBoxContainer/Restart_button
@onready var back_shops_button := $Shops_state/VBoxContainer/Back_shops_button

# states
@onready var menu_state := $Menu_state
@onready var game_state := $Game_state
@onready var shops_state := $Shops_state
@onready var settings_state := $Settings_state
@onready var canvas_layer := $CanvasLayer
@onready var result_state := $Result_state
@onready var coin_state := $Coin
@onready var thanks_state := $Thanks_state

enum {MENU, GAME, SHOPS, SETTINGS, RESULT, THANKS}
var states: int = MENU

# audios
@onready var button_select_audio := $Audio/Button_select_audio
@onready var button_focus_audio := $Audio/Button_focus_audio
@onready var button_click_audio := $Audio/Button_click_audio
@onready var game_music_audio := $Audio/Game_music_audio
@onready var countdown_audio := $Audio/Countdown_audio
@onready var win_audio := $Audio/win_audio
@onready var lose_audio := $Audio/lose_audio
@onready var sonic_music_audio := $Audio/sonic_music_audio
@onready var thank_you_music := $Audio/thank_you_music
@onready var lap_audio := $Audio/lap_audio
@onready var lock_audio := $Audio/lock_audio
@onready var lock_audio_2 := $Audio/lock_audio2

# sprites
@onready var rock := $Shops_state/Rock
@onready var sonic := $Shops_state/Sonic
@onready var pepe := $Shops_state/Pepe

# start game time
var time: float = 0
var can_time_run: bool = false
var countdown_time: float = 0

# signals
signal add_coins_win_signal
signal add_coins_lose_signal
signal reset_game_signal

func _ready():
	start_button.grab_focus()
	menu_state.visible = true
	coin_label.text = str(coin)
	
	# audio
	#countdown_audio.stream_paused = true
	win_audio.stream_paused = true
	lose_audio.stream_paused = true
	sonic_music_audio.stream_paused = true
	thank_you_music.stream_paused = true
	lap_audio.stream_paused = true
	
	# connect signals
	connect("add_coins_win_signal", add_coins_win)
	connect("add_coins_lose_signal", add_coins_lose)
	connect("reset_game_signal", reset_game)

func _process(delta):
	player_path_follow.progress_ratio += speed * delta
	
	var main_tween = create_tween()
	main_tween.set_parallel()
	main_tween.tween_property(main, "modulate", Color(1,1,1), 2)
	main_tween.tween_property(game_music_audio, "volume_db", 4.364, 2)
	
	speed -= 0.1 * delta
	
	# limit
	speed = min(speed, speed_max)
	speed = max(0, speed)
	
	enemy_speed = min(enemy_speed, enemy_max_speed)
	enemy_speed = max(0, enemy_speed)
	
	# match states
	match states:
		GAME:
			game_music_audio.stream_paused = true
			
			coin_state.visible = false
			
			countdown_time += delta
			countdown()
			
			if timer_done:
				enemy_path_follow.progress_ratio += enemy_speed * delta
				
				if can_time_run:
					time += delta
					timer_label.text = get_time()
				
				if sonic_mode:
					speed += 1.5
					player.rotation_degrees += 5
					hat_sprite.rotation_degrees += 5
					can_time_run = true
					
					sonic_music_audio.stream_paused = false
					
					if lap == 20:
						can_time_run = false
						states = THANKS
						change_screen(game_state, thanks_state)
				else:
					# make it dependant to left and right
					if can_left:
						if Input.get_action_strength("Left"):
							speed += speed_increment
							can_left = false
							can_right = true
							player.rotation_degrees = -5
							hat_sprite.rotation_degrees = -5
							can_time_run = true
							button_a.button_pressed = true
							button_b.button_pressed = false
							button_click_audio.play()
					
					if can_right:
						if Input.get_action_strength("Right"):
							speed += speed_increment
							can_right = false
							can_left = true
							player.rotation_degrees = 5
							hat_sprite.rotation_degrees = 5
							can_time_run = true
							button_a.button_pressed = false
							button_b.button_pressed = true
							button_click_audio.play()
					
					if lap == 3:
						can_time_run = false
						if lap >= enemy_lap:
							result_texture_rect.texture = ResourceLoader.load("res://Graphics/win.png")
							win = true
							win_audio.play()
							add_coins_win_signal.emit()
						else:
							result_texture_rect.texture = ResourceLoader.load("res://Graphics/lose.png")
							add_coins_lose_signal.emit()
							lose_audio.play()
						restart_button.grab_focus()
						update_price_label()
						states = RESULT
						change_screen(game_state, result_state)
		
		RESULT:
			coin_state.visible = true
			reset_game_signal.emit()
			coin_label.text = str(coin)
		
		THANKS:
			sonic_music_audio.stream_paused = true
			thank_you_music.stream_paused = false
			player_path_follow.progress_ratio = 0

func reset_game():
	lap = 1
	enemy_lap = 2
	lap_num_label.text = str(1)
	player_path_follow.progress_ratio = 0
	enemy_path_follow.progress_ratio = 0
	time = 0
	countdown_time = 0
	timer_done = false

func add_coins_lose():
	coin += 5

func add_coins_win():
	coin += 10

func _on_white_marker_area_area_entered(_area):
	lap += 1
	lap_audio.play()
	lap_num_label.text = str(lap)

func get_time():
	var minute = fmod(time, 60*60) / 60
	var second = fmod(time, 60)
	var msec = fmod(time, 1) * 1000
	return "%02d:%02d:%03d" % [minute, second, msec]

func change_screen(hide_state, show_state):
	hide_state.hide()
	show_state.show()

# buttons signals
func _on_start_button_pressed():
	states = GAME
	change_screen(menu_state, game_state)
	button_select_audio.play()
	update_time_label()
	countdown_audio.play()

func _on_shops_button_pressed():
	change_screen(menu_state, shops_state)
	button_select_audio.play()
	back_shops_button.grab_focus()
	states = SHOPS

func _on_settings_button_pressed():
	change_screen(menu_state, settings_state)
	button_select_audio.play()
	states = SETTINGS
	back_settings_button.grab_focus()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_start_button_focus_entered():
	button_focus_audio.play()

func _on_shops_button_focus_entered():
	button_focus_audio.play()

func _on_settings_button_focus_entered():
	button_focus_audio.play()

func _on_quit_button_focus_entered():
	button_focus_audio.play()

func _on_back_settings_button_pressed():
	change_screen(settings_state, menu_state)
	button_select_audio.play()
	start_button.grab_focus()

func _on_back_settings_button_focus_entered():
	button_focus_audio.play()

func _on_shader_checkbutton_focus_entered():
	button_focus_audio.play()

func _on_volume_slider_focus_entered():
	button_focus_audio.play()

func _on_shader_checkbutton_toggled(button_pressed):
	canvas_layer.visible = false
	light.visible = false
	lock_audio_2.play()
	
	if button_pressed:
		canvas_layer.visible = true
		light.visible = true
		lock_audio_2.play()

func _on_enemy_area_area_entered(_area):
	enemy_lap += 1
	print(enemy_lap)

func _on_restart_button_pressed():
	states = GAME
	update_time_label()
	countdown_audio.play()
	change_screen(result_state, game_state)

func _on_menu_button_pressed():
	change_screen(result_state, menu_state)
	start_button.grab_focus()
	game_music_audio.stream_paused = false

func _on_shop_button_pressed():
	change_screen(result_state, shops_state)
	back_shops_button.grab_focus()
	game_music_audio.play()
	game_music_audio.stream_paused = false

func _on_back_shops_button_pressed():
	change_screen(shops_state, menu_state)
	start_button.grab_focus()


func _on_game_music_audio_finished():
	game_music_audio.play()

func _on_pepe_buy_button_pressed():
	if not upgrade_pepe:
		hat_sprite.texture = ResourceLoader.load("res://Graphics/accessories/pepe.png")
		lock_audio_2.play()
	elif coin >= 10:
		var tween = create_tween()
		tween.tween_property(pepe, "modulate", Color.hex(0xffffff), 0.5)
		$Shops_state/VBoxContainer/HBoxContainer/Pepe_buy_button.set("text", " use ")
		hat_sprite.texture = ResourceLoader.load("res://Graphics/accessories/pepe.png")
		
		if upgrade_pepe:
			upgrade_pepe = false
			coin -= 10
			speed_increment = 0.01
			update_coin_label()
			update_price_label()
			button_select_audio.play()
			already_buy_pepe = true
	else:
		lock_audio.play()


func _on_rock_buy_button_pressed():
	if not upgrade_rock:
		hat_sprite.texture = ResourceLoader.load("res://Graphics/accessories/rock.png")
		lock_audio_2.play()
	elif coin >= 20:
		var tween = create_tween()
		tween.tween_property(rock, "modulate", Color.hex(0xffffff), 0.5)
		$Shops_state/VBoxContainer/HBoxContainer2/Rock_buy_button.set("text", " use ")
		hat_sprite.texture = ResourceLoader.load("res://Graphics/accessories/rock.png")
		
		if upgrade_rock:
			upgrade_rock = false
			coin -= 20
			speed_max = 0.1
			update_coin_label()
			update_price_label()
			button_select_audio.play()
			already_buy_rock = true
	else:
		lock_audio.play()

func _on_sonic_buy_button_pressed():
	if not upgrade_sonic:
		hat_sprite.texture = ResourceLoader.load("res://Graphics/accessories/sonic.png")
		lock_audio_2.play()
	elif coin >= 30:
		var tween = create_tween()
		tween.tween_property(sonic, "modulate", Color.hex(0xffffff), 0.5)
		hat_sprite.texture = ResourceLoader.load("res://Graphics/accessories/sonic.png")
		$Shops_state/VBoxContainer/HBoxContainer3/Sonic_buy_button.set("text", "  use ")
		
		if upgrade_sonic:
			upgrade_sonic = false
			coin -= 30
			speed_max = 1
			speed_increment = 1
			update_coin_label()
			update_price_label()
			button_select_audio.play()
			sonic_mode = true
			already_buy_sonic = true
	else:
		lock_audio.play()

func update_coin_label():
	coin_label.text = str(coin)

func update_time_label():
	timer_label.text = get_time()

func _on_pepe_buy_button_focus_entered():
	button_focus_audio.play()

func _on_rock_buy_button_focus_entered():
	button_focus_audio.play()

func _on_sonic_buy_button_focus_entered():
	button_focus_audio.play()

func countdown():	
	if countdown_time >= 3.0:
		timer_done = true
		

func _on_restart_button_focus_entered():
	button_focus_audio.play()

func _on_shop_button_focus_entered():
	button_focus_audio.play()

func _on_menu_button_focus_entered():
	button_focus_audio.play()

func _on_button_a_pressed():
	button_click_audio.play()

func _on_button_b_pressed():
	button_click_audio.play()

func update_price_label():
	if already_buy_pepe:
		pepe_price.set("theme_override_colors/font_color", Color(0.478, 0.478, 0.478))
	elif coin >= 10:
		pepe_price.set("theme_override_colors/font_color", Color(224,201,0))
	elif coin < 10:
		pepe_price.set("theme_override_colors/font_color", Color(0.271, 0.537, 0))
	
	if already_buy_rock:
		rock_price.set("theme_override_colors/font_color", Color(0.478, 0.478, 0.478))
	elif coin >= 20:
		rock_price.set("theme_override_colors/font_color", Color(224,201,0))
	elif coin < 20:
		rock_price.set("theme_override_colors/font_color", Color(0.271, 0.537, 0))
	
	if already_buy_sonic:
		sonic_price.set("theme_override_colors/font_color", Color(0.478, 0.478, 0.478))
	if coin >= 30:
		sonic_price.set("theme_override_colors/font_color", Color(224,201,0))
	elif coin < 30:
		sonic_price.set("theme_override_colors/font_color", Color(0.271, 0.537, 0))
