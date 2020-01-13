local gui = require 'gui'

renoise.tool():add_menu_entry {
	name = 'Main Menu:Tools:Expand Song...',
	invoke = gui.showDialog,
}
