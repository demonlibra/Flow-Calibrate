;-------------------------- Калибровка потока --------------------------
;-----------------------------------------------------------------------

;============================== Параметры ==============================
;-----------------------------------------------------------------------

var temperature_hotend=220    ; Указать температуру HotEnd`а, C
var temperature_hotbed=80    ; Указать температуру стола, C

var tower_width=30            ; Указать ширину параллелепипеда, мм
var tower_height=10           ; Указать высоту параллелепипеда, мм
var start_X=80                ; Указать координату X центра, мм
var start_Y=80                ; Указать координату Y центра, мм
var tower_perimeters=2        ; Указать количество периметров параллелепипеда
var skirt_offset=5            ; Указать расстояние до юбки (для прочистки сопла), мм
var brim_number=10            ; Указать количество линий каймы

var line_width=0.4            ; Указать ширину линий, мм
var line_height=0.2           ; Указать толщину линий, мм
var filament_diameter=1.75    ; Указать диаметр прутка, мм
var extrusion_multiplier=1.05 ; Указать коэффициент экструзии

var babystepping=0.00         ; Указать BabyStepping (минус уменьшает зазор), мм
var z_lift=0.0                ; Указать высоту для холостых перемещений, мм
var z_end=150                 ; Указать смещение Z по завершению теста, мм

var print_speed=20            ; Указать скорость печати, мм/сек
var travel_speed=150          ; Указать скорость холостых перемещений, мм/сек

var pa=0.025                  ; Указать коэффициент Pressure Advance

var model_fan_speed=0.3       ; Указать производительность вентилятора обдува модели (от 0.0 до 1.0)
var model_fan_layer_start=3   ; Указать номер слоя, с которого включить обдув модели
;-----------------------------------------------------------------------
;-----------------------------------------------------------------------
;=======================================================================
;=======================================================================

; --------------------------- Стартовый код ----------------------------

M300 P500                                                               ; Звуковой сигнал
T0                                                                      ; Выбор инструмента 0

M572 D0 S{var.pa}                                                       ; Установка коэффициента Pressure Advance

M83                                                                     ; Выбор относительных координат оси экструдера

M104 S{var.temperature_hotend-80}                                       ; Предварительный нагрев сопла
M190 S{var.temperature_hotbed}                                          ; Нагрев стола с ожиданием достижения температуры

G28                                                                     ; Калибровка всех осей
M290 R0 S{var.babystepping}                                             ; Задание BabyStepping 

; --------------------------- Печать юбки ------------------------------

M300 P500                                                               ; Звуковой сигнал
var brim_width=var.brim_number*var.line_width                           ; Расчёт ширины каймы
var skirt_offset_model=var.tower_width/2+var.brim_width+var.skirt_offset; Смещение юбки относительно центра печати
G90                                                                     ; Выбор абсолютных перемещений
G1 X{var.start_X-var.skirt_offset_model} Y{var.start_Y-var.skirt_offset_model} Z{var.z_lift} F{var.travel_speed*60}
G1 Z0                                                                   ; Упираем сопло в стол чтобы пластик не вытекал
M109 S{var.temperature_hotend}                                          ; Нагрев HotEnd`а с ожиданием достижения температуры

; Расчёт длин перемещения и выдавливаемого филамента квадрата прочистки сопла
var skirt_length=var.tower_width+var.brim_width*2+var.skirt_offset*2    ; Длина юбки
; Расчёт длины филамента
var skirt_filament_length=(var.line_width*var.line_height*var.skirt_length)/(pi*var.filament_diameter*var.filament_diameter/4)*var.extrusion_multiplier

M300 P500                                                               ; Звуковой сигнал
G90                                                                     ; Выбор абсолютных перемещений
G1 Z{var.line_height}                                                   ; Перемещение на высоту слоя
G91                                                                     ; Выбор относительных перемещений
G1 X{var.skirt_length} E{var.skirt_filament_length} F{var.print_speed*60}      ; Печать линии X+
G1 Y{var.skirt_length} E{var.skirt_filament_length} F{var.print_speed*60}      ; Печать линии Y+
G1 X{-var.skirt_length} E{var.skirt_filament_length} F{var.print_speed*60}     ; Печать линии X-
G1 Y{-var.skirt_length} E{var.skirt_filament_length} F{var.print_speed*60}     ; Печать линии Y-

G91 G1 Z{var.z_lift}                                                    ; Переместить сопло от стола
echo "Печать юбки завершена"

; -------------------------- Печать башни ------------------------------

var print_length=0                                                      ; Создание переменной - длина одной печатаемой стороны
var filament_length=0                                                   ; Создание переменной - длина филамента при печати одной стороны
var layers_count=1                                                      ; Создание переменной - счётчик слоёв
var layers_number=floor(var.tower_height/var.line_height)               ; Общее колиство слоёв
echo "Всего будет напечатано "^var.layers_number^" слоёв."

while var.layers_count <= var.layers_number                             ; Выполнять цикл до достижения общего количества слоёв

   if var.model_fan_layer_start==var.layers_count
      M106 S{var.model_fan_speed}                                       ; Включить обдув на указанном слое

   if var.layers_count==1
      set var.print_length=var.tower_width+var.brim_width*2             ; Если печать 1-го слоя, то учитывать кайму
   else
      set var.print_length=var.tower_width                              ; Если печать НЕ 1-го слоя, то НЕ учитывать кайму
      
   G90                                                                  ; Выбор абсолютных перемещений
   G1 X{var.start_X-var.print_length/2} Y{var.start_Y-var.print_length/2} F{var.travel_speed*60} ; Перемещение на позицию начала печати
   G1 Z{var.line_height*var.layers_count}                               ; Перемещение Z на высоту текущего слоя

   while var.print_length >= var.tower_width-var.tower_perimeters*var.line_width ; Ограничение печати периметров
      set var.filament_length=(var.line_width*var.line_height*var.print_length)/(pi*var.filament_diameter*var.filament_diameter/4)*var.extrusion_multiplier
      G91
      G1 X{var.print_length} E{var.filament_length} F{var.print_speed*60}      ; Печать линии X+
      G1 Y{var.print_length} E{var.filament_length} F{var.print_speed*60}      ; Печать линии Y+
      G1 X{-var.print_length} E{var.filament_length} F{var.print_speed*60}     ; Печать линии X-
      G1 Y{-var.print_length} E{var.filament_length} F{var.print_speed*60}     ; Печать линии Y-

      set var.print_length=var.print_length-var.line_width*2            ; Длина следующего периметра
      G1 X{var.line_width} Y{var.line_width}                            ; Переход к следующему периметру

   G91 G1 Z{var.z_lift} F{var.travel_speed*60}                          ; Опустить стол перед холостым перемещением

   set var.layers_count=var.layers_count+1                              ; Номер следующего слоя


; -------------------------- Завершающий код ---------------------------   

M104 S0                                                                 ; Выключить нагреватель HotEnd`а
M140 S0                                                                 ; Выключить нагреватель стола
M300 P1000                                                              ; Звуковой сигнал
M107                                                                    ; Выключить вентилятор обдува модели
G10                                                                     ; Ретракт
G91 G1 Z{var.z_end} F{var.travel_speed*60}                              ; Перестить стол
M290 R0 S0                                                              ; Сбросить значение BabyStepping
M207 S0                                                                 ; Сбросить значение длины ретракта
M400                                                                    ; Дождаться завершения перемещения
M18                                                                     ; Выключить питание моторов
