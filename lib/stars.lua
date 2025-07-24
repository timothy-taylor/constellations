Stars = {}
Stars.data = {}
Stars.get_number = function() return #Stars.data end
Stars.add = function(star) table.insert(Stars.data, star) end

Stars.iterate = function(seq)
    local s = Stars.data
    local i = 1
    while i <= #s do
        local star = s[i]
        if star then
            Stars.update_coordinate(star)
            Stars.tag(star, i, seq)

            if star.x - star.size > 128 then
                StarFactory.return_to_pool(star)
                table.remove(s, i)
            else
                Stars.update_brightness(star)
                i = i + 1
            end
        else
            i = i + 1
        end
    end
end

Stars.tag = function(star, _, seq)
    local x = params:get("x_axis")
    local y = params:get("y_axis")
    local size_cross = params:get("crosshair_size")
    local size_star = star.size

    if not star.TAGGED and params:get("targeting") == 2 then
        if
            (star.x - size_star - size_cross <= x)
            and (x <= star.x + size_star + size_cross)
            and (star.y - size_star - size_cross <= y)
            and (y <= star.y + size_star + size_cross)
        then
            local id = seq.get_size() + 1
            star.TAGGED = true
            star.id = id

            if params:get("overwrite_logic") == 3 and seq.is_full() then
                seq.toggle_lock()
            else
                seq.set_overwrite_ix(y)
                seq.add_note(star.note, id)
                seq.add_release(star.size, id)
                seq.add_amp(star.brightness, id)
                seq.add_time(Util.time(), id)
            end

            if not seq.PLAY then Actions.start() end
            if seq.CLEAR then seq.CLEAR = false end
        else
            if seq.CLEAR then star.TAGGED = false end
        end
    end
end

Stars.update_coordinate = function(star)
    if not star.velocity then
        local base_speed = 0.15 + math.random() * 0.2
        star.velocity = base_speed * (params:get("star_movement") or 1.0) * star.depth
    end

    if not star.wobble then
        star.wobble = {
            amplitude = math.random() * 0.3 * star.depth,
            frequency = 0.01 + math.random() * 0.02,
            phase = math.random() * math.pi * 2,
            base_y = star.y
        }
    end

    star.x = star.x + star.velocity

    if not star.TAGGED then
        star.wobble.phase = star.wobble.phase + star.wobble.frequency
        star.y = star.wobble.base_y + math.sin(star.wobble.phase) * star.wobble.amplitude
    end
end

Stars.update_brightness = function(star)
    if not star.brightness_anim then
        local twinkle_intensity = params:get("star_twinkle") or 0.5
        star.brightness_anim = {
            base = star.brightness,
            phase = math.random() * math.pi * 2,
            frequency = 0.02 + math.random() * 0.03,
            amplitude = (1 + math.random() * 2) * twinkle_intensity,
            last_update = 0
        }
    end

    local anim = star.brightness_anim
    anim.phase = anim.phase + anim.frequency
    anim.last_update = anim.last_update + 1

    if anim.last_update >= 3 then
        anim.last_update = 0
        local brightness_offset = math.sin(anim.phase) * anim.amplitude
        local new_brightness = anim.base + brightness_offset + 0.5
        star.brightness = new_brightness < 1 and 1 or (new_brightness > 15 and 15 or math.floor(new_brightness))
    end
end

return Stars
