extends RefCounted
class_name UnitNamePool

const NAME_POOL: Array[String] = [
	"Garcia",
	"Rodriguez",
	"Gomez",
	"Fernandez",
	"Lopez",
	"Martinez",
	"Perez",
	"Sanchez",
	"Ramirez",
	"Torres",
	"Flores",
	"Diaz",
	"Vasquez",
	"Castro",
	"Ruiz",
	"Herrera",
	"Mendoza",
	"Silva",
	"Rojas",
	"Morales",
	"Navarro",
	"Chavez",
	"Cruz",
	"Romero",
	"Leon",
	"Paredes",
	"Vega",
	"Medina",
	"Salazar",
	"Aguilar",
	"Campos",
	"Vargas",
	"Valdez",
	"Espinoza",
	"Cardenas",
	"Huaman",
	"Quispe",
	"Mamani",
	"Condori",
	"Calla",
	"Choque",
	"Yupanqui",
	"Nina",
	"Vilca",
	"Ticona",
	"Apaza",
	"Alarcon",
	"Cabrera",
	"Benites",
	"Zuniga"
]

static var _remaining_names: Array[String] = []
static var _fallback_counter: int = 1

static func reset_pool() -> void:
	_remaining_names = NAME_POOL.duplicate()
	_remaining_names.shuffle()
	_fallback_counter = 1

static func draw_name() -> String:
	if _remaining_names.is_empty():
		var fallback_name := "Unit %d" % _fallback_counter
		_fallback_counter += 1
		return fallback_name

	var selected_name: String = _remaining_names.pop_back()
	_fallback_counter += 1
	return selected_name
