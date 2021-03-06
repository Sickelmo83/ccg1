extends Node

# constants #

var SIZE = 4
var POSITIONS = 2
var NUM_START_CARDS = 4
const NUM_PLAYERS = 2
const PLANET_GAS = -1
const PLANET_BARREN = 0
const PLANET_TUNDRA = 1
const PLANET_DESERT = 2
const PLANET_TERRAN = 3
const PLANET_OCEAN = 4
const PLANET_TOXIC = 5
const PLANET_INFERNO = 6
const PLANET_ASTEROID = 7
const PLANET_TEXT = {
PLANET_GAS:"GAS_GIANT",PLANET_ASTEROID:"ASTEROID_BELT",
PLANET_BARREN:"BARREN",PLANET_TUNDRA:"TUNDRA",PLANET_DESERT:"DESERT",
PLANET_TERRAN:"TERRAN",PLANET_OCEAN:"OCEAN",PLANET_TOXIC:"TOXIC",PLANET_INFERNO:"INFERNO"}
const NEUTRAL = -1
const PLAYER1 = 0 # player
const PLAYER2 = 1 # enemy
const COLOURS = {NEUTRAL:Color(1.0,1.0,1.0),PLAYER1:Color(0.2,0.4,1.0),PLAYER2:Color(1.0,0.3,0.2)}
const NONE = -1
const HAND = 0
const EMPTY = 1
const UNIT = 2
const ALLY_UNIT = 3
const ENEMY_UNIT = 4
const PLANET = 5
const ALLY_PLANET = 6
const ENEMY_PLANET = 7
const EMPTY_OR_ENEMY = 8
const DISCARD = 9



# variables #

var planets = []
var player_is_ai = [false,true]
var deck = [[],[]]
var hand = [[],[]]
var player = NEUTRAL
var enemy = NEUTRAL
var player_select = NEUTRAL
var player_points = [{},{}]
var player_used_points = [{},{}]
var selected_hand
var selected_field
var cards = []
var field = []
var turn = -1
var select = NONE
var selected_target
var hand_offset = 0
var started = false
var discard = []
var player_name = []
var main_player = PLAYER1
var ID
var ID_enemy
var ready = false
var tutorial = false
var effect_canceled = false

const script_card_hand = preload("res://scripts/cards/card_hand.gd")
const point_textures = {
	"empire":[preload("res://images/ui/point_empire_available.png"),preload("res://images/ui/point_empire_used.png")],
	"rebels":[preload("res://images/ui/point_rebels_available.png"),preload("res://images/ui/point_rebels_used.png")],
	"pirates":[preload("res://images/ui/point_pirates_available.png"),preload("res://images/ui/point_pirates_used.png")]
}
const planet_icons = {
PLANET_GAS:[preload("res://images/planets/gas01.png"),preload("res://images/planets/gas02.png"),preload("res://images/planets/gas03.png"),preload("res://images/planets/gas04.png"),preload("res://images/planets/gas05.png")],
PLANET_BARREN:[preload("res://images/planets/barren01.png"),preload("res://images/planets/barren02.png"),preload("res://images/planets/barren03.png"),preload("res://images/planets/barren04.png"),preload("res://images/planets/barren05.png")],
PLANET_TUNDRA:[preload("res://images/planets/tundra01.png"),preload("res://images/planets/tundra02.png"),preload("res://images/planets/tundra03.png"),preload("res://images/planets/tundra04.png"),preload("res://images/planets/tundra05.png")],
PLANET_DESERT:[preload("res://images/planets/desert01.png"),preload("res://images/planets/desert02.png"),preload("res://images/planets/desert03.png"),preload("res://images/planets/desert04.png"),preload("res://images/planets/desert05.png")],
PLANET_TERRAN:[preload("res://images/planets/terran01.png"),preload("res://images/planets/terran02.png"),preload("res://images/planets/terran03.png"),preload("res://images/planets/terran04.png"),preload("res://images/planets/terran05.png")],
PLANET_OCEAN:[preload("res://images/planets/ocean01.png"),preload("res://images/planets/ocean02.png"),preload("res://images/planets/ocean03.png"),preload("res://images/planets/ocean04.png"),preload("res://images/planets/ocean05.png")],
PLANET_TOXIC:[preload("res://images/planets/toxic01.png"),preload("res://images/planets/toxic02.png"),preload("res://images/planets/toxic03.png"),preload("res://images/planets/toxic04.png"),preload("res://images/planets/toxic05.png")],
PLANET_INFERNO:[preload("res://images/planets/inferno01.png"),preload("res://images/planets/inferno02.png"),preload("res://images/planets/inferno03.png"),preload("res://images/planets/inferno04.png"),preload("res://images/planets/inferno05.png")]}


# signals #

signal target_selected(target_selected,target_type)
signal new_turn()
signal init_discarded()
signal started()
signal unit_used()
signal unit_moved()
signal unit_attacked()
signal unit_invaded()
signal effect_used(used)
signal discarded()


# classes #

class Card:
	var structure
	var damage
	var shield
	var points
	var cards
	var level
	var type
	var position
	var owner
	var enemy
	var node
	var effects
	var Main
	

class Unit:
	extends Card
	var attack_points
	var movement_points
	var dead
	
	func _init(_root,_type,_structure,_damage,_shield,_level,_effects,_player,pos,pos0,rot):
		var code = "var _self\nvar Main\n"
		var script = GDScript.new()
		Main = _root
		node = Cards.create_card(_type)
		structure = _structure
		damage = _damage
		shield = _shield
		level = _level
		type = _type
		owner = _player
		enemy = int(!owner)
		attack_points = Data.data[type]["attack_points"]
		movement_points = 0
		position = pos
		dead = false
		
		# add script to this class
		effects = Data.Effects.new()
		code = _effects.get_script().get_source_code()
		script.set_source_code(code)
		script.reload()
		effects.set_script(script)
		effects._self = self
		effects.Main = Main
		
		node.set_draw_behind_parent(true)
		node.set_name("Card")
		node.set_rotation(rot*PI)
		node.get_node("Description").set_rotation(-rot*PI)
		Main.get_node("Card_"+str(pos)+"_"+str(owner)).add_child(node)
		node.set_process(true)
		node.set_position(pos0)
		
		update()
	
	func update():
		if (structure<=0):
			structure = 0
			Main.destroy_unit(position,owner)
		else:
			dead = false
		Cards.update_values(node,level,structure,damage,shield)
		node.get_node("VBoxContainer/Structure").show()
		node.get_node("Effects/Attack").set_visible(attack_points>0)
		node.get_node("Effects/Movement").set_visible(movement_points>0)
	

class Planet:
	extends Card
	var planet
	var image
	
	func _init(_root,_type,_structure,_damage,_shield,_level,_effects,_cards,_owner,_image,pos):
		var code = "var _self\nvar Main\n"
		var script = GDScript.new()
		var img = Sprite.new()
		Main = _root
		node = Cards.base.instance()
		node.set_draw_behind_parent(true)
		node.set_name("Card")
		img.set_name("Image")
		node.get_node("Type").set_texture(Cards.icon_type["planet"])
		node.get_node("Logo").hide()
		node.get_node("Image").add_child(img)
		structure = _structure
		damage = _damage
		shield = _shield
		level = _level
		cards = _cards
		planet = _type
		points = {}
		type = ""
		position = pos
		owner = _owner
		enemy = int(!owner)
		image = _image
		
		# add script to this class
		effects = Data.Effects.new()
		if (_effects!=null):
			code = _effects.get_script().get_source_code()
		script.set_source_code(code)
		script.reload()
		effects.set_script(script)
		effects._self = self
		effects.Main = Main
		
		Main.get_node("Planet_"+str(pos)).add_child(node)
		node.set_process(true)
		
		update()
	
	func update():
		Cards.update_values(node,level,structure,damage,shield,cards,points)
		if (level==0):
			node.get_node("VBoxContainer/Level").hide()
		node.get_node("VBoxContainer/Structure").show()
		node.get_node("Header").set_modulate(COLOURS[owner])
		node.get_node("Image/Image").set_texture(Main.planet_icons[planet][image])
		if (type==""):
			node.get_node("Name").set_text(tr(PLANET_TEXT[planet]))
			node.get_node("Desc").set_text("")
		else:
			var text = ""
			node.get_node("Name").set_text(tr(Data.data[type]["name"].to_upper()))
			for c in node.get_node("Description/ScrollContainer/VBoxContainer").get_children()+node.get_node("Effects").get_children():
				if (c.get_name()!="Effect"):
					c.set_name("deleted")
					c.queue_free()
			
			# update displayed effects here
			
	


# other graphics #

var select_outline = preload("res://images/ui/card_select.png")
var select_green = preload("res://images/ui/card_select_green.png")
var card_back = preload("res://images/cards/card_back.png")


# AI functions #

var ai_class = preload("res://scripts/ai/ai_base.gd")
var ai

func ai_timer():
	get_node("AiTimer").set_wait_time(0.25)
	
	# skip AI turns
#	get_node("TimerNextTurn").start()
#	return
	
	var action
	ai.update()
	action = ai.get_action()
	printt("AI ACTION:",action)
	if (action==null):
		get_node("TimerNextTurn").start()
		return
	var f = action["function"]
	callv(f,action["arguments"])
	
	if (f=="move_unit"):
		get_node("AiTimer").set_wait_time(1.0)
	elif (f=="attack_unit"):
		get_node("AiTimer").set_wait_time(2.0)
	elif (f=="bombard_unit"):
		get_node("AiTimer").set_wait_time(1.0)
	elif (f=="discard_hand"):
		get_node("AiTimer").set_wait_time(0.5)
	
	get_node("AiTimer").start()


# card functions #

func get_card_targets(x,player,enemy):
	var targets = []
	if (cards[player][x]==null):
		return targets
	
	for y in range(floor(x/POSITIONS)*POSITIONS,(floor(x/POSITIONS)+1)*POSITIONS):
		if (cards[enemy][y]!=null):
			targets.push_back(y)
	
	return targets

func get_targets(type,effects=null,event="",ID=0,last_targets=[]):
	var targets = []
	var method = event+"_target"+str(ID+1)+"_filter"
	if (type==EMPTY):
		for x in range(SIZE*POSITIONS):
			if (cards[player][x]==null && (field[floor(x/POSITIONS)].owner==player)):
				if (effects!=null && effects.has_method(method) && !effects.call(method,x,last_targets)):
					continue
				targets.push_back(x)
	elif (type==HAND):
		for i in range(hand[player].size()):
			if (effects!=null && effects.has_method(method) && !effects.call(method,i,last_targets)):
				continue
			targets.push_back(i)
	elif (type==ALLY_PLANET):
		for x in range(SIZE):
			if (field[x]!=null && field[x].owner==player):
				if (effects!=null && effects.has_method(method) && !effects.call(method,x,last_targets)):
					continue
				targets.push_back(x)
	elif (type==ENEMY_PLANET):
		for x in range(SIZE):
			if (field[x]!=null && field[x].owner!=player):
				if (effects!=null && effects.has_method(method) && !effects.call(method,x,last_targets)):
					continue
				targets.push_back(x)
	elif (type==PLANET):
		for x in range(SIZE):
			if (effects!=null && effects.has_method(method) && !effects.call(method,x,last_targets)):
				continue
			targets.push_back(x)
	elif (type==ALLY_UNIT):
		for x in range(SIZE*POSITIONS):
			if (cards[player][x]!=null):
				if (effects!=null && effects.has_method(method) && !effects.call(method,cards[player][x],last_targets)):
					continue
				targets.push_back(x)
	elif (type==ENEMY_UNIT):
		for x in range(SIZE*POSITIONS):
			if (cards[enemy][x]!=null):
				if (effects!=null && effects.has_method(method) && !effects.call(method,cards[enemy][x],last_targets)):
					continue
				targets.push_back(x)
	
	return targets

func remove_card_planet(pos):
	if (field[pos].type==""):
		return
	
	field[pos].shield -= Data.calc_value(field[pos].type,"shield")
	field[pos].type = ""
	field[pos].level = 0
	for f in field[pos].points.keys():
		player_points[field[pos].owner][f] -= field[pos].points[f]
	field[pos].points.clear()
	field[pos].update()

func add_card_planet(pos,ID,effects):
	var card = Data.data[ID]
	field[pos].damage = 0
	field[pos].shield = 0
	field[pos].points = {}
	field[pos].cards = 0
	field[pos].type = ID
	field[pos].level = card["level"]
	field[pos].effects = effects
	
	field[pos].update()

func end_turn():
	player = NEUTRAL
	select = NONE
	get_node("TimerNextTurn").start()

func add_target(target,type,list,t,effects=null,event="",ID=0,last_targets=[]):
	printt("Selected type",type,", need",t,".")
	if !(target in get_targets(type,effects,event,ID,last_targets)):
		printt("Invalid selection!")
		return
	if (type==t):
		list.push_back(target)
	elif (target==null):
		list.clear()

func execute_effect(event,effects,player,_args=[],_targets=null):
	var target_ID = 0
	printt("execute ",event,effects,_args)
	if (effects.has_method(event)):
		var args = []+_args
		if (_targets!=null):
			# targets are already provided
			args += _targets
		else:
			# force the player to select targets
			for target in effects.get(event+"_targets"):
				queue_select(target,player,effects,event,target_ID,[]+args)
				select = target
				connect("target_selected",self,"add_target",[args,target,effects,event,target_ID,[]+args],CONNECT_ONESHOT)
				yield(self,"target_selected")
				if (args.size()<1):
					printt("cancel effect execution")
					effect_canceled = true
					emit_signal("effect_used",false)
					return
				target_ID += 1
				yield(get_tree(),"idle_frame")
		effects.callv(event,args)
	update()
	yield(get_tree(),"idle_frame")
	emit_signal("effect_used",true)

remote func use_card_effect(ID,player,targets=null):
	printt("use effect card",ID,player,hand[player][ID],hand[player])
	var card = Data.data[hand[player][ID]]
	var faction = card["faction"]
	if (card["level"]>player_points[player][faction]-player_used_points[player][faction]):
		return
	
	var enemy = int(!player)
	var effects = Data.Effects.new()
	var script = GDScript.new()
	var code = card["script"].get_script().get_source_code()
	script.set_source_code(code)
	script.reload()
	effects.set_script(script)
	effects._self = self
	effects.Main = self
	effect_canceled = false
	execute_effect("on_use",effects,player,[],targets)
	
	yield(self,"effect_used")
	if (effect_canceled):
		unselect_hand(player)
		return
	
	player_used_points[player][card["faction"]] += card["level"]
	hand[player].remove(ID)
	remove_card(ID,player)
	unselect_hand(player)
	update()

remote func use_card_planet(x,ID,player):
	printt("use planet card",x,ID,player)
	var card = Data.data[hand[player][ID]]
	var faction = card["faction"]
	if (card["level"]>player_points[player][faction]-player_used_points[player][faction]):
		return
	
	var enemy = int(!player)
	var effects = Data.Effects.new()
	var script = GDScript.new()
	var code = card["script"].get_script().get_source_code()
	script.set_source_code(code)
	script.reload()
	effects.set_script(script)
	effects._self = field[x]
	effects.Main = self
	effect_canceled = false
	remove_card_planet(x)
	add_card_planet(x,hand[player][ID],effects)
	
	player_used_points[player][Data.data[hand[player][ID]]["faction"]] += Data.calc_value(hand[player][ID],"level")
	hand[player].remove(ID)
	remove_card(ID,player)
	unselect_hand(player)
	update()
	
	execute_effect("on_use",effects,player,[x])

remote func use_card_unit(x,ID,player):
	var card = Data.data[hand[player][ID]]
	if (cards[player][x]!=null || field[floor(x/POSITIONS)].owner!=player || Data.calc_value(hand[player][ID],"level")>player_points[player][card["faction"]]-player_used_points[player][card["faction"]]):
		return
	
	var enemy = abs(1-player)
	add_unit(x,hand[player][ID],player)
	
	execute_effect("on_spawn",cards[player][x].effects,player)
	
	player_used_points[player][Data.data[hand[player][ID]]["faction"]] += Data.data[hand[player][ID]]["level"]
	unselect_hand(player)
	hand[player].remove(ID)
	remove_card(ID,player)
	update()
	emit_signal("unit_used")


func remove_cards(player,num):
	for k in range(min(num,hand[player].size())):
		var ID = randi()%(hand[player].size())
		if (get_tree().has_network_peer()):
			rpc("remove_card_ID",player,ID)
		else:
			remove_card_ID(player,ID)

func remove_card_ID(player,ID):
	hand[player].remove(ID)


remote func attack_unit(attacker,target,player,enemy):
	var card = cards[player][attacker]
	var t_card = cards[enemy][target]
	if (card==null || card.attack_points<1 || t_card==null || floor(attacker/POSITIONS)!=floor(target/POSITIONS)):
		return
	
	var damage = max(card.damage-t_card.shield,0)
	var pi = load(Data.data[card.type]["path"]+"/scenes/effects/"+Data.data[card.type]["file"]+".tscn").instance()
	var t_pos = t_card.node.get_global_position()
	var pos = card.node.get_global_position()
	
	execute_effect("on_attack",card.effects,player,[target])
	execute_effect("on_attacked",t_card.effects,enemy,[attacker])
	
#	if (damage<=0):
#		return
	
	card.attack_points -= 1
	pi.set_scale(Vector2(1,pos.distance_to(t_card.node.get_global_position())/800.0))
	pi.set_global_position(pos)
	pi.set_rotation(pos.angle_to_point(t_card.node.get_global_position())-PI/2.0)
	add_child(pi)
	t_card.structure -= damage
	card.update()
	t_card.update()
	
	unselect_unit(player)
	emit_signal("unit_attacked")

remote func bombard_unit(attacker,target,player,enemy):
	var card = cards[player][attacker]
	if (card==null || card.attack_points<1 || field[target].owner==player || floor(attacker/POSITIONS)!=target):
		return
	for x in range(target*POSITIONS,(target+1)*POSITIONS):
		if (cards[enemy][x]!=null):
			return
	
	var damage = max(card.damage-field[target].shield,0)
	var pi = load(Data.data[cards[player][attacker].type]["path"]+"/scenes/effects/"+Data.data[cards[player][attacker].type]["file"]+".tscn").instance()
	var offset = Vector2(0,0)
	var pos = cards[player][attacker].node.get_global_position()+offset
	
	execute_effect("on_bombard",card.effects,player,[target])
	execute_effect("on_bombarded",field[target].effects,enemy,[attacker])
	
#	if (damage<=0):
#		return
	
	card.attack_points -= 1
	pi.set_position(offset)
	pi.set_scale(Vector2(1,pos.distance_to(field[target].node.get_global_position())/800.0))
	pi.set_global_position(pos)
	pi.set_rotation(pos.angle_to_point(field[target].node.get_global_position())-PI/2.0)
	add_child(pi)
	field[target].structure -= damage
	if (field[target].structure<=0):
		field[target].structure = 0
		field[target].owner = player
	card.update()
	field[target].update()
	
	unselect_unit(player)
	emit_signal("unit_invaded")

remote func move_unit(from,to,player):
	var card = cards[player][from]
	if (card==null || cards[player][to]!=null || card.movement_points<1 || floor(from/POSITIONS)==floor(to/POSITIONS)):
		return
	
	var pos = card.node.get_global_position()
	get_node("Card_"+str(from)+"_"+str(player)).remove_child(card.node)
	get_node("Card_"+str(to)+"_"+str(player)).add_child(card.node)
	card.node.set_global_position(pos)
	card.node.move_to = get_node("Card_"+str(to)+"_"+str(player)).get_global_position()
	
	card.movement_points -= 1
	cards[player][to] = card
	card.position = to
	cards[player][from] = null
	card.update()
	
	execute_effect("on_moved",cards[player][to].effects,player)
	
	unselect_unit(player)
	emit_signal("unit_moved")

func add_unit(x,ID,player,pos=Vector2(0,0)):
	if (cards[player][x]!=null):
		return
	cards[player][x] = Unit.new(self,ID,Data.data[ID]["structure"],Data.data[ID]["damage"],Data.data[ID]["shield"],Data.data[ID]["level"],Data.data[ID]["script"],player,x,pos,player+main_player)
	if (pos==Vector2(0,0)):
		cards[player][x].node.set_position(cards[player][x].node.get_position()+Vector2(0,800*(0.5-player)))

func destroy_unit(x,player,explosion=true):
	var card = cards[player][x]
	if (card==null):
		return
	
	if (!card.dead):
		card.dead = true
		execute_effect("on_died",card.effects,player)
	card.node.set_name("destroyed")
	if (explosion):
		card.node.get_node("Anim").play("explode")
	else:
		card.node.queue_free()
	cards[player][x] = null

func capture_unit(pos,to,player,enemy):
	var new
#	var timer = Timer.new()
	var card = cards[enemy][pos]
	var tpos = card.node.get_global_position()
	destroy_unit(to,player,false)
	add_unit(to,card.type,player)
	new = cards[player][to]
	new.structure = card.structure
	new.damage = card.damage
	new.shield = card.shield
	new.attack_points = 0
	new.movement_points = 0
	destroy_unit(pos,enemy,false)
#	timer.set_one_shot(true)
#	timer.set_wait_time(1.0)
#	add_child(timer)
#	timer.start()
	
#	yield(timer,'timeout')
	new.node.set_global_position(tpos)

func update_resources():
	for p in range(NUM_PLAYERS):
		get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Deck/Label").set_text(str(deck[p].size()))
		for f in player_points[p].keys():
			for c in get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()).get_children():
				c.hide()
			for i in range(player_points[p][f]):
				var cols = max(floor(player_points[p][f]/3)+1,4)
				get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()).set_custom_minimum_size(Vector2(160+16*(cols-4),80))
				if (has_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point"+str(i))):
					get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point"+str(i)).set_texture(point_textures[f][0])
					get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point"+str(i)).show()
				else:
					var pi = get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point0").duplicate()
					pi.set_name("Point"+str(i))
					pi.set_position(Vector2(88,16)+Vector2(16*floor(i/3),16*(i%3)))
					get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()).add_child(pi)
					pi.show()
			for i in range(max(player_points[p][f]-player_used_points[p][f],0),player_points[p][f]):
				get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point"+str(i)).set_texture(point_textures[f][1])
				get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+f.capitalize()+"/Point"+str(i)).show()
	

func update():
	update_resources()
	for p in range(NUM_PLAYERS):
		for x in range(SIZE*POSITIONS):
			if (cards[p][x]!=null):
				cards[p][x].update()
	for x in range(SIZE):
		field[x].update()
	update_cards()


func _next_turn():
	if (!started):
		discard_cards()
	elif (player==main_player):
		effect_canceled = true
		select(null,NONE)
		emit_signal("effect_used",false)
		if (get_tree().has_network_peer()):
			rpc("next_turn")
		else:
			next_turn()

remote func next_turn():
	if (!started):
		discard_cards()
		return
	
	var num_planets = 0
	var num_units = 0
	var num_units_left = 0
	turn += 1
	player = turn%NUM_PLAYERS
	enemy = int(!player)
	player_select = player
	print("Turn "+str(turn)+": Player "+str(player)+"'s turn.")
	
	if (main_player==0 && turn>0):
		draw_card(player)
		if (turn>=NUM_PLAYERS):
			for x in range(SIZE):
				if (field[x]!=null && field[x].owner==player):
					draw_card(player)
	for f in player_used_points[player].keys():
		player_used_points[player][f] = 0
	
	for i in hand[player]+deck[player]:
		if (Data.data[i]["type"]=="unit"):
			num_units_left += 1
	for x in range(SIZE*POSITIONS):
		if (cards[player][x]!=null):
			var pos = floor(x/POSITIONS)
			var card = Data.data[cards[player][x].type]
			cards[player][x].attack_points = Data.data[cards[player][x].type]["attack_points"]
			cards[player][x].movement_points = Data.data[cards[player][x].type]["movement_points"]
			num_units += 1
#			cards[player][x].level = max(cards[player][x].level-1,1)
			execute_effect("on_next_turn",cards[player][x].effects,player,[player])
			if (player_used_points[player].has(card["faction"])):
				player_used_points[player][card["faction"]] += cards[player][x].level
		if (cards[enemy][x]!=null):
			execute_effect("on_next_turn",cards[enemy][x].effects,enemy,[player])
	for x in range(SIZE):
		if (field[x].owner==player):
			num_planets += 1
			if (field[x].structure<10):
				field[x].structure += min(10-field[x].structure,2)
#				if (field[x].structure>10):
#					field[x].structure = 10
#			field[x].level = max(field[x].level-1,1)
			
			if (field[x].type!=""):
				var card = Data.data[field[x].type]
				if (field[x].structure<1):
					field[x].structure = 1
				execute_effect("on_next_turn",field[x].effects,player,[player])
				for f in field[x].points.keys():
					player_points[player][f] += field[x].points[f]
	for f in player_used_points[player].keys():
		if (player_used_points[player][f]>player_points[player][f]):
			player_used_points[player][f] = player_points[player][f]
	update_resources()
	
	if (num_planets==0 || (deck[player].size()+hand[player].size()==0 && num_units==0)):
		print("Player "+str(player)+" lost!")
		get_node("/root/Menu").end_match(player!=main_player,(player+1)%2)
		return
	
	if (player_is_ai[player]):
		get_node("UI/Player1/VBoxContainer/Button").set_disabled(true)
		ai.reset()
		ai_timer()
	else:
		get_node("UI/Player1/VBoxContainer/Button").set_disabled(player!=main_player)
		# player has to select a card
		queue_select(HAND,player)
#		select = HAND
	
	emit_signal("new_turn")

func draw_card(player):
	# player draws one card
	var ID
	if (main_player==PLAYER1):
		ID = get_card_from_deck(player)
	if (ID!=null):
		if (get_tree().has_network_peer()):
			rpc("draw_card_ID",player,ID)
		else:
			draw_card_ID(player,ID)

func draw_cards(player,ammount):
	for i in range(ammount):
		draw_card(player)

remote func get_card_from_deck(player):
	if (deck[player].size()<1):
		return
	return randi()%(deck[player].size())

remote func draw_card_ID(player,ID):
	hand[player].push_back(deck[player][ID])
	if (player==main_player):
		add_card(hand[player].size()-1,deck[player][ID],player)
	else:
		var ci = TextureRect.new()
		ci.set_texture(card_back)
		ci.set_name("Card"+str(hand[player].size()-1))
		ci.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		ci.set_script(script_card_hand)
		ci.connect("gui_input",ci,"_input_event")
		ci.set_position(Vector2(get_node("UI/Cards2").get_size().x+250,0))
		get_node("UI/Cards2").add_child(ci)
	deck[player].remove(ID)

func _select_discard(pressed,ID):
	if (pressed):
		if !(ID in discard[PLAYER1]):
			discard[PLAYER1].push_back(ID)
	else:
		discard[PLAYER1].erase(ID)

func discard_cards():
	var timer = Timer.new()
	timer.set_one_shot(true)
	timer.set_wait_time(1.0)
	add_child(timer)
	
	for p in range(NUM_PLAYERS):
		if (!player_is_ai[p] && p!=main_player):
			continue
		
		var h
		if (player_is_ai[p]):
			discard[p] = ai.discard(hand[p])
		for ID in discard[p]:
			hand[p].erase(ID)
		h = []+hand[p]
		hand[p].clear()
		if (get_tree().has_network_peer()):
			rpc("set_hand",p,h)
		else:
			set_hand(p,h)
	get_node("UI/Player1/VBoxContainer/Button").set_text(tr("END_TURN"))
	for c in get_node("UI/HBoxContainer").get_children():
		c.target_pos = Vector2(-300,800)
	timer.start()
	emit_signal("init_discarded")
	
	yield(timer,"timeout")
	get_node("UI/HBoxContainer").hide()
	timer.queue_free()

func start():
	for p in range(NUM_PLAYERS):
		for i in range(NUM_START_CARDS-hand[p].size()):
			if (main_player==PLAYER1):
				draw_card(p)
			else:
				rpc_id(1,"draw_card",p)
	update_cards()
	started = true
	emit_signal("started")
	get_node("TimerNextTurn").start()

remote func set_hand(player,cards):
	hand[player] = cards
	for ID in cards:
		deck[player].erase(ID)
	if (ready):
		start()
	else:
		ready = true

remote func discard_hand(ID):
	printt("discard card ",ID,hand[player][ID])
	player_points[player][Data.data[hand[player][ID]]["faction"]] += 1
	player_used_points[player][Data.data[hand[player][ID]]["faction"]] += 1
	hand[player].remove(ID)
	remove_card(ID,player)
	unselect_hand(player)
	update_resources()
	emit_signal("discarded")

func _discard_hand():
	if (selected_hand!=null):
		if (get_tree().has_network_peer()):
			rpc("discard_hand",selected_hand)
		else:
			discard_hand(selected_hand)


# display cards #

func update_cards():
	for c in get_node("UI/Cards1").get_children()+get_node("UI/Cards2").get_children():
		c.hide()
	
	for i in range(hand[main_player].size()):
		if (!has_node("UI/Cards1/Card"+str(i))):
			add_card(i,hand[main_player][i],main_player)
		else:
			var bi = get_node("UI/Cards1/Card"+str(i))
			if (!bi.has_node("Card") || bi.get_node("Card").ID!=hand[main_player][i]):
				var ci = Cards.create_card(hand[main_player][i])
				if (bi.has_node("Card")):
					bi.get_node("Card").queue_free()
					bi.get_node("Card").set_name("deleted")
				ci.set_position(Vector2(175,250))
				ci.set_draw_behind_parent(true)
				bi.add_child(ci)
			bi.show()
	for i in range(hand[(main_player+1)%2].size()):
		if (!has_node("UI/Cards2/Card"+str(i))):
			var ci = TextureRect.new()
			ci.set_texture(card_back)
			ci.set_name("Card"+str(i))
			ci.set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
			ci.set_script(script_card_hand)
			ci.connect("gui_input",ci,"_input_event")
			ci.set_position(Vector2(get_node("UI/Cards2").get_size().x+250,0))
			get_node("UI/Cards2").add_child(ci)
		else:
			get_node("UI/Cards2/Card"+str(i)).show()
	

func add_card(index,ID,player):
	# add a new card to the container
	var bi = TextureButton.new()
	var outline = TextureRect.new()
	var ci = Cards.create_card(ID)
	ci.set_position(Vector2(175,250))
	ci.set_draw_behind_parent(true)
	bi.connect("pressed",self,"select_hand",[index,player])
	bi.set_custom_minimum_size(Vector2(350,500))
	bi.set_name("Card"+str(index))
	bi.set_hover_texture(select_green)
	bi.set_script(script_card_hand)
	bi.connect("gui_input",bi,"_input_event")
	bi.set_position(Vector2(-250,0))
	get_node("UI/Cards1").add_child(bi)
	bi.add_child(ci)
	outline.set_expand(true)
	outline.set_texture(select_outline)
	outline.set_modulate(Color(0.0,0.5,1.0))
	outline.set_anchor_and_margin(MARGIN_LEFT,Control.ANCHOR_BEGIN,0)
	outline.set_anchor_and_margin(MARGIN_TOP,Control.ANCHOR_BEGIN,0)
	outline.set_anchor_and_margin(MARGIN_RIGHT,Control.ANCHOR_END,0)
	outline.set_anchor_and_margin(MARGIN_BOTTOM,Control.ANCHOR_END,0)
	outline.hide()
	outline.set_name("Outline")
	bi.add_child(outline)

func remove_card(ID,player):
	# remove a card from the container
	get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(ID)).queue_free()
	get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(ID)).set_name("deleted")
	for i in range(ID+1,hand[player].size()+1):
		if (get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(i)).is_connected("pressed",self,"select_hand")):
			get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(i)).disconnect("pressed",self,"select_hand")
			get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(i)).connect("pressed",self,"select_hand",[i-1,player])
		get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(i)).set_name("Card"+str(i-1))

func update_discard_cards():
	discard.resize(NUM_PLAYERS)
	for i in range(NUM_PLAYERS):
		discard[i] = []
	for c in get_node("UI/HBoxContainer").get_children():
		c.set_name("deleted")
		c.queue_free()
	for i in range(hand[main_player].size()):
		var bi
		var ci = Cards.create_card(hand[main_player][i])
		if (!has_node("UI/HBoxContainer/Button"+str(i))):
			bi = get_node("UI/Card").duplicate()
			bi.set_name("Button"+str(i))
			get_node("UI/HBoxContainer").add_child(bi)
		else:
			bi = get_node("UI/HBoxContainer/Button"+str(i))
		bi.connect("toggled",self,"_select_discard",[hand[main_player][i]])
		bi.connect("gui_input",bi,"_input_event")
		ci.set_position(Vector2(5+175/2.0,250/2.0))
		ci.set_scale(Vector2(0.5,0.5))
		bi.add_child(ci)
		bi.show()
		bi.set_pressed(false)
		bi.target_pos = Vector2(150+200*i,500)
		bi.set_position(Vector2(-300,800))
	
	get_node("UI/HBoxContainer").show()
	get_node("UI/Player1/VBoxContainer/Button").set_text(tr("CONFIRM"))


# set up #

func draw_init():
	hand[main_player].resize(NUM_START_CARDS)
	for i in range(NUM_START_CARDS):
		var ID = randi()%(deck[main_player].size())
		hand[main_player][i] = deck[main_player][ID]
	
	for p in range(NUM_PLAYERS):
		if (player_is_ai[p] && p!=main_player):
			hand[p].resize(NUM_START_CARDS)
			for i in range(NUM_START_CARDS):
				var ID = randi()%(deck[p].size())
				hand[p][i] = deck[p][ID]

func init_field():
	var size = SIZE*POSITIONS
	var array_null = []
	var flip = 2*int(main_player==PLAYER1)-1
	array_null.resize(size)
	cards.resize(NUM_PLAYERS)
	field.resize(SIZE)
	for i in range(SIZE):
		field[i] = null
	for i in range(size):
		array_null[i] = null
	for i in range(NUM_PLAYERS):
		cards[i] = []+array_null
	
	for x in range(size):
		for y in range(2):
			var ci = get_node("Card").duplicate()
			ci.set_name("Card_"+str(x)+"_"+str(y))
			ci.set_position((Vector2(x-SIZE*POSITIONS/2.0+0.1*floor(x/POSITIONS)+0.25,flip*(0.5-y)))*Vector2(390,1100))
			ci.get_node("Button").connect("pressed",self,"select_field",[x,y,main_player])
			add_child(ci)
			ci.show()
	for x in range(SIZE):
		var pi = get_node("Card").duplicate()
		pi.set_name("Planet_"+str(x))
		pi.set_position((Vector2(x*(POSITIONS+0.1)-SIZE*POSITIONS/2.0+1.25,0))*Vector2(390,0))
		pi.get_node("Button").connect("pressed",self,"select_planet",[x,main_player])
		add_child(pi)
		pi.show()
	
	for x in range(SIZE):
		field[x] = Planet.new(self,planets[x]["type"],planets[x]["structure"],planets[x]["damage"],planets[x]["shield"],planets[x]["level"],null,planets[x]["cards"],planets[x]["owner"],planets[x]["image"],x)
	
	var homeworld = 0
	
	field[homeworld].owner = PLAYER1
	field[homeworld].structure = 9
	field[homeworld].planet = PLANET_TERRAN
	
	field[SIZE-1-homeworld].owner = PLAYER2
	field[SIZE-1-homeworld].structure = 9
	field[SIZE-1-homeworld].planet = PLANET_TERRAN
	
	for i in range(SIZE):
		field[i].update()
	
	player_points.resize(NUM_PLAYERS)
	player_used_points.resize(NUM_PLAYERS)
	for p in range(NUM_PLAYERS):
		player_points[p] = {}
		player_used_points[p] = {}
		for ID in deck[p]:
			if (!player_points[p].has(Data.data[ID]["faction"])):
				player_points[p][Data.data[ID]["faction"]] = 2
				player_used_points[p][Data.data[ID]["faction"]] = 0
				get_node("UI/Player"+str(int(p!=main_player)+1)+"/VBoxContainer/Points"+Data.data[ID]["faction"].capitalize()).show()
		for f in player_points[p].keys():
			player_points[p][f] += 2-player_points[p].size()
	
	get_node("Camera").set_position(Vector2(0,150))


# resize screen #

func _resize():
	var zoom = max((395.0*SIZE*POSITIONS+150.0)/OS.get_window_size().x,2800.0/OS.get_window_size().y)
	get_node("Camera").make_current()
	get_node("Camera").set_zoom(zoom*Vector2(1,1))

# input #

func button_end_turn():
	if (player<0 || player_is_ai[player] || player!=main_player):
		return
	
	unselect_hand(player)
	unselect_unit(player)
	end_turn()

func clear_hints():
	for i in range(hand[player].size()):
		if (has_node("UI/Cards1/Card"+str(i)+"/Outline")):
			get_node("UI/Cards1/Card"+str(i)+"/Outline").hide()
	for x in range(SIZE*POSITIONS):
		for y in range(2):
			get_node("Card_"+str(x)+"_"+str(y)+"/Select").hide()
	for x in range(SIZE):
		get_node("Planet_"+str(x)+"/Select").hide()
	

remote func select(target,type):
	emit_signal("target_selected",target,type)

func queue_select(target,player,effects=null,event="",ID=0,last_targets=[]):
	var enemy = int(!player)
	var targets = get_targets(target,effects,event,ID,last_targets)
	print("select "+str(target)+" (valid are "+str(targets)+")...")
	select = target
	player_select = player
	
	# display visual hints
	clear_hints()
	if (select==EMPTY):
		for x in range(targets):
			get_node("Card_"+str(x)+"_"+str(player)+"/Select").show()
			get_node("Card_"+str(x)+"_"+str(player)+"/Select").set_modulate(Color(0.0,1.0,0.0))
	elif (select==HAND && player==main_player):
		for i in targets:
			var card = Data.data[hand[player][i]]
			if (player_points[player][card["faction"]]-player_used_points[player][card["faction"]]>=card["level"]):
				get_node("UI/Cards1/Card"+str(i)+"/Outline").show()
	elif (select==ALLY_PLANET):
		for x in targets:
			get_node("Planet_"+str(x)+"/Select").show()
			get_node("Planet_"+str(x)+"/Select").set_modulate(Color(0.0,1.0,0.0))
	elif (select==ENEMY_PLANET):
		for x in targets:
			get_node("Planet_"+str(x)+"/Select").show()
			get_node("Planet_"+str(x)+"/Select").set_modulate(Color(1.0,0.0,0.0))
	elif (select==PLANET):
		for x in targets:
			get_node("Planet_"+str(x)+"/Select").show()
			get_node("Planet_"+str(x)+"/Select").set_modulate(Color(0.0,0.0,1.0))
	elif (select==ALLY_UNIT):
		for x in targets:
			get_node("Card_"+str(x)+"_"+str(player)+"/Select").set_modulate(Color(0.0,1.0,0.0))
			get_node("Card_"+str(x)+"_"+str(player)+"/Select").show()
	elif (select==ENEMY_UNIT):
		for x in targets:
			get_node("Card_"+str(x)+"_"+str(enemy)+"/Select").set_modulate(Color(1.0,0.0,0.0))
			get_node("Card_"+str(x)+"_"+str(enemy)+"/Select").show()
	elif (select==UNIT):
		for p in range(NUM_PLAYERS):
			for x in range(SIZE*POSITIONS):
				if (cards[p][x]!=null):
					get_node("Card_"+str(x)+"_"+str(p)+"/Select").set_modulate(Color(0.0,0.0,1.0))
					get_node("Card_"+str(x)+"_"+str(p)+"/Select").show()
	
	if (player_is_ai[player]):
		var t = ai.get_target(select,effects,event,ID,last_targets,targets)
		if (t==null):
			unselect_hand(player)
			unselect_unit(player)
			emit_signal("effect_used",false)
			emit_signal("target_selected",null,NONE)
			select = HAND
		else:
			if (get_tree().has_network_peer()):
				rpc("select",t,select)
			else:
				select(t,select)

func select_hand(index,player):
	if (player_is_ai[player] || player!=player_select):
		return
	
	var faction = Data.data[hand[player][index]]["faction"]
	if (select==EMPTY):
		effect_canceled = true
		emit_signal("effect_used",false)
		emit_signal("target_selected",null,NONE)
		unselect_hand(player)
	if (select==HAND && Data.calc_value(hand[player][index],"level")<=player_points[player][faction]-player_used_points[player][faction]):
		var type = Data.data[hand[player][index]]["type"]
		selected_hand = index
		get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(index)+"/Outline").show()
		get_node("UI/Player1/VBoxContainer/ButtonD").set_disabled(false)
		if (type=="unit"):
			select = EMPTY
			for x in range(SIZE*POSITIONS):
				if (cards[player][x]==null && (field[floor(x/POSITIONS)].owner==player)):
					get_node("Card_"+str(x)+"_"+str(player)+"/Select").show()
					get_node("Card_"+str(x)+"_"+str(player)+"/Select").set_modulate(Color(0.0,1.0,0.0))
		elif (type=="planet"):
			select = Data.TARGET_TYPE[Data.data[hand[player][index]]["target"]]
			if (select==ALLY_PLANET):
				for x in range(SIZE):
					if (field[x]!=null && field[x].owner==player):
						get_node("Planet_"+str(x)+"/Select").show()
						get_node("Planet_"+str(x)+"/Select").set_modulate(Color(0.0,0.0,1.0))
			elif (select==ENEMY_PLANET):
				for x in range(SIZE):
					if (field[x]!=null && field[x].owner!=player):
						get_node("Planet_"+str(x)+"/Select").show()
						get_node("Planet_"+str(x)+"/Select").set_modulate(Color(0.0,0.0,1.0))
		elif (type=="effect"):
			if (get_tree().has_network_peer()):
				rpc("use_card_effect",selected_hand,player)
			else:
				use_card_effect(selected_hand,player)
	elif (select==HAND && Data.data[hand[player][index]]["level"]>player_points[player][faction]-player_used_points[player][faction]):
		selected_hand = index
		select = DISCARD
		get_node("UI/Cards"+str(int(player!=main_player)+1)+"/Card"+str(index)+"/Outline").show()
		get_node("UI/Player1/VBoxContainer/ButtonD").set_disabled(false)

func unselect_hand(player):
	if (player!=player_select):
		return
	
	if (selected_hand!=null):
		clear_hints()
		selected_hand = null
#		select = HAND
		effect_canceled = true
		selected_target = null
		queue_select(HAND,player)
#		emit_signal("effect_used",false)
#		emit_signal("target_selected",null,NONE)
	get_node("UI/Player1/VBoxContainer/ButtonD").set_disabled(true)

func select_unit(x,p,player):
	if (player<0 || player_is_ai[player]  || player!=player_select || select!=HAND || cards[p][x]==null || p!=player):
		return
	
	var enemy = PLAYER1
	if (player==PLAYER1):
		enemy = PLAYER2
	selected_field = x
	select = EMPTY_OR_ENEMY
	get_node("Card_"+str(x)+"_"+str(p)+"/Select").set_modulate(Color(0.0,1.0,0.0))
	get_node("Card_"+str(x)+"_"+str(p)+"/Select").show()
	if (cards[p][x].attack_points>0):
		var guarded = false
		for y in get_card_targets(x,p,enemy):
			get_node("Card_"+str(y)+"_"+str(enemy)+"/Select").set_modulate(Color(1.0,0.0,0.0))
			get_node("Card_"+str(y)+"_"+str(enemy)+"/Select").show()
			guarded = true
		if (!guarded && field[floor(x/POSITIONS)].owner!=player):
			get_node("Planet_"+str(floor(x/POSITIONS))+"/Select").set_modulate(Color(1.0,0.0,0.0))
			get_node("Planet_"+str(floor(x/POSITIONS))+"/Select").show()
	if (cards[p][x].movement_points>0):
		for y in range(SIZE*POSITIONS):
			if (cards[player][y]==null && floor(y/POSITIONS)!=floor(x/POSITIONS)):
				get_node("Card_"+str(y)+"_"+str(player)+"/Select").set_modulate(Color(0.0,0.25,1.0))
				get_node("Card_"+str(y)+"_"+str(player)+"/Select").show()

func unselect_unit(player):
	if (selected_field==null || player!=player_select):
		return
	
	for x in range(SIZE*POSITIONS):
		for y in range(2):
			get_node("Card_"+str(x)+"_"+str(y)+"/Select").hide()
	for x in range(SIZE):
		get_node("Planet_"+str(x)+"/Select").hide()
	selected_field = null
	if (player>=0 && !player_is_ai[player]):
		select = HAND

func select_field(x,p,player):
	if (player<0 || player_is_ai[player] || player!=player_select):
		return
	
	if (select==EMPTY):
		if (selected_hand!=null):
			if (get_tree().has_network_peer()):
				rpc("use_card_unit",x,selected_hand,player)
			else:
				use_card_unit(x,selected_hand,player)
			selected_target = null
#			emit_signal("target_selected",selected_target,NONE)
	elif (select==HAND):
		if (cards[p][x]!=null):
			selected_target = null
#			emit_signal("target_selected",selected_target,NONE)
			select_unit(x,p,player)
	elif (select==EMPTY_OR_ENEMY):
		if (cards[p][x]!=null && player!=p):
			if (get_tree().has_network_peer()):
				rpc("attack_unit",selected_field,x,player,p)
			else:
				attack_unit(selected_field,x,player,p)
			selected_target = null
#			emit_signal("target_selected",selected_target,NONE)
		elif (cards[p][x]==null && player==p):
			if (get_tree().has_network_peer()):
				rpc("move_unit",selected_field,x,player)
			else:
				move_unit(selected_field,x,player)
			selected_target = null
#			emit_signal("target_selected",selected_target,NONE)
	elif (select==ENEMY_UNIT || select==ALLY_UNIT):
		if (cards[p][x]!=null):
			var type = ALLY_UNIT
			if (p!=player):
				type = ENEMY_UNIT
			selected_target = x
#			emit_signal("target_selected",selected_target,type)
			if (get_tree().has_network_peer()):
				rpc("select",selected_target,type)
			else:
				select(selected_target,type)

func select_planet(x,player):
	if (player<0 || player_is_ai[player] || player!=player_select):
		return
	
	var enemy = PLAYER1
	if (player==PLAYER1):
		enemy = PLAYER2
	if (select==ALLY_PLANET):
		if (field[x]!=null && field[x].owner==player):
			if (Data.data[hand[player][selected_hand]]["type"]=="planet"):
				if (get_tree().has_network_peer()):
					rpc("use_card_planet",x,selected_hand,player)
				else:
					use_card_planet(x,selected_hand,player)
				return
			selected_target = x
#			emit_signal("target_selected",selected_target,ALLY_PLANET)
			if (get_tree().has_network_peer()):
				rpc("select",selected_target,ALLY_PLANET)
			else:
				select(selected_target,ALLY_PLANET)
	elif (select==ENEMY_PLANET):
		if (field[x]!=null && field[x].owner!=player):
			if (Data.data[hand[player][selected_hand]]["type"]=="planet"):
				if (get_tree().has_network_peer()):
					rpc("use_card_planet",x,selected_hand,player)
				else:
					use_card_planet(x,selected_hand,player)
				return
			selected_target = x
#			emit_signal("target_selected",selected_target,ENEMY_PLANET)
			if (get_tree().has_network_peer()):
				rpc("select",selected_target,ENEMY_PLANET)
			else:
				select(selected_target,ENEMY_PLANET)
	elif (select==EMPTY_OR_ENEMY):
		var guarded = false
		for x1 in range(x*POSITIONS,(x+1)*POSITIONS):
			if (cards[enemy][x1]!=null):
				guarded = true
		if (!guarded && field[x].owner!=player):
			if (get_tree().has_network_peer()):
				rpc("bombard_unit",selected_field,x,player,enemy)
			else:
				bombard_unit(selected_field,x,player,enemy)
			selected_target = null
#			emit_signal("target_selected",selected_target,NONE)

func _input(event):
	if (player<0 || player_is_ai[player] || player!=main_player):
		return
	
#	if (event is InputEventMouseButton && event.pressed && event.button_index==2):
	if (event.is_action_pressed("RMB")):
		if (select!=NONE):
			unselect_hand(player)
			unselect_unit(player)
			emit_signal("effect_used",false)
			emit_signal("target_selected",null,NONE)
			select = HAND

func _process(delta):
	var last_pos = Vector2(50,200)
	var max_length = get_node("UI/Cards1").get_size().x-100
	var max_delta = max_length/max(get_node("UI/Cards1").get_child_count(),1)
	
	for c in get_node("UI/Cards1").get_children():
		c.target_pos = last_pos+Vector2(c.get_size().x*(c.get_scale().x-0.5)/2.0,0)
		last_pos.x += min(c.get_size().x*c.get_scale().x+8,max_delta)
	if (last_pos.x+350>max_length):
		var offset = ceil((last_pos.x+350-max_length)/(get_node("UI/Cards1").get_child_count()-1))
		for c in get_node("UI/Cards1").get_children():
			c.target_pos.x -= offset
	
	last_pos = Vector2(0,350)
	max_length = get_node("UI/Cards2").get_size().x-100
	max_delta = max_length/max(get_node("UI/Cards2").get_child_count(),1)
	for c in get_node("UI/Cards2").get_children():
		c.target_pos = last_pos+Vector2(c.get_size().x*(c.get_scale().x-0.5)/2.0,0)
		last_pos.x += min(c.get_size().x*c.get_scale().x+8,max_delta)
	if (last_pos.x+350>max_length):
		var offset = ceil((last_pos.x+350-max_length)/(get_node("UI/Cards2").get_child_count()-1))
		for c in get_node("UI/Cards2").get_children():
			c.target_pos.x -= offset
	
	var pos = get_node("UI/Cards1").get_margin(MARGIN_BOTTOM)
	pos = pos+delta*10*(hand_offset-pos)
	get_node("UI/Cards1").set_margin(MARGIN_BOTTOM,pos)
	pos = get_node("UI/Cards1").get_margin(MARGIN_TOP)
	pos = pos+delta*10*(200+hand_offset-pos)
	get_node("UI/Cards1").set_margin(MARGIN_TOP,pos)
	pos = get_node("UI/Cards2").get_margin(MARGIN_BOTTOM)
	pos = pos+delta*10*(300-hand_offset-pos)
	get_node("UI/Cards2").set_margin(MARGIN_BOTTOM,pos)
	pos = get_node("UI/Cards2").get_margin(MARGIN_TOP)
	pos = pos+delta*10*(100-hand_offset-pos)
	get_node("UI/Cards2").set_margin(MARGIN_TOP,pos)

func _ready():
	set_process(true)
	set_process_input(true)
	get_tree().connect("screen_resized",self,"_resize")
	_resize()
	get_node("UI/Player1/VBoxContainer/Button").connect("pressed",self,"_next_turn")
	get_node("UI/Player1/VBoxContainer/ButtonD").connect("pressed",self,"_discard_hand")
	rpc_config("set_hand",RPC_MODE_SYNC)
	rpc_config("use_card_unit",RPC_MODE_SYNC)
	rpc_config("use_card_effect",RPC_MODE_SYNC)
	rpc_config("use_card_planet",RPC_MODE_SYNC)
	rpc_config("attack_unit",RPC_MODE_SYNC)
	rpc_config("bombard_unit",RPC_MODE_SYNC)
	rpc_config("move_unit",RPC_MODE_SYNC)
	rpc_config("discard_hand",RPC_MODE_SYNC)
	rpc_config("next_turn",RPC_MODE_SYNC)
	rpc_config("draw_card_ID",RPC_MODE_SYNC)
	rpc_config("select",RPC_MODE_SYNC)
	
	init_field()
	draw_init()
	
	update_resources()
	ai = ai_class.new(PLAYER2,hand,deck,cards,field,player_points[PLAYER2],player_used_points[PLAYER2],SIZE,POSITIONS,self)
	
	update_discard_cards()
