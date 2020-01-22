local constant = require 'constant'
local expand = require 'expand'
local util = require 'util'

local dialog_width = 300

local gui = {}

function gui.show_dialog()
	local factor = 2
	local should_adjust_beat_sync = true
	local should_adjust_lpb = true
	local undo_steps = 0
	local vb = renoise.ViewBuilder()

	local show_pattern_warning, show_beat_sync_warning, show_lpb_warning, show_warnings

	local function update_warnings()
		show_pattern_warning = not expand.can_expand_all_patterns(factor)
		show_beat_sync_warning = should_adjust_beat_sync and not expand.can_adjust_beat_sync(factor)
		show_lpb_warning = should_adjust_lpb and not expand.can_adjust_lpb(factor)
		show_warnings = show_pattern_warning or show_beat_sync_warning or show_lpb_warning
	end

	local function update_warning_text()
		vb.views.pattern_warning.visible = show_pattern_warning
		vb.views.beat_sync_warning.visible = show_beat_sync_warning
		vb.views.lpb_warning.visible = show_lpb_warning
		vb.views.warnings.visible = show_warnings
		vb.views.dialog.width = dialog_width
	end

	update_warnings()

	renoise.app():show_custom_dialog('Expand song',
		vb:column {
			id = 'dialog',
			width = dialog_width,
			margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
			spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING,
			vb:column {
				style = 'panel',
				width = '100%',
				margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
				spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
				vb:text {
					text = 'Options',
					font = 'bold',
					width = '100%',
					align = 'center',
				},
				vb:horizontal_aligner {
					spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
					mode = 'justify',
					vb:text {
						text = 'Factor'
					},
					vb:valuebox {
						min = 2,
						value = factor,
						notifier = function(value)
							factor = value
							update_warnings()
							update_warning_text()
						end,
					},
				},
				vb:row {
					id = 'beat_sync_option',
					vb:checkbox {
						value = should_adjust_beat_sync,
						notifier = function(value)
							should_adjust_beat_sync = value
							update_warnings()
							update_warning_text()
						end,
					},
					vb:text {text = 'Adjust sample beat sync values'}
				},
				vb:row {
					vb:checkbox {
						value = should_adjust_lpb,
						notifier = function(value)
							should_adjust_lpb = value
							update_warnings()
							update_warning_text()
						end,
					},
					vb:text {text = 'Adjust lines per beat'}
				},
			},
			vb:column {
				id = 'warnings',
				visible = show_pattern_warning or show_beat_sync_warning or show_lpb_warning,
				style = 'panel',
				width = '100%',
				margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
				spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
				vb:text {
					text = 'Warnings',
					font = 'bold',
					width = '100%',
					align = 'center',
				},
				vb:multiline_text {
					id = 'pattern_warning',
					visible = show_pattern_warning,
					text = 'Some patterns will be truncated. Patterns have a max length of '
						.. renoise.Pattern.MAX_NUMBER_OF_LINES .. ' lines.',
					width = '100%',
					height = 32,
				},
				vb:multiline_text {
					id = 'beat_sync_warning',
					visible = show_beat_sync_warning,
					text = 'Some samples will have improperly adjusted beat sync values. Samples have a max beat sync value of '
						.. constant.max_sample_beat_sync_lines .. ' lines.',
					width = '100%',
					height = 48,
				},
				vb:multiline_text {
					id = 'lpb_warning',
					visible = show_lpb_warning,
					text = 'Some LPB values will be improperly adjusted. The max LPB value is '
						.. constant.max_lpb .. ' lines.',
					width = '100%',
					height = 32,
				},
			},
			vb:button {
				id = 'expand_song_button',
				text = 'Expand song',
				width = '100%',
				height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
				notifier = function()
					vb.views.expand_song_button.active = false
					vb.views.undo_button.visible = false
					util.run_sliced(
						expand.expand_song(factor, should_adjust_beat_sync, should_adjust_lpb),
						function(message)
							undo_steps = undo_steps + 1
							if type(message) == 'string' then
								vb.views.expand_song_button.text = message
								vb.views.dialog.width = dialog_width
							end
						end,
						function()
							vb.views.expand_song_button.text = 'Expand song'
							vb.views.undo_button.visible = true
							vb.views.expand_song_button.active = true
							vb.views.dialog.width = dialog_width
						end
					)
				end,
			},
			vb:button {
				id = 'undo_button',
				text = 'Undo',
				width = '100%',
				height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
				visible = false,
				notifier = function()
					vb.views.expand_song_button.active = false
					vb.views.undo_button.active = false
					util.run_sliced(
						coroutine.create(function()
							for i = 1, undo_steps do
								if i == 1 or i % 4 == 0 then
									coroutine.yield(('Undoing changes (%i / %i)'):format(
										i, undo_steps))
								end
								renoise.song():undo()
							end
						end),
						function(message)
							if type(message) == 'string' then
								vb.views.undo_button.text = message
								vb.views.dialog.width = dialog_width
							end
						end,
						function()
							vb.views.undo_button.text = 'Undo'
							vb.views.undo_button.visible = false
							vb.views.expand_song_button.active = true
							vb.views.undo_button.active = true
							vb.views.dialog.width = dialog_width
							undo_steps = 0
						end
					)
				end,
			}
		}
	)
end

return gui
