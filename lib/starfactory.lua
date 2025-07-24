StarFactory = {
    note = 0,
    brightness = 1,
    size = 1,
    x = -10,
    y = 1,
    TAGGED = false,
    id = nil,
    has_glow = false,
    has_bright_center = false,
}

StarFactory.__index = StarFactory

local star_pool = {}
local pool_size = 0

local function get_pooled_star()
    if pool_size > 0 then
        local star = star_pool[pool_size]
        star_pool[pool_size] = nil
        pool_size = pool_size - 1
        return star
    end
    return {}
end

function StarFactory:new(o, note, brightness, size, x, y, TAGGED, id)
    o = o or get_pooled_star()
    setmetatable(o, self)

    o.note = note or 0
    o.brightness = brightness or 1
    o.size = size or 1
    o.x = x or -10
    o.y = y or 1
    o.TAGGED = TAGGED or false
    o.id = id or nil
    o.has_glow = math.random() < 0.5
    o.has_bright_center = math.random() < 0.05
    o.depth = 0.3 + math.random() * 1.7
    return o
end

StarFactory.return_to_pool = function(star)
    if pool_size < 50 then
        star.note = 0
        star.brightness = 1
        star.size = 1
        star.x = -10
        star.y = 1
        star.TAGGED = false
        star.id = nil
        star.has_glow = false
        star.has_bright_center = false
        star.depth = nil
        star.velocity = nil
        star.wobble = nil
        star.brightness_anim = nil

        pool_size = pool_size + 1
        star_pool[pool_size] = star
    end
end

return StarFactory
