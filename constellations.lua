-- constellations; version 1.0.0
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
-- ALT + KEY2 + KEY3 == switch sync mode
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
local KEY2_DOWN = false
local KEY3_DOWN = false

local function switch_sync_mode()
    State.mode_transition_active = true

    local current_mode = params:get("sequencer_mode")
    local new_mode = current_mode == 1 and 2 or 1

    Actions.stop()
    local current_position = Seq.position

    -- if switching from time-sync to beat-sync, quantize the next start
    if current_mode == 2 and new_mode == 1 then
        clock.run(function()
            -- wait for next beat for smooth transition
            clock.sync(1)
            params:set("sequencer_mode", new_mode)

            -- restore sequence position
            Seq.position = current_position

            -- restart with new mode
            Actions.start()
            State.mode_transition_active = false
        end)
    else
        -- switch immediately for beat-sync to time-sync
        clock.run(function()
            clock.sleep(0.05)
            params:set("sequencer_mode", new_mode)
            Seq.position = current_position
            Actions.start()
            State.mode_transition_active = false
        end)
    end
end

function redraw()
    screen.clear()

    CosmicDust.draw()
    Gui.stars()
    Gui.cursor()
    Gui.seq_size()
    Gui.clock()

    if ALT then Gui.alt() end
    screen.update()
end

function key(n, z)
    if z == 1 then
        if n == 1 then
            ALT = true
        elseif n == 2 then
            KEY2_DOWN = true
            if ALT and KEY3_DOWN and not State.mode_transition_active then
                switch_sync_mode()
            elseif ALT and not KEY3_DOWN then
                Seq.shift()
            elseif not ALT and not KEY3_DOWN then
                Seq.clear_all()
            end
        elseif n == 3 then
            KEY3_DOWN = true
            if ALT and KEY2_DOWN and not State.mode_transition_active then
                switch_sync_mode()
            elseif ALT and not KEY2_DOWN then
                Seq.pop()
            elseif not ALT and not KEY2_DOWN then
                Seq.toggle_lock()
            end
        end
    else
        if n == 1 then
            ALT = false
        elseif n == 2 then
            KEY2_DOWN = false
        elseif n == 3 then
            KEY3_DOWN = false
        end
    end
end

function enc(n, d)
    if n == 1 and ALT then
        params:delta("probability", d)
    elseif n == 1 then
        params:delta("clock_div", d)
    elseif n == 2 and ALT then
        params:delta("star_density", d)
    elseif n == 2 then
        params:delta("y_axis", d)
    elseif n == 3 and ALT then
        params:delta("crosshair_size", d)
    elseif n == 3 then
        params:delta("x_axis", d)
    end
end

function cleanup()
    Actions.stop()

    if Actions.lattice then Actions.lattice:destroy() end
    if Actions.time_sync_clock then clock.cancel(Actions.time_sync_clock) end
end

function init()
    math.randomseed(Util.time())
    norns.enc.sens(2, 2)
    norns.enc.sens(3, 2)

    Midi_util.build_midi_device_list()
    Seq.build_scale_list()
    Params.build()
    LFOs.build()
    Seq.build_scale()
    CosmicDust.build()

    Midi_util.device = midi.connect()
    Midi_util.attach_event()

    local frame_count = 0
    local animate = metro.init()
    animate.time = 1 / 30
    animate.event = function()
        frame_count = frame_count + 1

        if frame_count % 2 == 0 then
            local density = params:get("star_density")
            local scaled_density = (density / 100) ^ 2 * 100

            if math.random(100) <= scaled_density then
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
        end

        Stars.iterate(Seq)
        CosmicDust.update()
        redraw()
    end

    animate:start()
    Notes_off = metro.init()
    Notes_off.event = Midi_util.all_notes_off

    Actions.init()
    LFOs.start()
end
