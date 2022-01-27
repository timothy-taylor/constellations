-- constellations; version 0.8
--
-- scan the stars, make music
-- an interactive sequencer
-- for norns, crow, jf, midi
--
--
-- [controls below]
-- ENC1 == time division
-- ENC2 == y axis control
-- ENC3 == x axis control
-- K2 == CLEAR constellation
-- K3 == turn on/off 
--       the targeting computer
--       [off by default]
-- the current sequence length
--       is displayed in the 
--       bottom left corner

engine.name = "PolyPerc"
local Mu = require 'musicutil'
local Util = require 'util'
local StarFactory = include 'lib/starfactory'
local seq = include 'lib/sequencer'
local stars = include 'lib/stars'
local crosshair = { size = 3, x = 128 / 2, y = 64 / 2 }

-- output & midi thanks to awake :)
local options = {}
options.OUTPUT = {"audio", "crow out 1+2", "crow ii JF", "midi", "audio + midi"}
local midi_devices
local midi_device
local midi_channel

function build_midi_device_list()
  midi_devices = {}
  for i = 1,#midi.vports do
    local long_name = midi.vports[i].name
    local short_name = string.len(long_name) > 15 and util.acronym(long_name) or long_name
    table.insert(midi_devices,i..": "..short_name)
  end
end

function all_notes_off()
  if (params:get("output") == 4 or params:get("output") == 5) then
    for _, a in pairs(seq.active_notes) do
      midi_device:note_off(a, nil, midi_channel)
    end
  end
  seq.active_notes = {}
end

function start() seq.start() end
function reset() seq.reset() end
function stop() seq.stop(); all_notes_off() end
function clock.transport.start() start() end
function clock.transport.stop() stop() end
function clock.transport.reset() reset() end

function midi_event(data)
  msg = midi.to_msg(data)
  if msg.type == "start" then
    clock.transport.reset()
    clock.transport.start()
  elseif msg.type == "continue" then
    if seq.PLAY then 
      clock.transport.stop()
    else 
      clock.transport.start()
    end
  end 
  if msg.type == "stop" then
    clock.transport.stop()
  end 
end

-- main_event is called by the main clock
function main_event()
  while true do
     if seq.get_size() < 1 and seq.PLAY then
      stop()
    end
    clock.sync(1/params:get("step_div"))
    if seq.PLAY then
      all_notes_off()
      if seq.get_size() > 0 then 
        seq.increment()
        local note = seq.get_note()
        if note then
          if math.random(100) <= params:get("probability") then
            if params:get("output") == 1 or params:get("output") == 5 then
              engine.hz(Mu.note_num_to_freq(note))
            elseif params:get("output") == 2 then
              crow.output[1].volts = (note-60)/12
              crow.output[2].execute()
            elseif params:get("output") == 3 then
              crow.ii.jf.play_note((note-60)/12,5)
            end
            -- MIDI out
            if (params:get("output") == 4 or params:get("output") == 5) then
              midi_device:note_on(note, 96, midi_channel)
              table.insert(seq.active_notes, note)
            end
            --local note_off_time = 
            -- Note off timeout
            if params:get("note_length") < 4 then
              notes_off_metro:start(
                (60 / params:get("clock_tempo") 
                    / params:get("step_div")) 
                    * params:get("note_length") 
                    * 0.25, 1)
            end
          end
        end
      else
        stop()
      end
    end
  end
end


function redraw()
  screen.clear()

  local n = stars.get_number()
  if n > 0 then
    local lastX
    local lastY
    for i=1,n do
      local s = stars.data[i]
      if s then
        -- draw the star
        screen.level(s.brightness)
        screen.circle(s.x, s.y, s.size)
        screen.fill()
        if s.TAGGED and not seq.CLEAR then
          -- draw the TAGGED box
          screen.level(2)
          screen.rect(
            s.x - s.size - 1, 
            s.y - s.size - 1, 
            2 + s.size * 2, 
            2 + s.size * 2
            )
            screen.stroke()
            
            if lastX and lastY then
              screen.level(2)
              screen.move(s.x,s.y)
              screen.line(lastX,lastY)
              screen.stroke()
            end
            lastX = s.x
            lastY = s.y
        end
      end
    end
  end
  -- draw the crosshair
  screen.level(1)
  for n=1,crosshair.size do
    screen.pixel(crosshair.x, crosshair.y)
    screen.pixel(crosshair.x + n, crosshair.y)
    screen.pixel(crosshair.x - n, crosshair.y)
    if not seq.LOCKED then screen.pixel(crosshair.x, crosshair.y + n) end
    if not seq.LOCKED then screen.pixel(crosshair.x, crosshair.y - n) end
  end
  screen.fill()
  -- write the size of sequence
  screen.level(7)
  screen.move(0,64)
  screen.text(""..seq.get_size())
  screen.fill() 
  
  screen.update()
end


function key(n,z)
  if z == 1 then
    if n == 2 then
      seq.clear_notes()
    elseif n == 3 then
      seq.toggle_lock()
    end
  end
end

function enc(n,d)
  if n == 1 then
    params:delta("step_div",d)
  elseif n == 2 then
    crosshair.y = Util.clamp(crosshair.y + d, 0, 64 - 1)
  elseif n == 3 then
    crosshair.x = Util.clamp(crosshair.x + d, 0, 128 - 1)
  end
end

local function setup_params()
  params:add_separator("Constellations")
  
  params:add_group("output",3)
  params:add{type = "option", id = "output", name = "output",
    options = options.OUTPUT,
    action = function(value)
      all_notes_off()
      if value == 2 then crow.output[2].action = "pulse()"
      elseif value == 3 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      end
    end
  }
    
  params:add{type = "option", id = "midi_device", name = "midi out device",
    options = midi_devices, default = 1,
    action = function(value) midi_device = midi.connect(value) end
  }
    
  params:add{type = "number", id = "midi_out_channel", name = "midi out channel",
    min = 1, max = 16, default = 1,
    action = function(value)
      all_notes_off()
      midi_channel = value
    end
  }
      
  params:add_group("sequencer params",8)
  params:add{type = "number", id = "step_div", name = "step division", min = 1, max = 16, default = 4}
  
  params:add{type = "option", id = "note_length", name = "note length",
    options = {"25%", "50%", "75%", "100%"},
    default = 4}
  
  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = seq.scale_names, default = 5,
    action = function() seq.build_scale() end}
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, formatter = function(param) return Mu.note_num_to_name(param:get(), true) end,
    action = function() seq.build_scale() end}
  params:add{type = "number", id = "probability", name = "probability",
    min = 0, max = 100, default = 100}
  params:add{type = "trigger", id = "stop", name = "stop",
    action = function() stop() reset() end}
  params:add{type = "trigger", id = "start", name = "start",
    action = function() start() end}
  params:add{type = "trigger", id = "reset", name = "reset",
    action = function() reset() end}
  
  params:add_group("engine params",6)
  cs_AMP = controlspec.new(0,1,'lin',0,0.3,'')
  params:add{type="control",id="amp",controlspec=cs_AMP,
    action=function(x) engine.amp(x) end}
  
  cs_PW = controlspec.new(0,100,'lin',0,50,'%')
  params:add{type="control",id="pw",controlspec=cs_PW,
    action=function(x) engine.pw(x/100) end}
  
  cs_REL = controlspec.new(0.1,3.2,'lin',0,1.2,'s')
  params:add{type="control",id="release",controlspec=cs_REL,
    action=function(x) engine.release(x) end}
  
  cs_CUT = controlspec.new(50,5000,'exp',0,800,'hz')
  params:add{type="control",id="cutoff",controlspec=cs_CUT,
    action=function(x) engine.cutoff(x) end}
  
  cs_GAIN = controlspec.new(0,4,'lin',0,1,'')
  params:add{type="control",id="gain",controlspec=cs_GAIN,
    action=function(x) engine.gain(x) end}
  
  cs_PAN = controlspec.new(-1,1, 'lin',0,0,'')
  params:add{type="control",id="pan",controlspec=cs_PAN,
    action=function(x) engine.pan(x) end}
end

function init()
  for i = 1, #Mu.SCALES do
    table.insert(seq.scale_names, string.lower(Mu.SCALES[i].name))
  end   
  
  math.randomseed(Util.time())
  norns.enc.sens(2,2)
  norns.enc.sens(3,1)
  
  build_midi_device_list()
  setup_params()
  seq.build_scale()
  midi_device = midi.connect(value)
  midi_device.event = midi_event
  main_clock = clock.run(main_event)
end

notes_off_metro = metro.init()
notes_off_metro.event = all_notes_off
animate = metro.init()
animate.time = 1/15
animate.event = function()
  -- create a star with 25% probability
  if math.random() <= 0.25 then
    local star = StarFactory:new()
    local size = math.floor(math.log(math.random(15)))
    local qt = math.floor(size/4)
    local y = math.random(qt, 64 - qt)
    star.note = math.floor(Util.linlin(qt,64-qt,0,32,64-y))
    star.brightness = math.floor(math.random(1,15))
    star.size = size
    star.y = y
    stars.add(star)
  end
  -- update stars
  stars.iterate(seq,crosshair)
  -- and then draw them
  redraw()
end
animate:start()

function cleanup()
  stop()
  clock.cancel(main_clock)
end
