local util = {}

function util.to_time(line, delay)
	return (line - 1) * 256 + delay
end

function util.from_time(time)
	local line = math.floor(time / 256) + 1
	local delay = time % 256
	return line, delay
end

return util
