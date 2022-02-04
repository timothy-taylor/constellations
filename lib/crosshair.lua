local Util = require 'util'

crosshair = {}

crosshair.size = 3
crosshair.x = 64
crosshair.y = 32

function crosshair.set_y_midi(x)
  crosshair.y = Util.linlin(0,127,0,63,x)
end

function crosshair.set_xy_crow(v)
  -- 0 to 5 volts == controls Y
  if v >= 0 then
    crosshair.y = Util.linlin(0,5,0,63,v)
  end
end

return crosshair;
