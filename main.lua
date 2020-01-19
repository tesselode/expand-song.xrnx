local expand = require 'expand'
local gui = require 'gui'

renoise.tool():add_menu_entry {
	name = 'Main Menu:Tools:Expand Song...',
	invoke = gui.show_dialog,
}

renoise.tool():add_keybinding {
	name = 'Pattern Editor:Expand:Expand Song...',
	invoke = gui.show_dialog,
}

renoise.tool():add_keybinding {
	name = 'Pattern Editor:Expand:Expand Song by 2x',
	invoke = function()
		expand.expand_song(2, true, true)
	end,
}
