extends Resource
class_name DialogueResource

@export_multiline var json_data: String = "[]"

func get_data() -> Variant:
    var json = JSON.new()
    var error = json.parse(json_data)
    if error == OK:
        return json.data
    else:
        push_error("JSON parse error")
        return []
