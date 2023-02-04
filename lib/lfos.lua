LFOs = {}

LFOs.data = {}

function LFOs.build()
	local targeting = {
		name = "targeting",
		lfo = _Lfo:add({
			min = 0,
			max = 63,
			shape = "sine",
			period = 8,
			mode = "free",
			action = function(scaled)
				if params:get("autopilot") == 2 then
					params:set("y_axis", scaled)
				end
			end,
		}),
	}

	table.insert(LFOs.data, targeting)
end

function LFOs.is_empty()
	return #LFOs.data == 0
end

function LFOs.set(name, param, val)
	if LFOs.is_empty() then
		return
	end

	for _, v in ipairs(LFOs.data) do
		if name == nil then
			v.lfo:set(param, val)
		end

		if v.name == name then
			v.lfo:set(param, val)
		end
	end
end

function LFOs.start(name)
	if LFOs.is_empty() then
		return
	end

	for _, v in ipairs(LFOs.data) do
		if name == nil then
			v.lfo:start()
		end

		if v.name == name then
			v.lfo:start()
		end
	end
end

function LFOs.stop(name)
	if LFOs.is_empty() then
		return
	end

	for _, v in ipairs(LFOs.data) do
		if name == nil then
			v.lfo:stop()
		end

		if v.name == name then
			v.lfo:stop()
		end
	end
end

return LFOs
