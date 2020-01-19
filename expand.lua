local constant = require 'constant'
local util = require 'util'

local expand = {}

function expand.can_expand_pattern(pattern_index, factor)
	local pattern = renoise.song().patterns[pattern_index]
	return pattern.number_of_lines * factor <= renoise.Pattern.MAX_NUMBER_OF_LINES
end

function expand.expand_pattern_automation(pattern_index, factor)
	for _, pattern_track in ipairs(renoise.song().patterns[pattern_index].tracks) do
		for _, automation in ipairs(pattern_track.automation) do
			local points = automation.points
			for _, point in ipairs(points) do
				point.time = math.min((point.time - 1) * factor + 1, renoise.Pattern.MAX_NUMBER_OF_LINES)
			end
			automation.points = points
		end
	end
end

function expand.expand_pattern(pattern_index, factor)
	local pattern = renoise.song().patterns[pattern_index]
	-- get the notes and effects in the pattern
	local notes = util.get_notes_in_pattern(pattern_index)
	local effects = util.get_effects_in_pattern(pattern_index)
	-- clear the pattern
	util.clear_columns_in_pattern(pattern_index)
	-- increase the pattern length
	pattern.number_of_lines = math.min(pattern.number_of_lines * factor, renoise.Pattern.MAX_NUMBER_OF_LINES)
	-- adjust note and effect times
	for _, note in ipairs(notes) do
		note.time = note.time * factor
	end
	for _, effect in ipairs(effects) do
		effect.line = (effect.line - 1) * factor + 1
	end
	-- write the notes and effects
	util.write_notes_to_pattern(notes, pattern_index)
	util.write_effects_to_pattern(effects, pattern_index)
	-- expand automation
	expand.expand_pattern_automation(pattern_index, factor)
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
	expand.expand_all_patterns(factor)
	if adjust_beat_sync then expand.adjust_beat_sync(factor) end
	if adjust_lpb then expand.adjust_lpb(factor) end
end

return expand
