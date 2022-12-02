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

function Actions.main_event()
	while true do
		if Seq.get_size() < 1 and Midi_util.PLAY then
			Actions.stop()
		end

		if params:get("sequencer_mode") == 1 then
			clock.sync(1 / params:get("step_div"))
		else
			clock.sleep(Seq.get_time() / params:get("step_div"))
		end

		if Midi_util.PLAY then
			Midi_util.all_notes_off()
			if Seq.get_size() > 0 then
				Seq.increment()
				local note = Seq.get_note()
				if note then
					if math.random(100) <= params:get("probability") then
						if params:get("output") == 1 or params:get("output") == 2 then
							engine.release(Seq.get_release())
							engine.amp(Seq.get_amp())
							engine.hz(Mu.note_num_to_freq(note))
						end
						-- crow out
						if params:get("output") == 4 or params:get("output") == 5 then
							crow.output[1].volts = (note - 60) / 12
							crow.output[2].execute()
							crow.output[3].volts = Seq.get_amp_crow()
							crow.output[4].volts = Seq.get_release_crow()
						end
						-- JF out
						if params:get("output") == 5 or params:get("output") == 6 then
							crow.ii.jf.play_note((note - 60) / 12, 5)
						end
						-- MIDI out
						if params:get("output") == 2 or params:get("output") == 3 then
							Midi_util.device:note_on(note, 96, Midi_util.channel)
							table.insert(Midi_util.active_notes, note)
						end
						-- Note off timeout
						-- todo: figure out note off logic for time-sync sequencer mode
						if params:get("note_length") < 4 then
							Notes_off:start(
								(60 / clock.get_tempo() / params:get("step_div")) * params:get("note_length") * 0.25,
								1
							)
						end
					end
				end
			else
				Actions.stop()
			end
		end
	end
end

return Actions
