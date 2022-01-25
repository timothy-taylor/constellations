Star = { 
  note = 0, 
  brightness = 1,
  size = 1,
  x = 1, 
  y = 1, 
  tagged = false,
  id = nil
}

function Star:new (
    o,
    note,
    brightness,
    size,
    x,
    y,
    tracked,
    playing,
    id
)
  o = o or {}
  setmetatable(o,self)
  self.__index = self
  self.note = note or 0
  self.brightness = brightness or 1
  self.size = size or 1
  self.x = x or 1
  self.y = y or 1
  self.tagged = tagged or false
  self.id = id or nil
  return o
end

return Star
