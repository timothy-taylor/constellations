midi_util = {}

midi_util.out_device = 1
midi_util.out_channel = 1
midi_util.out_devices = {}
midi_util.in_device = 1
midi_util.in_channel = 1
midi_util.in_devices = {}

midi_util.active_notes = {}
midi_util.PLAY = false;
midi_util.start = function() midi_util.PLAY = true end
midi_util.stop = function() midi_util.PLAY = false end

midi_util.build_midi_out_device_list = function()
  midi_util.out_devices = {}
  for i = 1,#midi.vports do
    local long_name = midi.vports[i].name
    local short_name = string.len(long_name) > 15 and util.acronym(long_name) or long_name
    table.insert(midi_util.out_devices,i..": "..short_name)
  end
end

midi_util.build_midi_in_device_list = function()
  midi_util.in_devices = {}
  for i = 1,#midi.vports do
    local long_name = midi.vports[i].name
    local short_name = string.len(long_name) > 15 and util.acronym(long_name) or long_name
    table.insert(midi_util.in_devices,i..": "..short_name)
  end
end

midi_util.all_notes_off = function()
  if (params:get("output") == 2 or params:get("output") == 3) then
    for _, a in pairs(midi_util.active_notes) do
      midi_util.out_device:note_off(a, nil, midi_util.out_channel)
    end
  end
  midi_util.active_notes = {}
end

-- this gets overriden in init()
midi_util.in_event = function(data) end
midi_util.out_event = function(data)
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

midi_util.attach_in_event = function()
  midi_util.in_device.event = midi_util.in_event
end

midi_util.attach_out_event = function()
  midi_util.out_device.event = midi_util.out_event
end

return midi_util
