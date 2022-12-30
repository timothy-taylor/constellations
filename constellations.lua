-- constellations; version 0.9.2
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
-- [ output1: 1 v/o ]
-- [ output2: clock pulse ]
-- [ output3: unipolar CV ]
-- [ output4: bipolar CV ]

include("lib/includes")

local ALT = false

function init()
	math.randomseed(Util.time())
	norns.enc.sens(2, 2)
	norns.enc.sens(3, 2)

	-- build necessary utilities and params
	Midi_util.build_midi_device_list()
	Seq.build_scale_list()
	Params.build()
	Seq.build_scale()

	Midi_util.device = midi.connect()
	Midi_util.attach_event()

	-- initialize metros
	local animate = metro.init()
	animate.time = 1 / 15
	animate.event = function()
		-- create star data
		if math.random(100) <= params:get("star_density") then
			local star = StarFactory:new()
			local size = math.floor(math.log(math.random(params:get("star_size") * 15)))
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

function redraw()
	screen.clear()
  Gui.stars()
  Gui.crosshair()
  Gui.seq_size()
  Gui.clock()
	if ALT then
    Gui.alt()
	end
	screen.update()
end


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
		params:delta("star_density", d)
	elseif n == 2 then
		params:delta("y_axis", d)
	elseif n == 3 and ALT then
		params:delta("star_size", d)
	elseif n == 3 then
		params:delta("x_axis", d)
	end
end

function cleanup()
	Actions.stop()
	clock.cancel(Main_clock)
end
