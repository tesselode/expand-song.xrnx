local util = {}

function util.get_pattern_indices_in_sequencer_range(from, to)
	if from == 0 then return {} end
	local pattern_indices = {}
	for i = from, to do
		table.insert(pattern_indices, renoise.song().sequencer.pattern_sequence[i])
	end
	return pattern_indices
end

return util
