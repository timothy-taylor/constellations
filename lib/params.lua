Params = {}

function Params.crosshair()
	params:add_group("crosshair", 4)
	params:add({ type = "option", id = "targeting", name = "targeting", options = { "off", "on" }, default = 1 })
	params:add({ type = "number", id = "y_axis", name = "y axis targeting", min = 0, max = 63, default = 32 })
	params:add({ type = "number", id = "x_axis", name = "x axis targeting", min = 0, max = 127, default = 64 })
	params:add({ type = "number", id = "crosshair_size", name = "size", min = 1, max = 25, default = 3 })
end

function Params.stars()
	params:add_group("star", 2)
	params:add({ type = "number", id = "star_density", name = "density", min = 1, max = 100, default = 15 })
	params:add({ type = "number", id = "star_size", name = "size", min = 1, max = 100, default = 25 })
end

function Params.engine()
	params:add_group("engine", 6)
	params:add({
		type = "control",
		id = "amp",
		name = "max amplitude",
		controlspec = controlspec.new(0, 1, "lin", 0, 0.7, ""),
		action = function(x)
			engine.amp(x)
		end,
	})

	params:add({
		type = "control",
		id = "release",
		name = "max release",
		controlspec = controlspec.new(0.1, 3.2, "lin", 0, 1.2, "s"),
		action = function(x)
			engine.release(x)
		end,
	})

	params:add({
		type = "control",
		id = "pulsewidth",
		controlspec = controlspec.new(0, 100, "lin", 0, 50, "%"),
		action = function(x)
			engine.pw(x / 100)
		end,
	})

	params:add({
		type = "control",
		id = "cutoff",
		controlspec = controlspec.new(50, 5000, "exp", 0, 800, "hz"),
		action = function(x)
			engine.cutoff(x)
		end,
	})

	params:add({
		type = "control",
		id = "gain",
		controlspec = controlspec.new(0, 4, "lin", 0, 1, ""),
		action = function(x)
			engine.gain(x)
		end,
	})

	params:add({
		type = "control",
		id = "pan",
		controlspec = controlspec.new(-1, 1, "lin", 0, 0, ""),
		action = function(x)
			engine.pan(x)
		end,
	})
end

function Params.sequencer()
	params:add_group("sequencer", 12)
	params:add({
		type = "option",
		id = "sequencer_mode",
		name = "mode",
		options = { "beat-sync", "time-sync" },
		default = 1,
	})
	params:add({ type = "number", id = "min_size", name = "minimum length", min = 1, max = 127, default = 1 })
	params:add({
		type = "number",
		id = "max_size",
		name = "maximum length",
		min = 1,
		max = 1500,
		default = 128,
		action = function(value)
			local min_lookup = params.lookup["min_size"]
			params.params[min_lookup].max = value

			if params:get("min_size") > value then
				params:set("min_size", value)
			end
		end,
	})
	params:add({
		type = "option",
		id = "overwrite_logic",
		name = "overwrite logic",
		options = { "low to high", "random", "none" },
		default = 1,
	})
	params:add({ type = "number", id = "step_div", name = "clock multiplier", min = 1, max = 16, default = 1 })
	params:add({
		type = "option",
		id = "note_length",
		name = "note length",
		options = { "25%", "50%", "75%", "100%" },
		default = 4,
	})
	params:add({
		type = "option",
		id = "scale_mode",
		name = "scale mode",
		options = Seq.scale_names,
		default = 5,
		action = Seq.build_scale,
	})
	params:add({
		type = "number",
		id = "root_note",
		name = "root note",
		min = 0,
		max = 127,
		default = 60,
		formatter = function(param)
			return Mu.note_num_to_name(param:get(), true)
		end,
		action = Seq.build_scale,
	})
	params:add({ type = "number", id = "probability", name = "probability", min = 0, max = 100, default = 100 })
	params:add({
		type = "trigger",
		id = "stop",
		name = "stop",
		action = function()
			Actions.stop()
			Actions.reset()
		end,
	})
	params:add({
		type = "trigger",
		id = "start",
		name = "start",
		action = Actions.start,
	})
	params:add({
		type = "trigger",
		id = "reset",
		name = "reset",
		action = Actions.reset,
	})
end

function Params.input_output()
	params:add_group("input & output", 5)
	params:add({
		type = "option",
		id = "output",
		name = "output",
		options = {
			"audio",
			"audio + midi",
			"midi",
			"crow ii JF",
		},
		action = function(value)
			Midi_util.all_notes_off()
			if value == 4 then
				crow.ii.pullup(true)
				crow.ii.jf.mode(1)
			end
		end,
	})
	params:add({
		type = "option",
		id = "crow_output",
		name = "crow output",
		options = { "off", "on" },
		action = function(value)
			if value == 2 then
				crow.output[2].action = "pulse()"
				crow.output[3].shape = "sine"
				crow.output[4].shape = "sine"
			end
		end,
	})
	params:add({
		type = "option",
		id = "crow_input",
		name = "crow input[2] => y axis",
		options = { "off", "on" },
		action = function(value)
			if value == 2 then
				crow.input[2].mode("stream", 0.01)
				crow.input[2].stream = Crosshair.set_xy_crow
			end
		end,
	})
	params:add({
		type = "option",
		id = "midi_device",
		name = "midi out device",
		options = Midi_util.devices,
		default = 1,
		action = function(value)
			Midi_util.device = midi.connect(value)
			Midi_util.attach_event()
		end,
	})
	params:add({
		type = "number",
		id = "midi_channel",
		name = "midi out channel",
		min = 1,
		max = 16,
		default = 1,
		action = function(value)
			Midi_util.all_notes_off()
			Midi_util.channel = value
		end,
	})
end

function Params.build()
	params:add_separator("constellations")
	Params.input_output()
	Params.sequencer()
	Params.engine()
	Params.stars()
	Params.crosshair()
end

return Params
