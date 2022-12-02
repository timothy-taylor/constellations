StarFactory = {
  note = 0,
  brightness = 1,
  size = 1,
  x = -10,
  y = 1,
  TAGGED = false,
  id = nil
}

function StarFactory:new (
    o,
    note,
    brightness,
    size,
    x,
    y,
    TAGGED,
    id
)
  o = o or {}
  setmetatable(o,self)
  self.__index = self
  self.note = note or 0
  self.brightness = brightness or 1
  self.size = size or 1
  self.x = x or -10
  self.y = y or 1
  self.TAGGED = TAGGED or false
  self.id = id or nil
  return o
end

return StarFactory
