local constant = require 'constant'

local function to_time(line, delay)
	return (line - 1) * 256 + delay
end

local function from_time(time)
	local line = math.floor(time / 256) + 1
	local delay = time % 256
	return line, delay
end

local expand = {}

function expand.can_expand_pattern(pattern_index, factor)
	local pattern = renoise.song().patterns[pattern_index]
	return pattern.number_of_lines * factor <= renoise.Pattern.MAX_NUMBER_OF_LINES
end

function expand.expand_pattern(pattern_index, factor)
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

function expand.can_expand_all_patterns(factor)
	for pattern_index in ipairs(renoise.song().patterns) do
		if not expand.can_expand_pattern(pattern_index, factor) then
			return false
		end
	end
	return true
end

function expand.expand_all_patterns(factor)
	for pattern_index in ipairs(renoise.song().patterns) do
		expand.expand_pattern(pattern_index, factor)
	end
end

function expand.can_expand_patterns(from, to, factor)
	if from == 0 then return end
	for pattern_index = from, to do
		if not expand.can_expand_pattern(pattern_index, factor) then
			return false
		end
	end
	return true
end

function expand.expand_patterns(from, to, factor)
	local song = renoise.song()
	local sequencer = song.sequencer
	sequencer:make_range_unique(from, to)
	for pattern_index = from, to do
		expand.expand_pattern(pattern_index, factor)
	end
end

function expand.can_adjust_beat_sync(factor)
	for _, instrument in ipairs(renoise.song().instruments) do
		for _, sample in ipairs(instrument.samples) do
			if sample.beat_sync_lines * factor > constant.max_sample_beat_sync_lines then
				return false
			end
		end
	end
	return true
end

function expand.adjust_beat_sync(factor)
	for _, instrument in ipairs(renoise.song().instruments) do
		for _, sample in ipairs(instrument.samples) do
			sample.beat_sync_lines = math.min(sample.beat_sync_lines * factor, constant.max_sample_beat_sync_lines)
		end
	end
end

function expand.can_adjust_lpb(factor)
	return renoise.song().transport.lpb * factor <= constant.max_lpb
end

function expand.adjust_lpb(factor)
	renoise.song().transport.lpb = math.min(renoise.song().transport.lpb * factor, constant.max_lpb)
end

return expand
