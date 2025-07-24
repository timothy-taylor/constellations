Actions = {}
Actions.lattice = nil
Actions.sprocket = nil

function Actions.init()
    Actions.lattice = Lattice:new {
        auto = true,
        meter = 4,
        ppqn = 96
    }

    Actions.sprocket = Actions.lattice:new_sprocket {
        action = Actions.step,
        division = 1 / 4,
        enabled = false
    }

    Actions.time_sync_clock = nil
end

function Actions.start()
    Midi_util.start()

    if params:get("sequencer_mode") == 1 then
        if Actions.sprocket then Actions.sprocket.enabled = true end
        if Actions.lattice and not Actions.lattice.enabled then Actions.lattice:start() end
    else
        if Actions.time_sync_clock then
            clock.cancel(Actions.time_sync_clock)
            Actions.time_sync_clock = nil
        end

        Actions.time_sync_clock = clock.run(Actions.time_sync_loop)
    end
end

function Actions.reset() Seq.reset() end

function Actions.stop()
    Midi_util.stop()
    Midi_util.all_notes_off()

    if Actions.sprocket then Actions.sprocket.enabled = false end
    if Actions.time_sync_clock then
        clock.cancel(Actions.time_sync_clock)
        Actions.time_sync_clock = nil
    end
end

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
        local division = DIVISION_VALUES[params:get("clock_div")]
        local beat_length = 60 / clock.get_tempo()
        local step_length = beat_length * division * 4 -- convert to quarter note base
        Notes_off:start(step_length * params:get("note_length") * 0.25, 1)
    end
end

function Actions.step()
    local min = params:get("min_size")

    if Midi_util.PLAY then
        -- check if we have enough notes in sequence
        if Seq.get_size() < min then
            Actions.stop()
            return
        end

        Midi_util.all_notes_off()
        Seq.increment()
        local note = Seq.get_note()

        if note and math.random(100) <= params:get("probability") then
            engine_play(note)
            crow_play(note)
            jf_play(note)
            midi_play(note)
            midi_note_off()
        end
    end
end

function Actions.update_division(division)
    if Actions.sprocket then
        Actions.sprocket.division = division
    end
end

function Actions.update_swing(swing)
    if Actions.sprocket then
        Actions.sprocket.swing = swing
    end
end

function Actions.time_sync_loop()
    while true do
        local min = params:get("min_size")
        if Seq.get_size() < min and Midi_util.PLAY then
            Actions.stop()
        end

        local div_value = DIVISION_VALUES[params:get("clock_div")] or (1 / 4)
        clock.sleep(Seq.get_time() / (1 / div_value))

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
