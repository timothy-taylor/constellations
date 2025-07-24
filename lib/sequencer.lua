Seq = {}

Seq.CLEAR = false
Seq.scale_names = {}
Seq.scale = {}
Seq.notes = {}
Seq.release = {}
Seq.amp = {}
Seq.time = {}
Seq.ix = 1
Seq.overwrite_ix = 0

function Seq.get_overwrite_ix(i)
    local ix = i
    if i > params:get("max_size") then
        ix = Seq.overwrite_ix
    end
    return ix
end

function Seq.set_overwrite_ix(y)
    if params:get("overwrite_logic") == 1 then
        Seq.overwrite_ix = math.ceil(Util.linlin(1, 64, 1, #Seq.notes, 64 - y))
    elseif params:get("overwrite_logic") == 2 then
        Seq.overwrite_ix = math.floor(math.random(1, #Seq.notes > 1 and #Seq.notes or 2))
    end
end

function Seq.add_release(r, i)
    local ix = Seq.get_overwrite_ix(i)
    Seq.release[ix] = r
end

function Seq.add_amp(p, i)
    local ix = Seq.get_overwrite_ix(i)
    Seq.amp[ix] = p
end

function Seq.add_time(t, i)
    local ix = Seq.get_overwrite_ix(i)
    Seq.time[ix] = t
end

function Seq.add_note(n, i)
    local ix = Seq.get_overwrite_ix(i)
    Seq.notes[ix] = n
end

function Seq.pop()
    table.remove(Seq.notes)
    table.remove(Seq.release)
    table.remove(Seq.amp)
    table.remove(Seq.time)
end

function Seq.shift()
    table.remove(Seq.notes, 1)
    table.remove(Seq.release, 1)
    table.remove(Seq.amp, 1)
    table.remove(Seq.time, 1)
end

function Seq.get_size() return #Seq.notes end

function Seq.is_full() return #Seq.notes >= params:get("max_size") end

function Seq.reset() Seq.ix = 1 end

function Seq.increment() Seq.ix = Seq.ix % #Seq.notes + 1 end

function Seq.toggle_lock() params:set("targeting", params:get("targeting") % 2 + 1) end

function Seq.get_note() return Seq.scale[Seq.notes[Seq.ix]] end

function Seq.get_time()
    if Seq.get_size() < 1 then
        return 1 / 15
    end

    local ix = Seq.ix
    local prev_ix = (ix - 1 <= 1) and 1 or ix - 1
    local diff = Seq.time[ix] - Seq.time[prev_ix]
    return (diff <= 0) and 1 or diff
end

function Seq.get_release()
    return Util.linlin(1, 7, 0.1, params:get("release"), Seq.release[Seq.ix])
end

function Seq.get_release_crow()
    return Util.linlin(1, 7, -5, 5, Seq.release[Seq.ix])
end

function Seq.get_amp()
    return Util.linlin(1, 15, 0, params:get("amp"), Seq.amp[Seq.ix])
end

function Seq.get_amp_crow()
    return Util.linlin(1, 15, 0, 5, Seq.amp[Seq.ix])
end

function Seq.clear_all()
    Seq.notes = {}
    Seq.release = {}
    Seq.amp = {}
    Seq.time = {}
    Seq.ix = 1
    Seq.CLEAR = true
end

function Seq.build_scale()
    Seq.scale = Mu.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 32)
    local num_to_add = 32 - #Seq.scale
    for _ = 1, num_to_add do
        table.insert(Seq.scale, Seq.scale[32 - num_to_add])
    end
end

function Seq.build_scale_list()
    for i = 1, #Mu.SCALES do
        table.insert(Seq.scale_names, string.lower(Mu.SCALES[i].name))
    end
end

return Seq
