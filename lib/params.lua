Params = {}

function Params.navigation()
    params:add_group("navigation", 8)
    params:add({ type = "option", id = "cursor_type", name = "type", options = { "crosshair", "ufo" }, default = 2 })
    params:add({ type = "option", id = "targeting", name = "targeting", options = { "off", "on" }, default = 1 })
    params:add({ type = "number", id = "crosshair_size", name = "targeting size", min = 1, max = 25, default = 3 })
    params:add({ type = "option", id = "autopilot", name = "autopilot", options = { "off", "on" }, default = 1 })
    params:add({
        type = "option",
        id = "autopilot_shape",
        name = "autopilot type",
        options = { "classical", "quantum" },
        default = 1,
        action = function(x)
            if LFOs then
                local shapes = { "sine", "random" }
                LFOs.set("targeting", "shape", shapes[x])
            end
        end,
    })
    params:add({
        type = "control",
        id = "autopilot_depth",
        name = "autopilot depth",
        controlspec = controlspec.new(0.0, 1.0, "lin", 0.01, 1.0, ""),
        action = function(x)
            if LFOs then
                LFOs.set("targeting", "depth", x)
            end
        end,
    })
    -- coordinates for modulation
    params:add({ type = "number", id = "y_axis", name = "y axis", min = 0, max = 63, default = 32 })
    params:add({ type = "number", id = "x_axis", name = "x axis", min = 0, max = 127, default = 64 })
end

function Params.starfield()
    params:add_group("starfield", 4)
    params:add({
        type = "number",
        id = "star_density",
        name = "constellation density",
        min = 1,
        max = 100,
        default = 15,
        formatter = function(param)
            local val = param:get()
            local effective = math.floor((val / 100) ^ 2 * 100)
            return val .. " (" .. effective .. "%)"
        end
    })
    params:add({ type = "number", id = "star_size", name = "star magnitude", min = 1, max = 100, default = 50 })
    params:add({
        type = "control",
        id = "star_movement",
        name = "drift velocity",
        controlspec = controlspec.new(0.1, 2.0,
            "lin", 0.1, 1.0, "x"),
        default = 1.0
    })
    params:add({
        type = "control",
        id = "star_twinkle",
        name = "luminosity flux",
        controlspec = controlspec.new(0.0,
            1.0, "lin", 0.1, 0.5, ""),
        default = 0.5
    })
end

function Params.synthesizer()
    params:add_group("internal synth", 6)
    params:add({
        type = "control",
        id = "amp",
        name = "amplitude",
        controlspec = controlspec.new(0, 1, "lin", 0, 0.7, ""),
        action = function(x)
            engine.amp(x)
        end,
    })
    params:add({
        type = "control",
        id = "release",
        name = "release",
        controlspec = controlspec.new(0.1, 3.2, "lin", 0, 2.0, "s"),
        action = function(x)
            engine.release(x)
        end,
    })
    params:add({
        type = "control",
        id = "cutoff",
        name = "cutoff",
        controlspec = controlspec.new(50, 5000, "exp", 0, 800, "hz"),
        action = function(x)
            engine.cutoff(x)
        end,
    })
    params:add({
        type = "control",
        id = "pulsewidth",
        name = "pulsewidth",
        controlspec = controlspec.new(0, 100, "lin", 0, 50, "%"),
        action = function(x)
            engine.pw(x / 100)
        end,
    })
    params:add({
        type = "control",
        id = "gain",
        name = "gain",
        controlspec = controlspec.new(0, 4, "lin", 0, 1, ""),
        action = function(x)
            engine.gain(x)
        end,
    })
    params:add({
        type = "control",
        id = "pan",
        name = "pan",
        controlspec = controlspec.new(-1, 1, "lin", 0, 0, ""),
        action = function(x)
            engine.pan(x)
        end,
    })
end

function Params.sequencer()
    params:add_group("temporal", 9)
    params:add({
        type = "trigger",
        id = "reset",
        name = "reset",
        action = Actions.reset,
    })
    params:add({
        type = "option",
        id = "sequencer_mode",
        name = "mode",
        options = { "beat-sync", "time-sync" },
        default = 1,
    })

    params:add({
        type = "option",
        id = "clock_div",
        name = "clock division",
        options = DIVISION_NAMES,
        default = 6, -- Default to 1/4 (quarter notes)
        action = function(value)
            Actions.update_division(DIVISION_VALUES[value])
        end
    })
    params:add({
        type = "control",
        id = "swing",
        name = "swing",
        controlspec = controlspec.new(0, 100, "lin", 1, 50, "%"),
        action = function(value)
            Actions.update_swing(value)
        end
    })
    params:add({
        type = "option",
        id = "note_length",
        name = "note length",
        options = { "25%", "50%", "75%", "100%" },
        default = 4,
    })
    params:add({ type = "number", id = "min_size", name = "min sequence", min = 1, max = 127, default = 1 })
    params:add({
        type = "number",
        id = "max_size",
        name = "max sequence",
        min = 1,
        max = 1500,
        default = 8,
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
        name = "collision logic",
        options = { "low to high", "random", "none" },
        default = 1,
    })
    params:add({ type = "number", id = "probability", name = "probability", min = 0, max = 100, default = 100 })
end

function Params.musical()
    params:add_group("harmonic", 2)
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
        default = 48,
        formatter = function(param)
            return Mu.note_num_to_name(param:get(), true)
        end,
        action = Seq.build_scale,
    })
end

function Params.io()
    params:add_group("i/o", 5)
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
end

function Params.build()
    params:add_separator("constellations")
    Params.io()
    Params.sequencer()
    Params.musical()
    Params.synthesizer()
    Params.starfield()
    Params.navigation()
end

return Params
