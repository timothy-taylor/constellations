local Util = require 'util'

stars = {}
stars.data = {}
stars.get_number = function() return #stars.data end
stars.iterate = function(seq,crosshair)
  local s = stars.data
  for i=1,#s do
    if s[i] then
      stars.update_coordinate(s[i])
      stars.tag(s[i],i,seq,crosshair)
      stars.delete(s[i],i)
      stars.update_brightness(s[i]) 
    end
  end
end

stars.tag = function(star,i,seq,crosshair)
  local x = crosshair.x
  local y = crosshair.y
  local size_cross = crosshair.size
  local size_star = star.size
  if not star.TAGGED and not seq.LOCKED then
    if (star.x - size_star - size_cross <= x) and (x <= star.x + size_star + size_cross)
    and (star.y - size_star - size_cross <= y) and (y <= star.y + size_star + size_cross)
    then
      local id = seq.get_size() + 1;
      star.TAGGED = true
      star.id = id
      seq.add_note(star.note,id)
      if not seq.PLAY then start() end
      if seq.CLEAR then seq.CLEAR = false end
    else
      if seq.CLEAR then star.TAGGED = false end
    end
  end
end

stars.add = function(star)
  table.insert(stars.data,star)
end

stars.delete = function(star,i)
  if star.x - star.size > 128 then
    table.remove(stars.data,i)
    star = nil
  end
end

stars.update_coordinate = function(star)
  star.x = star.x + 1 
end

do
  local i = 0;
    stars.update_brightness = function(star)
      i = i + 1
      if i % 8 == 0 then
        i = 0
        local walk = math.random() >= 0.5 and 2 or -2
        star.brightness = Util.clamp(star.brightness + walk, 1,15)    
      end
    end
end

return stars