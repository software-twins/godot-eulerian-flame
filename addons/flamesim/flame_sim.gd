extends FlameSim

# Grid settings (must match the values passed to init_simulation)
var grid_width: int = 24
var grid_height: int = 34

var fluid_image: Image
var fluid_texture: ImageTexture

var cell_size: float = 10.0 # Size of a single cell in pixels on screen
var vec_scale: float = 20.0 # Velocity vector scale

var wind_noise: FastNoiseLite = FastNoiseLite.new()

var dynamic_obstacle: ColorRect

func add_obstacle(position, size, value, name):

	for y in range(position.y, position.y + size.y):
		for x in range(position.x, position.x + size.x):
			set_obstacle(x, y, value)
	
	if value == false:
		# If the obstacle is disabled, check if it exists in the scene.
		# If it does, remove it permanently.
		if has_node(name):
			get_node(name).queue_free()
		return
		
	# If the obstacle is enabled, create it ONLY if
	# it is not already in the scene tree.
	if has_node(name):
		return
	
	var dynamic_obstacle = Panel.new()
	
	dynamic_obstacle.name = name

	# Create a style for the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.45, 0.55, 0.85)

	# Add a light border (imitating a bevel or highlight)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.7, 0.8, 0.8) 
	style.border_blend = true ## Makes the border softer

	# Add a subtle shadow for depth
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 0
	style.shadow_offset = Vector2(4, 4)

	# Apply the style to the panel
	dynamic_obstacle.add_theme_stylebox_override("panel", style)

	# 3. Set coordinates and size
	dynamic_obstacle.position = position
	dynamic_obstacle.size = size

	# # 4. Add node
	add_child(dynamic_obstacle)
	
	
func _ready():
	# Initialize simulation via C++ method
	# (nx, ny, dx, dy, viscosity, density)
	init_simulation(grid_width, grid_height, 1.0, 1.0, 0.0001, 1.0)
	
	# 2. Create an empty image and texture matching the grid size
	fluid_image = Image.create_empty(grid_width, grid_height, false, Image.FORMAT_R8)
	fluid_texture = ImageTexture.create_from_image(fluid_image)
	
	# 3. Assign texture to our node (the shader will pick it up automatically)
	self.texture = fluid_texture
	self.texture_filter = TEXTURE_FILTER_LINEAR # Edge smoothing
	
	# Scale up on screen
	self.scale = Vector2(20.0, 20.0) 
	#self.position = Vector2(120, 320)
	
	wind_noise.seed = randi() # Random seed on every run
	wind_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	wind_noise.frequency = 0.015 # Lower value means smoother gusts

	# Set invisible physical obstacles in the C++ solver
	# Using coordinates from our Rect2
	# Small block shifted to the right of the jet center (center is at x=12)
	add_obstacle(Vector2(13, 28), Vector2(3, 2), true, "Obstacle_1")
	add_obstacle(Vector2(10, 24), Vector2(2, 2), true, "Obstacle_2")
	
	#queue_redraw()

var _time = 0

var fire_base_y = 32

func _process(delta):
	add_obstacle(Vector2(13, 28), Vector2(3, 2), %Panel.obstacle_1_visible, "Obstacle_1")
	add_obstacle(Vector2(10, 24), Vector2(2, 2), %Panel.obstacle_2_visible, "Obstacle_2")
	print(%Panel.obstacle_1_visible)
	queue_redraw()
	
	add_force(12, fire_base_y, 0.0, -800.0, delta)
	# Add density
	add_density(12, fire_base_y, %Panel.substance_amount, delta)
	print(%Panel.substance_amount)
		
	# Get current time for wind animation
	var time = Time.get_ticks_msec() / 1000.0
	
	for y in range(grid_height):
		for x in range(grid_width):
			#var local_wind = 20.0 * sin(time * 3.0 + float(x) * 0.08)
			var local_wind = %Panel.wind_force * wind_noise.get_noise_2d(float(x) * 5.0, time * 30.0)
			
			# Read noise value. It will always be random in the range from -1.0 to 1.0
			# time * 50.0 is the speed of time flowing through the noise (gust change speed)
			var noise_value = wind_noise.get_noise_1d(time * 50.0)

			# Multiply by wind force (deflection amplitude)
			var main_gust = %Panel.wind_force * noise_value
			
			var final_wind = main_gust + local_wind
			
			add_force(x, y, final_wind, 0.0, delta)
		
	# Checking that the array size matches the number of pixels (width * height)
	var bytes = get_density_bytes()
	
	if bytes.size() == grid_width * grid_height:
		# Inserting data from library into an existing image
		fluid_image.set_data (grid_width, grid_height, false, Image.FORMAT_R8, bytes)
		
		# Update the existing texture (fluid_texture.update), 
		fluid_texture.update (fluid_image)

func _on_v_slider_value_changed(value: float):
	%Panel.substance_amount = value


func _on_v_slider_2_value_changed(value: float) -> void:
	%Panel.wind_force = value # Replace with function body.

var obstacle_rect := Rect2(13, 26, 5, 2)
