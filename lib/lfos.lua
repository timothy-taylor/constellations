LFOs = {}

LFOs.data = {}

function LFOs.build()
    local targeting = {
        name = "targeting",
        lfo = Lfo:add({
            shape = "sine",
            min = 0,
            max = 63,
            depth = 1.0,
            mode = "free",
            period = 8,
            action = function(scaled)
                if params:get("autopilot") == 2 then
                    params:set("y_axis", math.floor(scaled + 0.5))
                end
            end,
        }),
    }

    table.insert(LFOs.data, targeting)
end

function LFOs.is_empty()
    return #LFOs.data == 0
end

function LFOs.set(name, param, val)
    if LFOs.is_empty() then return end

    for _, v in ipairs(LFOs.data) do
        if name == nil then
            v.lfo:set(param, val)
        end

        if v.name == name then
            v.lfo:set(param, val)
        end
    end
end

function LFOs.start(name)
    if LFOs.is_empty() then return end

    for _, v in ipairs(LFOs.data) do
        if name == nil then
            v.lfo:start()
        end

        if v.name == name then
            v.lfo:start()
        end
    end
end

function LFOs.stop(name)
    if LFOs.is_empty() then
        return
    end

    for _, v in ipairs(LFOs.data) do
        if name == nil then
            v.lfo:stop()
        end

        if v.name == name then
            v.lfo:stop()
        end
    end
end

return LFOs
