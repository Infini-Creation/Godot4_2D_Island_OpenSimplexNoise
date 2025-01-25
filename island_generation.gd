extends Node2D

#https://github.com/adcomp/Godot3_2D_Island_OpenSimplexNoise
#https://www.youtube.com/watch?v=kUm7eLfmmS0

var GRID_SIZE = 128

@onready var noise_1 : FastNoiseLite
@onready var noise_2 : FastNoiseLite

var minimap : Image = Image.new()
var grad_img : TextureRect = TextureRect.new()
var grad_data : Image
var grad_size : Vector2 = Vector2.ZERO
var paramFileBaseName : String = "user://IG-parameters-"
var paramFileExtension : String = ".data"
var paramFileIdx : int = 0

@export var ImgTexture : Texture = preload("res://grad_map_tex.png")
@export var randomizeParameters : bool = false


@export var noise1_seed : int = 0
@export var noise1_octaves : int = 4
#@export var noise1_period : int = 16
@export var noise1_lacunarity : float = 1.5
#@export var noise1_persistence : float = 0.75

@export var noise2_seed : int = 12
@export var noise2_octaves : int = 4
#@export var noise2_period : int = 64
@export var noise2_lacunarity : float = 0.75
#@export var noise2_persistence : float = 0.25


enum BIOME {SAND, DIRT_1, DIRT_2, GREEN_1, GREEN_2, GREEN_3, ROCK_1, ROCK_2, ROCK_3, WATER}
const COLOR = [
	"#fee254", 
	"#fdc742", 
	"#fb9a26", 
	"#a2d730", 
	"#74bd25", 
	"#228f12", 
	"#796e5e", 
	"#a4998b",
	"#c9bfb2",
	"#1f4677"]


func _ready():
	grad_img.texture = ImgTexture
	grad_data = grad_img.texture.get_image()
	grad_size = grad_img.texture.get_size()
	minimap = Image.create_empty(GRID_SIZE, GRID_SIZE, false, Image.FORMAT_RGBA8)
	
	noise_1 = FastNoiseLite.new()

	if randomizeParameters == true:
		print("random values")
		noise1_seed = randi_range(0, 99999999)
		noise1_octaves = randi_range(1, 10)
		noise1_lacunarity = randf_range(0.0, 10.0)
		
		noise2_seed = randi_range(0, 99999999)
		noise2_octaves = randi_range(1, 10)
		noise2_lacunarity = randf_range(0.0, 10.0)

	_generateMap()


func _generateMap():
	var noise
	var biome
	
	noise_1.seed = noise1_seed
	noise_1.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_1.fractal_octaves = noise1_octaves
	#noise_1.period = noise1_period
	noise_1.fractal_lacunarity = noise1_lacunarity
	#noise_1.persistence = noise1_persistence

	noise_2 = FastNoiseLite.new()
	noise_2.seed = noise2_seed
	noise_2.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_2.fractal_octaves = noise2_octaves
	#noise_2.period = noise2_period
	noise_2.fractal_lacunarity = noise2_lacunarity
	#noise_2.persistence = noise2_persistence

	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			noise = get_noise(x, y)
			biome = get_biome(noise)
			minimap.set_pixel(x, y, Color(COLOR[biome]))

	var tex = ImageTexture.new()
	tex = ImageTexture.create_from_image(minimap)
	$VBoxContainer/Minimap.set_texture(tex)


func get_noise(x, y):
	var n_1 = (1 + noise_1.get_noise_2d(float(x), float(y))) / 2.0
	var n_2 = (1 + noise_2.get_noise_2d(float(x), float(y))) / 2.0
	var r = grad_data.get_pixel(x * grad_size.x / GRID_SIZE, y * grad_size.y / GRID_SIZE).r
	return (n_1 + n_2*.25 - r)
#	return (n_1 + n_2*.48 - r)


func get_biome(noise):
		if noise < 0.085:
			return BIOME.WATER
		elif noise < 0.105:
			return BIOME.SAND
		elif noise < 0.12:
			return BIOME.DIRT_1
		elif noise < 0.20:
			return BIOME.DIRT_2
		elif noise < 0.35:
			return BIOME.GREEN_1
		elif noise < 0.55:
			return BIOME.GREEN_2
		elif noise < 0.65:
			return BIOME.GREEN_3
		elif noise < 0.91:
			return BIOME.ROCK_1
		elif noise < 0.92:
			return BIOME.ROCK_2
		else:
			return BIOME.ROCK_3


func create_file() -> bool:
	var save_ok : bool = false
	
	var datafile = FileAccess.open(paramFileBaseName+str(paramFileIdx)+paramFileExtension, FileAccess.WRITE)
	var error = FileAccess.get_open_error()

	if error != Error.OK:
		print("save parameters error: error=["+error+"]")
	else:
		datafile.store_pascal_string("noise1_seed="+str(noise1_seed))
		datafile.store_pascal_string("noise1_octaves="+str(noise1_octaves))
		datafile.store_pascal_string("noise1_lacunarity="+str(noise1_lacunarity))
		datafile.store_pascal_string("noise2_seed="+str(noise2_seed))
		datafile.store_pascal_string("noise2_octaves="+str(noise2_octaves))
		datafile.store_pascal_string("noise2_lacunarity="+str(noise2_lacunarity))
		datafile.close()

		save_ok = true
		paramFileIdx += 1

	return save_ok

func _on_button_pressed() -> void:
	if randomizeParameters == true:
		noise1_seed = randi_range(0, 99999999)
		noise1_octaves = randi_range(1, 10)
		noise1_lacunarity = randf_range(0.0, 10.0)
		
		noise2_seed = randi_range(0, 99999999)
		noise2_octaves = randi_range(1, 10)
		noise2_lacunarity = randf_range(0.0, 10.0)

		_generateMap()
	else:
		pass


func _on_save_param_pressed() -> void:
	create_file()
