Crosshair = {}

function Crosshair.set_xy_crow(v)
  -- 0 to 5 volts == controls Y
  if v >= 0 and params:get("crow_input") == 2 then
    params:set("y_axis", Util.linlin(0,5,0,63,v))
  end
end

return Crosshair;
