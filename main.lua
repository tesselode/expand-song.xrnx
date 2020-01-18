local Gui = require 'gui'

local gui

renoise.tool():add_menu_entry {
	name = 'Main Menu:Tools:Expand Song...',
	invoke = function()
		if gui then gui:destroy() end
		gui = Gui()
	end,
}
