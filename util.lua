local util = {}

function util.bind(f, ...)
	local args = {...}
	return function() f(unpack(args)) end
end

function util.to_time(line, delay)
	return (line - 1) * 256 + delay
end

function util.from_time(time)
	local line = math.floor(time / 256) + 1
	local delay = time % 256
	return line, delay
end

function util.get_master_track_index()
	for track_index, track in ipairs(renoise.song().tracks) do
		if track.type == renoise.Track.TRACK_TYPE_MASTER then
			return track_index
		end
	end
end

function util.get_pattern_indices_in_sequencer_range(from, to)
	if from == 0 then return {} end
	local pattern_indices = {}
	for i = from, to do
		table.insert(pattern_indices, renoise.song().sequencer.pattern_sequence[i])
	end
	return pattern_indices
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
end

function util.write_effects_to_pattern(effects, pattern_index)
	local pattern = renoise.song().patterns[pattern_index]
	for _, effect in ipairs(effects) do
		if effect.line <= renoise.Pattern.MAX_NUMBER_OF_LINES then
			local column = pattern.tracks[effect.track].lines[effect.line].effect_columns[effect.column]
			column.number_string = effect.number_string
			column.amount_value = effect.amount_value
		end
	end
end

--[[
	Adds an effect to the first empty effect column in the line.
	If the effect number in a column is the same as the one we're
	going to add, go ahead and overwrite it instead of continuing
	to search for an empty column.
]]
function util.add_effect_command(pattern_index, track_index, line_number, number_string, amount_value)
	local track = renoise.song().tracks[track_index]
	local line = renoise.song().patterns[pattern_index].tracks[track_index].lines[line_number]
	for column_index, column in ipairs(line.effect_columns) do
		if column.is_empty or column.number_string == number_string then
			column.number_string = number_string
			column.amount_value = amount_value
			track.visible_effect_columns = math.max(track.visible_effect_columns, column_index)
			break
		end
	end
end

return util
