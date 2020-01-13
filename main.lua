local MAX_SAMPLE_BEAT_SYNC_LINES = 512
local MAX_LPB = 256
local DIALOG_WIDTH = 300

local function to_time(line, delay)
	return (line - 1) * 256 + delay
end

local function from_time(time)
	local line = math.floor(time / 256) + 1
	local delay = time % 256
	return line, delay
end

local function can_expand_pattern(pattern_index, factor)
	local pattern = renoise.song().patterns[pattern_index]
	return pattern.number_of_lines * factor <= renoise.Pattern.MAX_NUMBER_OF_LINES
end

local function expand_pattern(pattern_index, factor)
	local song = renoise.song()
	local pattern = song.patterns[pattern_index]
	-- get all the note events in this pattern and clear the columns
	local notes = {}
	for position, column in song.pattern_iterator:note_columns_in_pattern(pattern_index) do
		if not column.is_empty then
			table.insert(notes, {
				track = position.track,
				column = position.column,
				time = to_time(position.line, column.delay_value),
				note_value = column.note_value,
				instrument_value = column.instrument_value,
				volume_value = column.volume_value,
				panning_value = column.panning_value,
				effect_number_value = column.effect_number_value,
				effect_amount_value = column.effect_amount_value,
			})
			column:clear()
		end
	end
	-- get all the effects in this pattern and clear the columns
	local effects = {}
	for position, column in song.pattern_iterator:effect_columns_in_pattern(pattern_index) do
		if not column.is_empty then
			table.insert(effects, {
				track = position.track,
				column = position.column,
				line = position.line,
				number_string = column.number_string,
				amount_value = column.amount_value,
			})
			column:clear()
		end
	end
	-- increase the pattern length
	pattern.number_of_lines = math.min(pattern.number_of_lines * factor, renoise.Pattern.MAX_NUMBER_OF_LINES)
	-- write the notes
	for _, note in ipairs(notes) do
		note.time = note.time * factor
		local line, delay = from_time(note.time)
		if line <= renoise.Pattern.MAX_NUMBER_OF_LINES then
			local column = pattern.tracks[note.track].lines[line].note_columns[note.column]
			column.note_value = note.note_value
			column.instrument_value = note.instrument_value
			column.volume_value = note.volume_value
			column.panning_value = note.panning_value
			column.delay_value = delay
			column.effect_number_value = note.effect_number_value
			column.effect_amount_value = note.effect_amount_value
		end
	end
	-- write the effects
	for _, effect in ipairs(effects) do
		effect.line = effect.line * factor
		if effect.line <= renoise.Pattern.MAX_NUMBER_OF_LINES then
			local column = pattern.tracks[effect.track].lines[effect.line].effect_columns[effect.column]
			column.number_string = effect.number_string
			column.amount_value = effect.amount_value
		end
	end
end

local function can_expand_all_patterns(factor)
	for pattern_index in ipairs(renoise.song().patterns) do
		if not can_expand_pattern(pattern_index, factor) then
			return false
		end
	end
	return true
end

local function expand_all_patterns(factor)
	for pattern_index in ipairs(renoise.song().patterns) do
		expand_pattern(pattern_index, factor)
	end
end

local function can_adjust_beat_sync(factor)
	for _, instrument in ipairs(renoise.song().instruments) do
		for _, sample in ipairs(instrument.samples) do
			if sample.beat_sync_lines * factor > MAX_SAMPLE_BEAT_SYNC_LINES then
				return false
			end
		end
	end
	return true
end

local function adjust_beat_sync(factor)
	for _, instrument in ipairs(renoise.song().instruments) do
		for _, sample in ipairs(instrument.samples) do
			sample.beat_sync_lines = math.min(sample.beat_sync_lines * factor, MAX_SAMPLE_BEAT_SYNC_LINES)
		end
	end
end

local function can_adjust_lpb(factor)
	return renoise.song().transport.lpb * factor <= MAX_LPB
end

local function adjust_lpb(factor)
	renoise.song().transport.lpb = math.min(renoise.song().transport.lpb * factor, MAX_LPB)
end

local function showDialog()
	local vb = renoise.ViewBuilder()

	-- settings
	local factor = 2
	local should_adjust_beat_sync = true
	local should_adjust_lpb = true

	-- warnings
	local show_pattern_warning, show_beat_sync_warning, show_lpb_warning, show_warnings
	local function update_warnings()
		show_pattern_warning = not can_expand_all_patterns(factor)
		show_beat_sync_warning = should_adjust_beat_sync and not can_adjust_beat_sync(factor)
		show_lpb_warning = should_adjust_lpb and not can_adjust_lpb(factor)
		show_warnings = show_pattern_warning or show_beat_sync_warning or show_lpb_warning
	end
	local function update_warning_text()
		vb.views.pattern_warning.visible = show_pattern_warning
		vb.views.beat_sync_warning.visible = show_beat_sync_warning
		vb.views.lpb_warning.visible = show_lpb_warning
		vb.views.warnings.visible = show_warnings
		vb.views.dialog.width = DIALOG_WIDTH
	end
	update_warnings()

	renoise.app():show_custom_dialog('Expand song',
		vb:column {
			id = 'dialog',
			width = DIALOG_WIDTH,
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
				vb:row {
					spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
					vb:text {
						text = 'Expand song by a factor of:'
					},
					vb:valuebox {
						min = 1,
						value = factor,
						notifier = function(value)
							factor = value
							update_warnings()
							update_warning_text()
						end,
					},
				},
				vb:row {
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
						.. MAX_SAMPLE_BEAT_SYNC_LINES .. ' lines.',
					width = '100%',
					height = 48,
				},
				vb:multiline_text {
					id = 'lpb_warning',
					visible = show_lpb_warning,
					text = 'Some LPB values will be improperly adjusted. The max LPB value is '
						.. MAX_LPB .. ' lines.',
					width = '100%',
					height = 32,
				},
			},
			vb:button {
				text = 'Expand song',
				width = '100%',
				height = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT,
				notifier = function()
					expand_all_patterns(factor)
					if should_adjust_beat_sync then adjust_beat_sync(factor) end
					if should_adjust_lpb then adjust_lpb(factor) end
				end,
			},
		}
	)
end

renoise.tool():add_menu_entry {
	name = 'Main Menu:Tools:Expand Song...',
	invoke = showDialog,
}
