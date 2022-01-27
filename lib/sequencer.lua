local Mu = require 'musicutil'

seq = {}

seq.LOCKED = true
seq.PLAY = false
seq.CLEAR = false
seq.scale_names = {}
seq.scale = {}
seq.active_notes = {}
seq.notes = {}
seq.ix = 1
seq.toggle_lock = function() seq.LOCKED = not seq.LOCKED end
seq.add_note = function (note,i) seq.notes[i] = note end
seq.clear_notes = function() seq.notes = {}; seq.ix = 1; seq.CLEAR = true end
seq.increment = function() seq.ix = seq.ix % #seq.notes + 1 end
seq.start = function() seq.PLAY = true end
seq.stop = function() seq.PLAY = false end
seq.reset = function() seq.ix = 1 end
seq.get_note = function() return seq.scale[seq.notes[seq.ix]] end
seq.get_size = function () return #seq.notes end
seq.build_scale = function()
  seq.scale = Mu.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 32)
  local num_to_add = 32 - #seq.scale
  for i = 1, num_to_add do
    table.insert(seq.scale, seq.scale[32 - num_to_add])
  end
end

return seq
