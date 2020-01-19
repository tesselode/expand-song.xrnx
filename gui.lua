local constant = require 'constant'
local expand = require 'expand'

local Gui = {
	dialog_width = 350,
}
Gui.__index = Gui
setmetatable(Gui, {
	__call = function(self)
		local gui = setmetatable({}, self)
		gui:new()
		return gui
	end,
})

function Gui:update_warnings()
	self.show_pattern_warning = not expand.can_expand_all_patterns(self.factor)
	self.show_beat_sync_warning = self.should_adjust_beat_sync and not expand.can_adjust_beat_sync(self.factor)
	self.show_lpb_warning = self.should_adjust_lpb and not expand.can_adjust_lpb(self.factor)
	self.show_warnings = self.show_pattern_warning or self.show_beat_sync_warning or self.show_lpb_warning
end

function Gui:update_warning_text()
	self.vb.views.pattern_warning.visible = self.show_pattern_warning
	self.vb.views.beat_sync_warning.visible = self.show_beat_sync_warning
	self.vb.views.lpb_warning.visible = self.show_lpb_warning
	self.vb.views.warnings.visible = self.show_warnings
end

function Gui:update()
	self:update_warnings()
	self:update_warning_text()
	self.vb.views.dialog.width = self.dialog_width
end

function Gui:run_tool()
	expand.expand_all_patterns(self.factor)
	if self.should_adjust_beat_sync then expand.adjust_beat_sync(self.factor) end
	if self.should_adjust_lpb then expand.adjust_lpb(self.factor) end
end

function Gui:new()
	self.factor = 2
	self.should_adjust_beat_sync = true
	self.should_adjust_lpb = true
	self.vb = renoise.ViewBuilder()
	self:update_warnings()

	self.dialog = renoise.app():show_custom_dialog('Expand song',
		self.vb:column {
			id = 'dialog',
			width = self.dialog_width,
			margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
			spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
			self.vb:column {
				style = 'panel',
				width = '100%',
				margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
				spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
				self.vb:text {
					text = 'Options',
					font = 'bold',
					width = '100%',
					align = 'center',
				},
				self.vb:horizontal_aligner {
					spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
					mode = 'justify',
					self.vb:text {
						text = 'Factor'
					},
					self.vb:valuebox {
						min = 2,
						value = self.factor,
						notifier = function(value)
							self.factor = value
							self:update()
						end,
					},
				},
				self.vb:row {
					id = 'beat_sync_option',
					self.vb:checkbox {
						value = self.should_adjust_beat_sync,
						notifier = function(value)
							self.should_adjust_beat_sync = value
							self:update()
						end,
					},
					self.vb:text {text = 'Adjust sample beat sync values'}
				},
				self.vb:row {
					self.vb:checkbox {
						value = self.should_adjust_lpb,
						notifier = function(value)
							self.should_adjust_lpb = value
							self:update()
						end,
					},
					self.vb:text {text = 'Adjust lines per beat'}
				},
			},
			self.vb:column {
				id = 'warnings',
				visible = self.show_pattern_warning or self.show_beat_sync_warning or self.show_lpb_warning,
				style = 'panel',
				width = '100%',
				margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
				spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
				self.vb:text {
					text = 'Warnings',
					font = 'bold',
					width = '100%',
					align = 'center',
				},
				self.vb:multiline_text {
					id = 'pattern_warning',
					visible = self.show_pattern_warning,
					text = 'Some patterns will be truncated. Patterns have a max length of '
						.. renoise.Pattern.MAX_NUMBER_OF_LINES .. ' lines.',
					width = '100%',
					height = 32,
				},
				self.vb:multiline_text {
					id = 'beat_sync_warning',
					visible = self.show_beat_sync_warning,
					text = 'Some samples will have improperly adjusted beat sync values. Samples have a max beat sync value of '
						.. constant.max_sample_beat_sync_lines .. ' lines.',
					width = '100%',
					height = 48,
				},
				self.vb:multiline_text {
					id = 'lpb_warning',
					visible = self.show_lpb_warning,
					text = 'Some LPB values will be improperly adjusted. The max LPB value is '
						.. constant.max_lpb .. ' lines.',
					width = '100%',
					height = 32,
				},
			},
			self.vb:button {
				id = 'expand_button',
				text = 'Expand song',
				width = '100%',
				height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
				notifier = function() self:run_tool() end,
			},
		}
	)
end

return Gui
