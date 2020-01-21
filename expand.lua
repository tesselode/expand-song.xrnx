local constant = require 'constant'
local util = require 'util'

local expand = {}

function expand.expand_notes(factor)
	for _, pattern in ipairs(renoise.song().patterns) do
		-- increase the length of each pattern
		pattern.number_of_lines = math.min(pattern.number_of_lines * factor, renoise.Pattern.MAX_NUMBER_OF_LINES)
		-- expand the automation
		for _, pattern_track in ipairs(pattern.tracks) do
			for _, automation in ipairs(pattern_track.automation) do
				local points = automation.points
				for _, point in ipairs(points) do
					point.time = math.min((point.time - 1) * factor + 1, renoise.Pattern.MAX_NUMBER_OF_LINES)
				end
				automation.points = points
			end
		end
	end
	-- get all the notes and effects in the song and clear the lines
	local notes = {}
	local effects = {}
	for position, line in renoise.song().pattern_iterator:lines_in_song() do
		for column_index, column in ipairs(line.note_columns) do
			if not column.is_empty then
				table.insert(notes, {
					pattern = position.pattern,
					track = position.track,
					column = column_index,
					time = util.to_time(position.line, column.delay_value) * factor,
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
		for column_index, column in ipairs(line.effect_columns) do
			if not column.is_empty then
				table.insert(effects, {
					pattern = position.pattern,
					track = position.track,
					column = column_index,
					line = (position.line - 1) * factor + 1,
					number_string = column.number_string,
					amount_value = column.amount_value,
				})
				column:clear()
			end
		end
	end
	-- write the notes and effects
	for _, note in ipairs(notes) do
		local pattern = renoise.song().patterns[note.pattern]
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
	for _, effect in ipairs(effects) do
		local pattern = renoise.song().patterns[effect.pattern]
		if effect.line <= pattern.number_of_lines then
			local column = pattern.tracks[effect.track].lines[effect.line].effect_columns[effect.column]
			column.number_string = effect.number_string
			column.amount_value = effect.amount_value
		end
	end
end

function expand.can_expand_pattern(pattern_index, factor)
	local pattern = renoise.song().patterns[pattern_index]
	return pattern.number_of_lines * factor <= renoise.Pattern.MAX_NUMBER_OF_LINES
end

function expand.can_expand_all_patterns(factor)
	for pattern_index in ipairs(renoise.song().patterns) do
		if not expand.can_expand_pattern(pattern_index, factor) then
			return false
		end
	end
	return true
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
	local song = renoise.song()
	song.transport.lpb = math.min(song.transport.lpb * factor, constant.max_lpb)
end

function expand.expand_song(factor, adjust_beat_sync, adjust_lpb)
	renoise.song():describe_undo 'Expand song'
	expand.expand_notes(factor)
	if adjust_beat_sync then expand.adjust_beat_sync(factor) end
	if adjust_lpb then expand.adjust_lpb(factor) end
end

return expand
