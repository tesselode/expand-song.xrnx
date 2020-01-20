local util = {}

function util.to_time(line, delay)
	return (line - 1) * 256 + delay
end

function util.from_time(time)
	local line = math.floor(time / 256) + 1
	local delay = time % 256
	return line, delay
end

function util.get_notes_in_pattern(pattern_index)
	local notes = {}
	for position, column in renoise.song().pattern_iterator:note_columns_in_pattern(pattern_index) do
		if not column.is_empty then
			table.insert(notes, {
				track = position.track,
				column = position.column,
				time = util.to_time(position.line, column.delay_value),
				note_value = column.note_value,
				instrument_value = column.instrument_value,
				volume_value = column.volume_value,
				panning_value = column.panning_value,
				effect_number_value = column.effect_number_value,
				effect_amount_value = column.effect_amount_value,
			})
		end
	end
	return notes
end

function util.get_effects_in_pattern(pattern_index)
	local effects = {}
	for position, column in renoise.song().pattern_iterator:effect_columns_in_pattern(pattern_index) do
		if not column.is_empty then
			table.insert(effects, {
				track = position.track,
				column = position.column,
				line = position.line,
				number_string = column.number_string,
				amount_value = column.amount_value,
			})
		end
	end
	return effects
end

function util.clear_columns_in_pattern(pattern_index)
	local pattern_iterator = renoise.song().pattern_iterator
	for _, column in pattern_iterator:note_columns_in_pattern(pattern_index) do
		column:clear()
	end
	for _, column in pattern_iterator:effect_columns_in_pattern(pattern_index) do
		column:clear()
	end
end

function util.write_notes_to_pattern(notes, pattern_index)
	local pattern = renoise.song().patterns[pattern_index]
	for _, note in ipairs(notes) do
		local line, delay = util.from_time(note.time)
		if line <= pattern.number_of_lines then
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
end

function util.write_effects_to_pattern(effects, pattern_index)
	local pattern = renoise.song().patterns[pattern_index]
	for _, effect in ipairs(effects) do
		if effect.line <= pattern.number_of_lines then
			local column = pattern.tracks[effect.track].lines[effect.line].effect_columns[effect.column]
			column.number_string = effect.number_string
			column.amount_value = effect.amount_value
		end
	end
end

return util
