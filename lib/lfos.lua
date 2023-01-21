LFOs = {}

LFOs.data = {}

function LFOs.build()
	local targeting_lfo = _Lfo:add({
    min = 0,
    max = 63,
		shape = "sine",
    period = 8,
		mode = "free",
		action = function(scaled, raw)
			if params:get("autopilot") == 2 then
				params:set("y_axis", scaled)
			end
		end,
	})

	local data = {
		name = "targeting",
		lfo = targeting_lfo,
	}

	table.insert(LFOs.data, data)
end

function LFOs.start(name)
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
