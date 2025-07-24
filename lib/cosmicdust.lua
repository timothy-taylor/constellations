CosmicDust = {}

local particles = {}
local max_particles = 40
local time_offset = 0
local milky_way = {}

function CosmicDust.build()
    local band_angle = -0.3 + math.random() * 0.6
    local band_height_offset = math.random() * 20 - 10
    local band_curvature = math.random() * 0.02 - 0.01
    local global_flow_phase = math.random() * math.pi * 2

    for i = 1, max_particles do
        particles[i] = {
            x = math.random(0, 128),
            y = math.random(0, 64),
            speed = 0.05 + math.random() * 0.15,
            phase = math.random() * math.pi * 2,
            wave_amplitude = 2 + math.random() * 3,
            wave_frequency = 0.02 + math.random() * 0.03,
            brightness = math.random(1, 3),
            size_phase = math.random() * math.pi * 2,
            layer = i <= max_particles / 2 and 1 or 2
        }
    end

    for i = 1, 150 do
        local base_x = (i - 1) * 128 / 150

        local linear_y = 32 + (base_x / 128) * band_angle * 40
        local curved_y = linear_y + math.sin(base_x / 128 * math.pi) * band_curvature * 20
        local base_y = curved_y + band_height_offset

        milky_way[i] = {
            base_x = base_x,
            base_y = base_y,
            offset_phase = math.random() * math.pi * 2 + global_flow_phase,
            density_phase = math.random() * math.pi * 2 + global_flow_phase,
            flow_speed = 0.3 + math.random() * 0.2
        }
    end
end

function CosmicDust.update()
    time_offset = time_offset + 0.003

    for i = 1, #particles do
        local p = particles[i]

        -- different speeds per layer
        p.x = p.x + p.speed * (p.layer == 1 and 0.5 or 1.0)
        if p.x > 130 then
            p.x = -2
            p.y = math.random(0, 64)
        end

        local wave_offset = math.sin(p.phase + time_offset * p.wave_frequency + p.x * 0.02) * p.wave_amplitude
        p.y_draw = p.y + wave_offset

        p.current_brightness = p.brightness + math.sin(time_offset * 0.5 + p.phase) * 0.5
    end
end

function CosmicDust.draw()
    screen.level(1)
    for i = 1, #milky_way do
        local mw = milky_way[i]

        -- vertical
        local flow_y = math.sin(time_offset * mw.flow_speed + mw.offset_phase) * 2
        local center_y = mw.base_y + flow_y

        -- variation
        local density = math.sin(time_offset * 0.03 + mw.density_phase) * 0.3 + 0.7
        local thickness = 6 + density * 3

        local horizontal_fade = math.sin((mw.base_x / 128) * math.pi) * 0.8 + 0.2
        local pixels_to_draw = math.floor(2 + density * 3 * horizontal_fade)

        for j = 1, pixels_to_draw do
            local seed_factor = (i * 31 + j * 17) * 0.001 + time_offset * 0.1

            local y_spread = thickness * horizontal_fade
            local y_offset = math.sin(seed_factor * 13.7) * y_spread * 0.5
            local draw_y = center_y + y_offset + math.sin(time_offset * 0.05 + mw.offset_phase + j) * 0.8

            if draw_y >= 0 and draw_y <= 64 and mw.base_x >= 0 and mw.base_x <= 128 then
                screen.pixel(math.floor(mw.base_x), math.floor(draw_y))
            end
        end
    end
    screen.fill()

    for i = 1, #particles do
        local p = particles[i]

        if p.y_draw and p.y_draw >= 0 and p.y_draw <= 64 then
            local level = p.layer == 1 and
                math.max(1, math.floor(p.current_brightness * 0.5)) or
                math.max(1, math.floor(p.current_brightness))

            screen.level(level)

            if p.layer == 1 then
                -- background layer
                screen.pixel(math.floor(p.x), math.floor(p.y_draw))
            else
                -- foreground layer
                if i % 3 == 0 then
                    screen.circle(math.floor(p.x), math.floor(p.y_draw), 0.5)
                else
                    screen.pixel(math.floor(p.x), math.floor(p.y_draw))
                end
            end
            screen.fill()
        end
    end
end

return CosmicDust
