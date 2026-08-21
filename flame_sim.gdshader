shader_type canvas_item;

// Включаем аддитивное смешивание для эффекта свечения пламени
render_mode blend_add; 

// Сюда мы положим градиент цветов огня
uniform sampler2D color_ramp; 

// Яркость пламени
uniform float fire_intensity = 1.2; 

void fragment() {
    // TEXTURE автоматически берет вашу fluid_texture из скрипта
    // Читаем плотность дыма/огня из красного канала
    float density = texture(TEXTURE, UV).r;
    // Раскрашиваем плотность с помощью градиента
    vec4 fire_color = texture(color_ramp, vec2(10.0 * density, 0.5));
    // Выводим финальный цвет, умножая на яркость
    COLOR = vec4(fire_color.rgb * fire_intensity, fire_color.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
