local Mu = require 'musicutil'
local Util = require 'util'

seq = {}

seq.LOCKED = true
seq.CLEAR = false
seq.scale_names = {}
seq.scale = {}
seq.notes = {}
seq.release = {}
seq.amp = {}
seq.ix = 1
seq.overwrite_ix = 0

function seq.get_overwrite_ix(i)
 local ix = i
  if i > params:get("max_size") then
    ix = seq.overwrite_ix
  end
  return ix
end

function seq.add_release(r,i)
  local ix = seq.get_overwrite_ix(i)
  seq.release[ix] = r 
end

function seq.add_amp(p,i)
  local ix = seq.get_overwrite_ix(i)
  seq.amp[ix] = p 
end

function seq.add_note(n,i)
  local ix = seq.get_overwrite_ix(i)
  --print('i:'..i..' / ix:'..ix)
  seq.notes[ix] = n 
end

function seq.pop() 
  table.remove(seq.notes)
  table.remove(seq.release)
  table.remove(seq.amp)
end

function seq.shift()
  table.remove(seq.notes,1)
  table.remove(seq.release,1)
  table.remove(seq.amp,1)
end

function seq.set_overwrite_ix(y)
  if params:get("overwrite_logic") == 1 then
    seq.overwrite_ix = math.ceil(Util.linlin(1,64,1,#seq.notes,64-y))
  elseif params:get("overwrite_logic") == 2 then
    seq.overwrite_ix = math.floor(
      math.random(1,#seq.notes > 1 and #seq.notes or 2)
      )
  end
end

function seq.increment() seq.ix = seq.ix % #seq.notes + 1 end
function seq.toggle_lock() seq.LOCKED = not seq.LOCKED end
function seq.reset() seq.ix = 1 end

function seq.get_note() 
  return seq.scale[seq.notes[seq.ix]] 
end

function seq.get_release() 
  return Util.linlin(1,7,0.1,params:get("release"),seq.release[seq.ix]) 
end

function seq.get_release_crow() 
  return Util.linlin(1,7,-5,5,seq.release[seq.ix]) 
end

function seq.get_amp() 
  return Util.linlin(1,15,0,params:get("amp"),seq.amp[seq.ix]) 
end

function seq.get_amp_crow() 
  return Util.linlin(1,15,0,5,seq.amp[seq.ix]) 
end

function seq.get_size() 
  return #seq.notes 
end

function seq.clear_all() 
  seq.notes = {} 
  seq.release = {} 
  seq.amp = {}
  seq.ix = 1
  seq.CLEAR = true 
end

function seq.build_scale()
  seq.scale = Mu.generate_scale_of_length(
    params:get("root_note"), 
    params:get("scale_mode"), 
    32
  )
  local num_to_add = 32 - #seq.scale
  for i = 1, num_to_add do
    table.insert(seq.scale, seq.scale[32 - num_to_add])
  end
end

function seq.build_scale_list()
 for i = 1, #Mu.SCALES do
    table.insert(seq.scale_names, string.lower(Mu.SCALES[i].name))
  end   
end

return seq
