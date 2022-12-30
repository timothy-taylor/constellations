Stars = {}

Stars.data = {}

Stars.get_number = function()
	return #Stars.data
end

Stars.iterate = function(seq)
	local s = Stars.data
	for i = 1, #s do
		if s[i] then
			Stars.update_coordinate(s[i])
			Stars.tag(s[i], i, seq)
			Stars.delete(s[i], i)
			Stars.update_brightness(s[i])
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

			if not seq.PLAY then
				Actions.start()
			end
			if seq.CLEAR then
				seq.CLEAR = false
			end
		else
			if seq.CLEAR then
				star.TAGGED = false
			end
		end
	end
end

Stars.add = function(star)
	table.insert(Stars.data, star)
end

Stars.delete = function(star, i)
	if star.x - star.size > 128 then
		table.remove(Stars.data, i)
		star = nil
	end
end

Stars.update_coordinate = function(star)
	star.x = star.x + 1
end

do
	local i = 0
	Stars.update_brightness = function(star)
		i = i + 1
		if i % 8 == 0 then
			i = 0
			local walk = math.random() >= 0.5 and 2 or -2
			star.brightness = Util.clamp(star.brightness + walk, 1, 15)
		end
	end
end

return Stars
