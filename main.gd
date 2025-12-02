extends Node2D

enum State {
	READY,
	START,
	LOST,
	CASHOUT
}

var attempts: int = 10
var cur_row_idx: int = 4
var state: State = State.READY
var cur_cash: int = 0

const CRATE_CLOSE_REGION = Rect2(1552, 416, 16, 16)
const CRATE_OPEN_REGION = Rect2(1568, 416, 16, 16)
const BUG_REGION = Rect2(1568, 496, 16, 16)
const GOLD_REGION = Rect2(1440, 608, 16, 16)
	
func ready() -> void:
	$HUD/Stats.text = "ATTEMPTS: %s" % str(attempts)
	$HUD/Button.text = "START"
	reset_boxes()
				
func start_game() -> void:
	attempts -= 1
	cur_row_idx = 4
	cur_cash = 0 
	reset_boxes()
	var prizes = get_tree().get_nodes_in_group("prizes")
	
	for prize in prizes:
		prize.queue_free()
	
	$HUD/Stats.visible = true
	$HUD/Stats.text = "TOTAL CASH: %s" % str(cur_cash)
	$HUD/Button.text = "CASHOUT"
				
func game_over() -> void:
	$LostSound.play()
	$HUD/Stats.text = "YOU LOST"
	$HUD/Button.text = "TRY AGAIN"
	state = State.LOST
	
func cashout() -> void:
	$WinSound.play()
	$HUD/Stats.text = "YOU WON %s" % str(cur_cash)
	$HUD/Button.text = "GET MORE"
	state = State.CASHOUT
	
func reset_boxes() -> void:
	var hboxes= $VBoxContainer.get_child_count()
	for hbox_idx in hboxes:
		var hbox = $VBoxContainer.get_child(hbox_idx)
		for panel in hbox.get_children():
			if (panel is Label):
				continue
			
			#if hbox_idx == cur_row_idx:
			var texture = load("res://images/items.png") as Texture2D
			var stylebox = StyleBoxTexture.new()
			stylebox.texture = texture
			stylebox.set("region_rect", CRATE_CLOSE_REGION)
				
			panel.add_theme_stylebox_override("panel", stylebox)
				
			panel.connect("gui_input", _on_box_click.bind(panel, hbox_idx))
			panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND	
				
func _on_box_click(event: InputEvent, panel: Panel, idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed(): 
		if cur_row_idx != idx:
			return
		
		var rand = randi_range(1, 100)
		if rand < 60: # WIN
			$WinSound.play()
			cur_cash += 100
			cur_row_idx -= 1 
			
			var sibling_nodes = panel.get_parent().get_children()
			for node in sibling_nodes:
				if node is Label:
					continue
				
				var stylebox = StyleBoxTexture.new()
				var texture = load("res://images/items.png") as Texture2D
				stylebox.texture = texture
				stylebox.set("region_rect", CRATE_OPEN_REGION)
				
				node.add_theme_stylebox_override("panel", stylebox)
				
				var content = PanelContainer.new()
				content.size = Vector2(64, 64)
				
				var content_bug_stylebox = StyleBoxTexture.new()
				var ntexture = load("res://images/items.png") as Texture2D
				content_bug_stylebox.texture = ntexture
				if node == panel:
					content_bug_stylebox.set("region_rect", GOLD_REGION)
				else:
					content_bug_stylebox.set("region_rect", BUG_REGION)
					
				content.add_theme_stylebox_override("panel", content_bug_stylebox)
				content.position.y -= 50
			
				content.add_to_group("prizes")
				
				node.add_child(content)
				
			var next_hbox = $VBoxContainer.get_child(cur_row_idx)
			for node in next_hbox.get_children():
				if node is Label:
					continue
				
				node.connect("gui_input", _on_box_click.bind(node))
				node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

			if cur_row_idx < 0:
				print(cur_row_idx)
				cashout()
				return
			
			$HUD/Stats.text = "TOTAL CASH: %s" % str(cur_cash)
		else: # LOST
			var gold_added = false
			var sibling_nodes = panel.get_parent().get_children()
			for node in sibling_nodes:
				if node is Label:
					continue
				
				var stylebox = StyleBoxTexture.new()
				var texture = load("res://images/items.png") as Texture2D
				stylebox.texture = texture
				stylebox.set("region_rect", CRATE_OPEN_REGION)
				
				node.add_theme_stylebox_override("panel", stylebox)
				
				var content = PanelContainer.new()
				content.size = Vector2(64, 64)
				
				var content_bug_stylebox = StyleBoxTexture.new()
				var ntexture = load("res://images/items.png") as Texture2D
				content_bug_stylebox.texture = ntexture
				if node != panel && !gold_added:
					gold_added = true
					content_bug_stylebox.set("region_rect", GOLD_REGION)
				else:
					content_bug_stylebox.set("region_rect", BUG_REGION)
					
				content.add_theme_stylebox_override("panel", content_bug_stylebox)
				content.position.y -= 50
			
				content.add_to_group("prizes")
				
				node.add_child(content)

			
			game_over()
			print("LOSE")
	

func _on_button_pressed() -> void:
	$ClickSound.play()
	if state == State.READY:
		state = State.START
		start_game()
	elif state == State.LOST:
		state = State.START
		start_game()
	elif state == State.CASHOUT:
		state = State.START
		start_game()
	elif state == State.START:
		state = State.CASHOUT
		cashout()
		
