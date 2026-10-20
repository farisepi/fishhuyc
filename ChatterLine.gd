## Одна реплика фонового диалога (chatter).
## Создаётся как ресурс .tres и заполняется в инспекторе.
## Путь: res://GameScripts/Dialogue/ChatterLine.gd
class_name ChatterLine
extends Resource

enum Speaker { SCIENTIST, MECHANIC }

## Кто говорит
@export var speaker: Speaker = Speaker.SCIENTIST

## Текст реплики. Просто строка — ругательства помечаются отдельно ниже.
@export_multiline var text: String = ""

## Слова которые будут выделены красным и с встряской панели.
## Пиши точно так же как они написаны в тексте, регистр важен.
## Пример: ["БЛЯТЬ", "НАХУЙ"]
@export var swear_words: Array[String] = []

## Высота панели в пикселях (near-режим). 0 = авто.
@export_range(0.0, 200.0, 2.0) var panel_height: float = 0.0

## Пауза перед следующей репликой (секунды). 0 = дефолт контроллера.
@export_range(0.0, 10.0, 0.1) var display_time: float = 0.0

## Особый флаг: эта реплика скрывает панель и запускает ивент
@export var is_silent: bool = false
