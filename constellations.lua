-- constellations; version 0.9.0
--
-- scan the stars, make music
-- an interactive Sequencer
-- for norns, crow, jf, midi
--
--
-- [controls below]
-- ENC1 == time division
-- ENC2 == y axis control
-- ENC3 == x axis control
-- ALT + ENC1 == probability
-- ALT + ENC2 == density
-- ALT + ENC3 == size
-- KEY1 == ALT
-- KEY2 == clear constellation
-- KEY3 == turn on/off
--       the targeting computer
--       [off by default]
-- ALT + KEY2 == sequence shift
-- ALT + KEY3 == sequence pop
--
-- the current clock division
--       / time multiplier
--       is displayed in the
--       top right corner
-- the current sequence length
--       is displayed in the
--       bottom left corner
-- max sequence length can
--       be set in params
--
-- crow
-- [  input2: 0-5v => Y axis ]
-- [ output1: 1 volt per octave ]
-- [ output2: clock pulse ]
-- [ output3: unipolar CV ]
-- [ output4: bipolar CV ]

include("lib/includes")

local ALT = false
local options = {}
options.OUTPUT = {
	"audio",
	"audio + midi",
	"midi",
	"crow out",
	"crow out + ii JF",
	"crow ii JF",
}

function key(n, z)
	if z == 1 then
		if n == 1 then
			ALT = true
		elseif n == 2 and ALT then
			Seq.shift()
		elseif n == 2 then
			Seq.clear_all()
		elseif n == 3 and ALT then
			Seq.pop()
		elseif n == 3 then
			Seq.toggle_lock()
		end
	else
		ALT = false
	end
end

function enc(n, d)
	if n == 1 and ALT then
		params:delta("probability", d)
	elseif n == 1 then
		params:delta("step_div", d)
	elseif n == 2 and ALT then
		params:delta("density", d)
	elseif n == 2 then
		params:delta("y_axis", d)
	elseif n == 3 and ALT then
		params:delta("size", d)
	elseif n == 3 then
		params:delta("x_axis", d)
	end
end

function redraw()
	local sn = screen
	sn.clear()
	local n = Stars.get_number()
	if n > 0 then
		local lastX
		local lastY
		for i = 1, n do
			local s = Stars.data[i]
			if s then
				-- draw the star
				sn.level(s.brightness)
				sn.circle(s.x, s.y, s.size)
				sn.fill()
				if s.TAGGED and not Seq.CLEAR then
					-- draw the TAGGED box
					sn.level(2)
					sn.rect(s.x - s.size - 1, s.y - s.size - 1, 2 + s.size * 2, 2 + s.size * 2)
					sn.stroke()

					if lastX and lastY then
						sn.level(2)
						sn.move(s.x, s.y)
						sn.line(lastX, lastY)
						sn.stroke()
					end
					lastX = s.x
					lastY = s.y
				end
			end
		end
	end

	-- draw the crosshair
	sn.level(1)
	for j = 1, params:get("crosshair_size") do
		local x = params:get("x_axis")
		local y = params:get("y_axis")
		sn.pixel(x, y)
		sn.pixel(x + j, y)
		sn.pixel(x - j, y)
		if params:get("targeting") == 2 then
			sn.pixel(x, y + j)
		end
		if params:get("targeting") == 2 then
			sn.pixel(x, y - j)
		end
	end
	sn.fill()

	-- write the size of Sequence
	sn.level(7)
	sn.move(0, 64)
	sn.text("" .. Seq.get_size())
	sn.fill()

	-- write current clock division
	sn.level(7)
	sn.move(124, 5)
	sn.text_right("" .. params:get("step_div"))
	sn.fill()

	-- ALT
	if ALT then
		sn.level(2)
		sn.rect(32, 0, 96, 68)
		sn.fill()
		sn.level(0)
		sn.font_face(3)
		sn.font_size(15)
		sn.move(36, 2 + 32)
		sn.text("constellations")
		sn.level(15)
		sn.font_face(1)
		sn.font_size(8)
		sn.move(44, 62)
		sn.text("density")
		sn.move(64, 53)
		sn.text(params:get("density"))
		sn.move(103, 62)
		sn.text("size")
		sn.move(103, 53)
		sn.text(params:get("size"))
		sn.move(74, 6)
		sn.text("probability")
		sn.move(74, 15)
		sn.text(params:get("probability"))
		sn.stroke()
	end

	sn.update()
end

local function build_params()
	params:add_separator("constellations")

	params:add_group("input & output", 4)
	params:add({
		type = "option",
		id = "output",
		name = "output",
		options = options.OUTPUT,
		action = function(value)
			Midi_util.all_notes_off()
			if value == 4 or value == 5 then
				crow.output[2].action = "pulse()"
				crow.output[3].shape = "sine"
				crow.output[4].shape = "sine"
			end
			if value == 5 or value == 6 then
				crow.ii.pullup(true)
				crow.ii.jf.mode(1)
			end
		end,
	})
	params:add({
		type = "option",
		id = "crow_input",
		name = "crow input 2",
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

	params:add_group("sequencer params", 11)
	params:add({
		type = "option",
		id = "sequencer_mode",
		name = "sequencer mode",
		options = { "beat-sync", "time-sync" },
		default = 1,
	})
	params:add({ type = "number", id = "max_size", name = "max sequence size", min = 1, max = 1500, default = 128 })
	params:add({
		type = "option",
		id = "overwrite_logic",
		name = "overwrite logic",
		options = { "low to high", "random", "none" },
		default = 1,
	})
	params:add({ type = "number", id = "step_div", name = "step division", min = 1, max = 16, default = 1 })
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
		action = Seq.build_scale
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

	params:add_group("engine params", 6)
	cs_AMP = controlspec.new(0, 1, "lin", 0, 0.5, "")
	params:add({
		type = "control",
		id = "amp",
		name = "max amplitude",
		controlspec = cs_AMP,
		action = function(x)
			engine.amp(x)
		end,
	})

	cs_REL = controlspec.new(0.1, 3.2, "lin", 0, 1.2, "s")
	params:add({
		type = "control",
		id = "release",
		name = "max release",
		controlspec = cs_REL,
		action = function(x)
			engine.release(x)
		end,
	})

	cs_PW = controlspec.new(0, 100, "lin", 0, 50, "%")
	params:add({
		type = "control",
		id = "pulsewidth",
		controlspec = cs_PW,
		action = function(x)
			engine.pw(x / 100)
		end,
	})

	cs_CUT = controlspec.new(50, 5000, "exp", 0, 800, "hz")
	params:add({
		type = "control",
		id = "cutoff",
		controlspec = cs_CUT,
		action = function(x)
			engine.cutoff(x)
		end,
	})

	cs_GAIN = controlspec.new(0, 4, "lin", 0, 1, "")
	params:add({
		type = "control",
		id = "gain",
		controlspec = cs_GAIN,
		action = function(x)
			engine.gain(x)
		end,
	})

	cs_PAN = controlspec.new(-1, 1, "lin", 0, 0, "")
	params:add({
		type = "control",
		id = "pan",
		controlspec = cs_PAN,
		action = function(x)
			engine.pan(x)
		end,
	})

	params:add_group("star params", 2)
	params:add({ type = "number", id = "density", name = "star density", min = 1, max = 100, default = 25 })
	params:add({ type = "number", id = "size", name = "star size", min = 1, max = 100, default = 1 })

	params:add_group("crosshair params", 4)
	params:add({ type = "option", id = "targeting", name = "targeting", options = { "off", "on" }, default = 1 })
	params:add({ type = "number", id = "y_axis", name = "y axis targeting", min = 0, max = 63, default = 32 })
	params:add({ type = "number", id = "x_axis", name = "x axis targeting", min = 0, max = 127, default = 64 })
	params:add({ type = "number", id = "crosshair_size", name = "size", min = 1, max = 25, default = 3 })
end

function init()
	math.randomseed(Util.time())
	norns.enc.sens(2, 2)
	norns.enc.sens(3, 2)

	-- build necessary utilities and params
	Midi_util.build_midi_device_list()
	build_params()
	Seq.build_scale_list()
	Seq.build_scale()
	Midi_util.device = midi.connect()
	Midi_util.attach_event()

	-- initialize metros
	local animate = metro.init()
	animate.time = 1 / 15
	animate.event = function()
		-- create star data
		if math.random(100) <= params:get("density") then
			local star = StarFactory:new()
			local size = math.floor(math.log(math.random(params:get("size") * 15)))
			local qt = math.floor(size / 4)
			local y = math.random(qt, 64 - qt)
			star.note = math.floor(Util.linlin(qt, 64 - qt, 0, 32, 64 - y))
			star.brightness = math.floor(math.random(1, 15))
			star.size = size
			star.y = y
			Stars.add(star)
		end
		-- apply changes
		Stars.iterate(Seq)
		-- and then draw them
		redraw()
	end
	animate:start()
	Notes_off = metro.init()
	Notes_off.event = Midi_util.all_notes_off

	-- and go
	Main_clock = clock.run(Actions.main_event)
end

function cleanup()
	Actions.stop()
	clock.cancel(Main_clock)
end
