extends PanelContainer

# Координаты по оси Y (подставьте ваши значения из Инспектора)
# Например, если высота панели 150, то спрятанная может быть -130 (чтобы торчал краешек)
var hidden_y: float = -248.0 
var shown_y: float = 0.0  
var anim_speed: float = 0.3 

@onready var wind_slider = $VBoxContainer/wind_slider
@onready var substance_slider = $VBoxContainer/substance_slider

# Флаг, чтобы не запускать анимацию каждый кадр
var is_open: bool = false 

var wind_force: float = 20.0
var substance_amount: float = 2.5

func _ready():
	# На старте прячем панель по оси Y
	position.y = hidden_y
	
	# 1. При старте игры двигаем ползунки на значения переменных
	wind_slider.value = wind_force
	substance_slider.value = substance_amount
	
	# 2. Подключаем сигналы: когда слайдер двигают, вызывается функция
	wind_slider.value_changed.connect(_on_wind_slider_changed)
	substance_slider.value_changed.connect(_on_substance_slider_changed)
	
	$VBoxContainer/HBoxContainer/CheckButton.button_pressed = true
	$VBoxContainer/HBoxContainer/CheckButton2.button_pressed = true

func _process(_delta):
	# 1. Получаем позицию мыши относительно панели
	var mouse_pos = get_local_mouse_position()
	var panel_rect = Rect2(Vector2.ZERO, size)
	
	# 2. Проверяем, находится ли точка внутри прямоугольника
	var is_mouse_inside = panel_rect.has_point(mouse_pos)
	
	# --- ФИКС ДРОЖАНИЯ ---
	# Получаем позицию мыши относительно самого окна (viewport).
	# Если мышь ушла за верхний край экрана (Y меньше 0), 
	# принудительно отменяем открытие панели.
	if get_viewport().get_mouse_position().y < 0.0:
		is_mouse_inside = false
	# -----------------------

	# 4. Логика открытия/закрытия
	if is_mouse_inside and not is_open:
		is_open = true
		var tween = create_tween()
		tween.tween_property(self, "position:y", shown_y, anim_speed).set_trans(Tween.TRANS_SINE)
		
	elif not is_mouse_inside and is_open:
		is_open = false
		var tween = create_tween()
		tween.tween_property(self, "position:y", hidden_y, anim_speed).set_trans(Tween.TRANS_SINE)

func _on_wind_slider_changed(value: float) -> void:
	wind_force = value
	print("Ветер изменен: ", wind_force)
	# Здесь вы можете передавать wind_force в вашу симуляцию

func _on_substance_slider_changed(value: float) -> void:
	substance_amount = value
	print("Вещество изменено: ", substance_amount)
	# Здесь вы можете передавать substance_amount в вашу симуляцию

var obstacle_1_visible = true

func _on_check_button_toggled(toggled_on: bool) -> void:
	obstacle_1_visible = toggled_on

var obstacle_2_visible = true

func _on_check_button_2_toggled(toggled_on: bool) -> void:
	obstacle_2_visible = toggled_on
