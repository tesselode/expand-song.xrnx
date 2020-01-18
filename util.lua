local util = {}

function util.bind(f, ...)
	local args = {...}
	return function() f(unpack(args)) end
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
