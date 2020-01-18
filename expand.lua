local constant = require 'constant'
local util = require 'util'

local expand = {}

function expand.can_expand_pattern(pattern_index, factor)
	local pattern = renoise.song().patterns[pattern_index]
	return pattern.number_of_lines * factor <= renoise.Pattern.MAX_NUMBER_OF_LINES
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
	local pattern_indices = util.get_pattern_indices_in_sequencer_range(from, to)
	for _, pattern_index in ipairs(pattern_indices) do
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
	local pattern_indices = util.get_pattern_indices_in_sequencer_range(from, to)
	for _, pattern_index in ipairs(pattern_indices) do
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

-- TODO: add from and to arguments
function expand.can_adjust_lpb(factor)
	return renoise.song().transport.lpb * factor <= constant.max_lpb
end

function expand.adjust_lpb(factor, from, to)
	local song = renoise.song()
	if from and to then
		local master_track_index = util.get_master_track_index()
		local current_lpb = song.transport.lpb
		local first_pattern_index = song.sequencer.pattern_sequence[from]
		util.add_effect_command(first_pattern_index, master_track_index, 1, 'ZL', current_lpb * factor)
		local last_pattern_index = song.sequencer.pattern_sequence[to + 1]
		if last_pattern_index then
			util.add_effect_command(last_pattern_index, master_track_index, 1, 'ZL', current_lpb)
		end
	else
		song.transport.lpb = math.min(song.transport.lpb * factor, constant.max_lpb)
	end
end

return expand
