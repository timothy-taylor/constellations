Gui = {}

local sn = screen

function Gui.stars()
	local n = Stars.get_number()
	if n > 0 then
		local lastX
		local lastY
		for i = 1, n do
			local s = Stars.data[i]
			if s then
				-- draw the star
				sn.level(s.brightness)
				sn.circle(s.x, s.y, s.size)
				sn.fill()
				if s.TAGGED and not Seq.CLEAR then
					-- draw the TAGGED box
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
	sn.level(1)
	for j = 1, params:get("crosshair_size") do
		local x = params:get("x_axis")
		local y = params:get("y_axis")
		sn.pixel(x, y)
		sn.pixel(x + j, y)
		sn.pixel(x - j, y)
		if params:get("targeting") == 2 then
			sn.pixel(x, y + j)
		end
		if params:get("targeting") == 2 then
			sn.pixel(x, y - j)
		end
	end
	sn.fill()
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
	sn.text_right("" .. params:get("step_div"))
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
	sn.level(15)
	sn.font_face(1)
	sn.font_size(8)
	sn.move(44, 62)
	sn.text("density")
	sn.move(64, 53)
	sn.text(params:get("density"))
	sn.move(103, 62)
	sn.text("size")
	sn.move(103, 53)
	sn.text(params:get("size"))
	sn.move(74, 6)
	sn.text("probability")
	sn.move(74, 15)
	sn.text(params:get("probability"))
	sn.stroke()
end

return Gui
