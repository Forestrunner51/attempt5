extends CanvasLayer



# these are references to our nodes in scene tree:
@onready var panel = $Control/Panel
@onready var npc_label = $Control/Panel/MarginContainer/VBoxContainer/NPCText
@onready var options_container = $Control/Panel/MarginContainer/VBoxContainer/OptionsContainer



# this is our state of the dialogue manager.
var current_npc: Node = null
var dialogue_list: Array = []
var current_index: int = 0


# initially we set panel to invisible
func _ready():
    panel.visible = false



# when start_dialogue is called by NPC, we parse the JSON,
# set our initial state (set current_npc we are interacting with,
# store the dialogue steps in dialogue_list and set current index
# at 0). we then call process_step to begin the dislogue.
func start_dialogue(npc: Node, resource: Resource):
    if not resource or not "json_data" in resource:
        print("Error: Invalid dialogue resource")
        return

    current_npc = npc

    var json = JSON.new()
    if json.parse(resource.json_data) == OK:
        if json.data is Array:
            dialogue_list = json.data
            current_index = 0
            _process_step()
        else:
            print("Error: JSON root must be an Array []")
    else:
        print("JSON Parse Error")





# this function fetches the current step from dislogue_list,
# and checks for following cases:

# if jump_to is there, then jump to the step with given ID in next
# step. if ID=null, then end dialogue. if id="", it doesnt count.

# if callback is there, then call that on npc object.

# if message text is there without options given,
# show continue button as option (see case 1 below).
# otherwise, show text with options below it (so player can select).
func _process_step():
    if current_index >= dialogue_list.size():
        _end_dialogue()
        return

    var step = dialogue_list[current_index]

    # checking for "jump_to" in the step
    if step.has("jump_to") and not step.has("text") and not step.has("options"):
        var jump = step["jump_to"]
        if jump == null:
            _end_dialogue()
            return
        elif jump is String and jump != "":
            _jump_to_id(jump)
            return

    # checking for callback
    if step.has("callback") and step["callback"] != "":
        if current_npc and current_npc.has_method(step["callback"]):
            current_npc.call(step["callback"])

    # case 1: standard text step
    if step.has("text") and not step.has("options"):
        _display_text_and_continue(step)
    # case 2: options step
    elif step.has("options"):
        _display_options(step)
    # if neither (e.g. just a marker or purely logic step that didn't jump), move next
    else:
        current_index += 1
        _process_step()




# we just assign the text to label, and build a continue button
func _display_text_and_continue(step):
    panel.visible = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _clear_options()

    # show speaker name if exists
    var speaker_name = step.get("speaker", "NPC")
    var text_content = step.get("text", "...")

    npc_label.text = speaker_name + ": " + text_content

    # Create a "Continue" button.
    var next_jump = step.get("jump_to", "")
    _create_button("Continue", next_jump, "")






# we loop over all the options in current step, and create
# button for each option
func _display_options(step):
    panel.visible = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _clear_options()

    npc_label.text = "..." # placeholder

    for opt in step["options"]:
        var txt = opt.get("text", "Option")
        var jump = opt.get("jump_to", "")
        var cb = opt.get("callback", "")
        _create_button(txt, jump, cb)




# next step to process will be the one with this ID.
func _jump_to_id(target_id: String):
    for i in range(dialogue_list.size()):
        if dialogue_list[i].has("id") and dialogue_list[i]["id"] == target_id:
            current_index = i
            _process_step()
            return
    print("Error: Jump ID not found: " + target_id)
    _end_dialogue()




# we reset the UI before creating next step's options buttons
func _clear_options():
    for child in options_container.get_children():
        child.queue_free()



# helper function to create a button node
func _create_button(text: String, next_jump_val, callback: String):
    var btn = Button.new()
    btn.alignment = HORIZONTAL_ALIGNMENT_LEFT


    btn.text = "▶ " + text
    btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    options_container.add_child(btn)

    # pass next_jump_val directly (can be String or null)
    btn.pressed.connect(_on_option_clicked.bind(next_jump_val, callback))



# we needed to add support for callback to our option buttons,
# so first call the callback function if given, then proceed to
# next step (either jump directly to given ID or just to next step
# in sequence if no jump specified. we also check for end
# dialogue logic.
func _on_option_clicked(next_jump_val, callback):
    # run callback
    if callback != "" and current_npc and current_npc.has_method(callback):
        current_npc.call(callback)

    # navigate
    if next_jump_val == null:
        _end_dialogue()
    elif next_jump_val is String:
        if next_jump_val == "":
            # continue to next line
            current_index += 1
            _process_step()
        else:
            # jump to specific ID
            _jump_to_id(next_jump_val)
    else:
        _end_dialogue()


# reset state and make dialogue UI invisible
func _end_dialogue():
    panel.visible = false
    current_npc = null
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
