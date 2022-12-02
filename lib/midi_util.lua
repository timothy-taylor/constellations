Midi_util = {}

function clock.transport.start()
	Actions.start()
end
function clock.transport.stop()
	Actions.stop()
end
function clock.transport.reset()
	Actions.reset()
end

Midi_util.device = 1
Midi_util.channel = 1
Midi_util.devices = {}

Midi_util.active_notes = {}
Midi_util.PLAY = false;
Midi_util.start = function() Midi_util.PLAY = true end
Midi_util.stop = function() Midi_util.PLAY = false end

Midi_util.build_midi_device_list = function()
  Midi_util.devices = {}
  for i = 1,#midi.vports do
    local long_name = midi.vports[i].name
    local short_name = string.len(long_name) > 15 and Util.acronym(long_name) or long_name
    table.insert(Midi_util.devices,i..": "..short_name)
  end
end

Midi_util.all_notes_off = function()
  if (params:get("output") == 2 or params:get("output") == 3) then
    for _, a in pairs(Midi_util.active_notes) do
      Midi_util.device:note_off(a, nil, Midi_util.channel)
    end
  end
  Midi_util.active_notes = {}
end

Midi_util.event = function(data)
  local msg = midi.to_msg(data)
  if msg.type == "start" then
    clock.transport.reset()
    clock.transport.start()
  elseif msg.type == "continue" then
    if Midi_util.PLAY then
      clock.transport.stop()
    else
      clock.transport.start()
    end
  end
  if msg.type == "stop" then
    clock.transport.stop()
  end
end

Midi_util.attach_event = function()
  Midi_util.device.event = Midi_util.event
end

return Midi_util
