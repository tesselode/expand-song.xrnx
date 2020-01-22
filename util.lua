local util = {}

function util.to_time(line, delay)
	return (line - 1) * 256 + delay
end

function util.from_time(time)
	local line = math.floor(time / 256) + 1
	local delay = time % 256
	return line, delay
end

function util.run_sliced(co, on_progress, on_finish)
	local function on_idle()
		if coroutine.status(co) == 'dead' then
			on_finish()
			renoise.tool().app_idle_observable:remove_notifier(on_idle)
			return
		end
		local success, message = coroutine.resume(co)
		if not success then error(message) end
		on_progress(message)
	end
	renoise.tool().app_idle_observable:add_notifier(on_idle)
end

return util
