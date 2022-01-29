local Mu = require 'musicutil'
local Util = require 'util'

seq = {}

seq.LOCKED = true
seq.PLAY = false
seq.CLEAR = false
seq.scale_names = {}
seq.scale = {}
seq.active_notes = {}
seq.notes = {}
seq.release = {}
seq.amp = {}
seq.ix = 1
seq.toggle_lock = function() seq.LOCKED = not seq.LOCKED end
seq.add_note = function (n,i) seq.notes[i] = n end
seq.add_release = function (r,i) seq.release[i] = r end
seq.add_amp = function (p,i) seq.amp[i] = p end
seq.clear_all = function() seq.notes = {}; seq.release = {}; seq.amp = {}; seq.ix = 1; seq.CLEAR = true end
seq.increment = function() seq.ix = seq.ix % #seq.notes + 1 end
seq.start = function() seq.PLAY = true end
seq.stop = function() seq.PLAY = false end
seq.reset = function() seq.ix = 1 end
seq.get_note = function() return seq.scale[seq.notes[seq.ix]] end
seq.get_release = function() return Util.linlin(1,7,0.1,params:get("release"),seq.release[seq.ix]) end
seq.get_release_crow = function() return Util.linlin(1,7,-5,5,seq.release[seq.ix]) end
seq.get_amp = function() return Util.linlin(1,15,0,params:get("amp"),seq.amp[seq.ix]) end
seq.get_amp_crow = function() Util.linlin(1,15,0,5,seq.amp[seq.ix]) end
seq.get_size = function () return #seq.notes end
seq.build_scale = function()
  seq.scale = Mu.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), 32)
  local num_to_add = 32 - #seq.scale
  for i = 1, num_to_add do
    table.insert(seq.scale, seq.scale[32 - num_to_add])
  end
end

return seq
