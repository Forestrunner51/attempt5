extends CharacterBody3D

@export var dialogue_resource: Resource

# when this function is called, start dialogue
func interact():
    if dialogue_resource:
        # accessing the autoload/singleton we created earlier
        DialogueManager.start_dialogue(self, dialogue_resource)

# test callbacks
# these functions are called by the JSON "callback" field
func start_combat():
    print("The NPC is getting angry!")
    # any combat logic can come here...

func heal_player():
    print("The NPC healed you.")
