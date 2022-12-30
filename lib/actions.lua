Actions = {}

function Actions.start()
	Midi_util.start()
end

function Actions.reset()
	Seq.reset()
end

function Actions.stop()
	Midi_util.stop()
	Midi_util.all_notes_off()
end

-- helper functions for main_event
local function engine_play(note)
	if params:get("output") == 1 or params:get("output") == 2 then
		engine.release(Seq.get_release())
		engine.amp(Seq.get_amp())
		engine.hz(Mu.note_num_to_freq(note))
	end
end

local function crow_play(note)
	if params:get("crow_output") then
		crow.output[1].volts = (note - 60) / 12
		crow.output[2].execute()
		crow.output[3].volts = Seq.get_amp_crow()
		crow.output[4].volts = Seq.get_release_crow()
	end
end

local function jf_play(note)
	if params:get("output") == 4 then
		crow.ii.jf.play_note((note - 60) / 12, 5)
	end
end

local function midi_play(note)
	if params:get("output") == 2 or params:get("output") == 3 then
		Midi_util.device:note_on(note, 96, Midi_util.channel)
		table.insert(Midi_util.active_notes, note)
	end
end

local function midi_note_off()
	if params:get("note_length") < 4 then
		Notes_off:start((60 / clock.get_tempo() / params:get("step_div")) * params:get("note_length") * 0.25, 1)
	end
end

function Actions.main_event()
	while true do
		local min = params:get("min_size")
		if Seq.get_size() < min and Midi_util.PLAY then
			Actions.stop()
		end

		-- time-sync vs clock-sync modes
		if params:get("sequencer_mode") == 1 then
			clock.sync(1 / params:get("step_div"))
		else
			clock.sleep(Seq.get_time() / params:get("step_div"))
		end

		if Midi_util.PLAY then
			Midi_util.all_notes_off()
			if Seq.get_size() >= min then
				Seq.increment()
				local note = Seq.get_note()
				if note and math.random(100) <= params:get("probability") then
					engine_play(note)
					crow_play(note)
					jf_play(note)
					midi_play(note)
					midi_note_off()
				end
			else
				Actions.stop()
			end
		end
	end
end

return Actions
