Gui = {}

local sn = screen

local teleport_effect = {
    active = false,
    start_time = 0,
    duration = 0.3,
    start_x = 0,
    start_y = 0,
    end_x = 0,
    end_y = 0,
    last_y = 32
}

local rocket_cache = {
    flame_frame = 0,
    last_time_check = 0,
    force_field_angles = {}
}

for i = 1, 8 do
    rocket_cache.force_field_angles[i] = (i - 1) / 8 * math.pi * 2
end


local teleport_angles = {}
for i = 1, 20 do
    teleport_angles[i] = (i - 1) / 20 * math.pi * 2
end
local teleport_mat_angles = {}
for i = 1, 10 do
    teleport_mat_angles[i] = (i - 1) / 10 * math.pi * 2
end

function Gui.stars()
    local n = Stars.get_number()
    if n > 0 then
        local lastX
        local lastY
        for i = 1, n do
            local s = Stars.data[i]
            if s then
                if s.has_glow and s.size >= 2 then
                    sn.level(math.max(1, math.floor(s.brightness * 0.3)))
                    sn.circle(s.x, s.y, s.size + 1)
                    sn.fill()
                end

                sn.level(s.brightness)
                sn.circle(s.x, s.y, s.size)
                sn.fill()

                if s.has_bright_center and s.size >= 2 then
                    sn.level(math.min(15, s.brightness + 2))
                    sn.pixel(s.x, s.y)
                    sn.fill()
                end

                if s.TAGGED and not Seq.CLEAR then
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
end

function Gui.crosshair()
    local x = params:get("x_axis")
    local y = params:get("y_axis")
    local size = params:get("crosshair_size")
    local targeting_on = params:get("targeting") == 2

    sn.level(1)

    -- horizontal line
    for j = 0, size do
        if j > 0 then
            sn.pixel(x + j, y)
            sn.pixel(x - j, y)
        end
    end

    -- draw vertical line if targeting is on
    if targeting_on then
        for j = 0, size do
            if j > 0 then
                sn.pixel(x, y + j)
                sn.pixel(x, y - j)
            end
        end
    end

    sn.pixel(x, y)
    sn.fill()
end

function Gui.rocket()
    local x = params:get("x_axis")
    local y = params:get("y_axis")
    local cursor_size = params:get("crosshair_size")
    local targeting_on = params:get("targeting") == 2

    local current_time = Util.time()
    if current_time - rocket_cache.last_time_check > 0.1 then
        rocket_cache.flame_frame = math.floor(current_time * 10) % 3
        rocket_cache.last_time_check = current_time
    end
    if targeting_on and cursor_size >= 15 then
        local pulse = math.sin(current_time * 4) * 0.3 + 0.7
        local pulse_2 = math.floor(pulse * 2)
        local pulse_4 = math.floor(pulse * 4)
        local pulse_6 = math.floor(pulse * 6)

        -- outer glow
        sn.level(pulse_2)
        sn.circle(x + 4, y, cursor_size + 2)
        sn.stroke()

        -- main force field boundary
        sn.level(pulse_4)
        sn.circle(x + 4, y, cursor_size)
        sn.stroke()

        sn.level(pulse_6)
        local radius = cursor_size * 0.7
        local time_offset = current_time * 2
        for i = 1, 8 do
            local angle = rocket_cache.force_field_angles[i] + time_offset
            local px = x + 4 + math.cos(angle) * radius
            local py = y + math.sin(angle) * radius
            sn.pixel(px, py)
        end
        sn.fill()
    end

    sn.level(15)
    for i = -2, 5 do
        sn.pixel(x + i, y - 2)
        sn.pixel(x + i, y - 1)
        sn.pixel(x + i, y)
        sn.pixel(x + i, y + 1)
        sn.pixel(x + i, y + 2)
    end

    sn.pixel(x - 3, y - 1)
    sn.pixel(x - 3, y)
    sn.pixel(x - 3, y + 1)
    sn.pixel(x - 4, y - 1)
    sn.pixel(x - 4, y)
    sn.pixel(x - 4, y + 1)
    sn.pixel(x - 5, y)
    sn.pixel(x - 6, y)

    sn.level(5)
    sn.pixel(x - 2, y - 1)
    sn.pixel(x - 2, y)
    sn.pixel(x - 3, y)

    sn.level(15)
    for i = 0, 4 do
        sn.pixel(x + i, y - 3)
        sn.pixel(x + i, y + 3)
    end
    for i = 1, 3 do
        sn.pixel(x + i, y - 4)
        sn.pixel(x + i, y + 4)
    end
    sn.pixel(x + 2, y - 5)
    sn.pixel(x + 2, y + 5)

    sn.pixel(x + 6, y - 2)
    sn.pixel(x + 6, y - 3)
    sn.pixel(x + 6, y - 4)
    sn.pixel(x + 7, y - 3)
    sn.pixel(x + 7, y - 4)
    sn.pixel(x + 7, y - 5)
    sn.pixel(x + 8, y - 4)
    sn.pixel(x + 8, y - 5)

    sn.level(10)
    sn.pixel(x + 6, y - 1)
    sn.pixel(x + 6, y)
    sn.pixel(x + 6, y + 1)
    sn.pixel(x + 7, y - 1)
    sn.pixel(x + 7, y)
    sn.pixel(x + 7, y + 1)

    -- cockpit
    sn.level(8)
    sn.pixel(x, y - 1)
    sn.pixel(x + 1, y - 1)
    sn.pixel(x, y)
    sn.pixel(x + 1, y)

    local flame_frame = rocket_cache.flame_frame

    if targeting_on then
        sn.level(14)

        for i = 1, 8 do
            sn.pixel(x + 8 + i, y)
            sn.pixel(x + 8 + i, y - 1)
            sn.pixel(x + 8 + i, y + 1)
        end

        sn.level(12 - flame_frame)
        if flame_frame == 0 then
            for i = 1, 6 do
                sn.pixel(x + 9 + i, y - 2)
                sn.pixel(x + 9 + i, y + 2)
            end
            sn.pixel(x + 11, y - 3)
            sn.pixel(x + 11, y + 3)
            sn.pixel(x + 13, y - 3)
            sn.pixel(x + 13, y + 3)
        elseif flame_frame == 1 then
            for i = 1, 7 do
                sn.pixel(x + 10 + i, y - 2)
                sn.pixel(x + 10 + i, y + 2)
            end
            sn.pixel(x + 12, y - 3)
            sn.pixel(x + 12, y + 3)
            sn.pixel(x + 14, y - 4)
            sn.pixel(x + 14, y + 4)
        else
            for i = 1, 5 do
                sn.pixel(x + 9 + i, y - 3)
                sn.pixel(x + 9 + i, y + 3)
            end
            sn.pixel(x + 15, y - 2)
            sn.pixel(x + 15, y + 2)
            sn.pixel(x + 16, y - 1)
            sn.pixel(x + 16, y + 1)
            sn.pixel(x + 17, y)
        end
    else
        sn.level(10 + flame_frame * 2)

        if flame_frame == 0 then
            sn.pixel(x + 9, y)
            sn.pixel(x + 10, y)
            sn.pixel(x + 10, y - 1)
            sn.pixel(x + 10, y + 1)
            sn.pixel(x + 11, y - 1)
            sn.pixel(x + 11, y + 1)
        elseif flame_frame == 1 then
            sn.pixel(x + 9, y)
            sn.pixel(x + 9, y - 1)
            sn.pixel(x + 9, y + 1)
            sn.pixel(x + 10, y)
            sn.pixel(x + 11, y)
        else
            sn.pixel(x + 9, y - 1)
            sn.pixel(x + 9, y + 1)
            sn.pixel(x + 10, y)
            sn.pixel(x + 11, y - 1)
            sn.pixel(x + 11, y + 1)
        end
    end

    sn.fill()
end

function Gui.cursor()
    local x = params:get("x_axis")
    local y = params:get("y_axis")

    if params:get("autopilot") == 2 and params:get("autopilot_shape") == 2 then
        if y ~= teleport_effect.last_y then
            teleport_effect.active = true
            teleport_effect.start_time = Util.time()
            teleport_effect.start_x = x
            teleport_effect.start_y = teleport_effect.last_y
            teleport_effect.end_x = x
            teleport_effect.end_y = y
        end
        teleport_effect.last_y = y
    end

    if teleport_effect.active then
        local elapsed = Util.time() - teleport_effect.start_time
        local progress = elapsed / teleport_effect.duration

        if progress < 1 then
            -- quantum particles dispersing
            local brightness = math.floor((1 - progress) * 15)
            sn.level(brightness)
            local radius = progress * 15
            for i = 1, 20 do
                local angle = teleport_angles[i]
                local px = teleport_effect.start_x + math.cos(angle) * radius
                local py = teleport_effect.start_y + math.sin(angle) * radius
                sn.pixel(px, py)
            end
            sn.fill()

            -- energy rings
            sn.level(math.floor((1 - progress) * 10))
            sn.circle(teleport_effect.start_x, teleport_effect.start_y, progress * 20)
            sn.stroke()

            -- materializing particles at destination - reduced to 10
            if progress > 0.5 then
                local mat_progress = (progress - 0.5) * 2
                local mat_brightness = math.floor(mat_progress * 15)
                sn.level(mat_brightness)
                local mat_radius = (1 - mat_progress) * 12
                local angle_offset = progress * math.pi
                for i = 1, 10 do
                    local angle = teleport_mat_angles[i] + angle_offset
                    local px = teleport_effect.end_x + math.cos(angle) * mat_radius
                    local py = teleport_effect.end_y + math.sin(angle) * mat_radius
                    sn.pixel(px, py)
                end
                sn.fill()

                -- convergence ring
                sn.level(math.floor(mat_progress * 8))
                sn.circle(teleport_effect.end_x, teleport_effect.end_y, (1 - mat_progress) * 15)
                sn.stroke()
            end
        else
            teleport_effect.active = false
        end
    end

    if params:get("cursor_type") == 1 then
        Gui.crosshair()
    else
        Gui.rocket()
    end
end

function Gui.seq_size()
    sn.level(7)
    sn.move(0, 64)
    sn.text("" .. Seq.get_size())
    sn.fill()
end

function Gui.clock()
    sn.level(7)
    sn.move(124, 5)
    sn.text_right(DIVISION_NAMES[params:get("clock_div")])
    sn.fill()
end

function Gui.alt()
    sn.level(2)
    sn.rect(32, 0, 96, 68)
    sn.fill()
    sn.level(0)
    sn.font_face(3)
    sn.font_size(15)
    sn.move(36, 2 + 32)
    sn.text("constellations")
    sn.level(13)
    sn.font_face(1)
    sn.font_size(8)
    sn.move(44, 62)
    sn.text("density")
    sn.level(15)
    sn.move(64, 53)
    sn.text(params:get("star_density"))
    sn.level(13)
    sn.move(103, 62)
    sn.text("size")
    sn.level(15)
    sn.move(103, 53)
    sn.text(params:get("crosshair_size"))
    sn.level(13)
    sn.move(103, 6)
    sn.text("prob")
    sn.level(15)
    sn.move(105, 15)
    sn.text(params:get("probability"))

    sn.move(36, 15)
    local mode_text = params:string("sequencer_mode")
    if State.mode_transition_active then
        -- Blink during transition
        if math.floor(Util.time() * 6) % 2 == 0 then
            sn.text(mode_text)
        end
    else
        sn.text(mode_text)
    end

    sn.level(13)
    sn.move(36, 6)
    sn.font_size(8)
    sn.text("mode")

    sn.stroke()
    sn.font_face(1)
    sn.font_size(8)
    sn.level(15)
end

return Gui
