midi_util = {}

midi_util.device = 1
midi_util.channel = 1
midi_util.devices = {}
midi_util.active_notes = {}
midi_util.PLAY = false;
midi_util.start = function() midi_util.PLAY = true end
midi_util.stop = function() midi_util.PLAY = false end

midi_util.build_midi_device_list = function()
  midi_util.devices = {}
  for i = 1,#midi.vports do
    local long_name = midi.vports[i].name
    local short_name = string.len(long_name) > 15 and util.acronym(long_name) or long_name
    table.insert(midi_util.devices,i..": "..short_name)
  end
end

midi_util.all_notes_off = function()
  if (params:get("output") == 2 or params:get("output") == 3) then
    for _, a in pairs(midi_util.active_notes) do
      midi_util.device:note_off(a, nil, midi_util.channel)
    end
  end
  midi_util.active_notes = {}
end

midi_util.event = function(data)
  msg = midi.to_msg(data)
  if msg.type == "start" then
    clock.transport.reset()
    clock.transport.start()
  elseif msg.type == "continue" then
    if midi_util.PLAY then 
      clock.transport.stop()
    else 
      clock.transport.start()
    end
  end 
  if msg.type == "stop" then
    clock.transport.stop()
  end 
end

midi_util.attach_event = function()
  midi_util.device.event = midi_util.event
end

return midi_util
