-- constellations; version 0.8.3
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
-- ALT + ENC1 == probability
-- ALT + ENC2 == density
-- ALT + ENC3 == size
-- KEY1 == ALT
-- KEY2 == clear constellation
-- KEY3 == turn on/off 
--       the targeting computer
--       [off by default]
-- the current sequence length
--       is displayed in the 
--       bottom left corner
-- the current clock division
--       is displayed in the
--       top right corner
--
-- crow 
-- [ output1: 1 volt per octave ]
-- [ output2: clock pulse ]
-- [ output3: unipolar CV ]
-- [ output4: bipolar CV ]

engine.name = "PolyPerc"
local Mu = require 'musicutil'
local Util = require 'util'
local StarFactory = include 'lib/starfactory'
local midi_util = include 'lib/midi_util'
local seq = include 'lib/sequencer'
local stars = include 'lib/stars'
local crosshair = include 'lib/crosshair'
local ALT = false

-- output options; thanks to tehn & awake :)
local options = {}
options.OUTPUT = {
  "audio", 
  "audio + midi", 
  "midi", 
  "crow out", 
  "crow out + ii JF", 
  "crow ii JF"
}

function start() midi_util.start() end
function reset() seq.reset() end
function stop() midi_util.stop(); midi_util.all_notes_off() end
function clock.transport.start() start() end
function clock.transport.stop() stop() end
function clock.transport.reset() reset() end

-- main_event is called by the main clock
function main_event()
  while true do
     if seq.get_size() < 1 and midi_util.PLAY then
      stop()
    end
    clock.sync(1/params:get("step_div"))
    if midi_util.PLAY then
      midi_util.all_notes_off()
      if seq.get_size() > 0 then 
        seq.increment()
        local note = seq.get_note()
        if note then
          if math.random(100) <= params:get("probability") then
            if params:get("output") == 1 or params:get("output") == 2 then
              engine.release(seq.get_release())
              engine.amp(seq.get_amp())
              engine.hz(Mu.note_num_to_freq(note))
            end
            if crow.connected() then
              -- crow out
              if params:get("output") == 4 or params:get("output") == 5 then
                crow.output[1].volts = (note-60)/12
                crow.output[2].execute()
                crow.output[3].volts = seq.get_amp_crow()
                crow.output[4].volts = seq.get_release_crow()
              end
              -- JF out
              if params:get("output") == 5 or params:get("output") == 6 then
                crow.ii.jf.play_note((note-60)/12,5)
              end
            end
            -- MIDI out
            if (params:get("output") == 2 or params:get("output") == 3) then
              midi_util.out_device:note_on(note, 96, midi_util.out_channel)
              table.insert(midi_util.active_notes, note)
            end
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
  -- write current clock division
  screen.level(7)
  screen.move(124, 5)
  screen.text_right(""..params:get("step_div"))
  screen.fill()
  -- ALT
  if ALT then
    screen.level(2)
    screen.rect(32,0,96,68)
    screen.fill()
    screen.level(0)
    screen.font_face(3)
    screen.font_size(15)
    screen.move(36,2 + 32)
    screen.text("constellations")
    screen.level(15)
    screen.font_face(1)
    screen.font_size(8)
    screen.move(44,62)
    screen.text("density")
    screen.move(64,53)
    screen.text(params:get("density"))
    screen.move(103,62)
    screen.text("size")
    screen.move(103,53)
    screen.text(params:get("size"))
    screen.move(74, 6)
    screen.text("probability")
    screen.move(74, 15)
    screen.text(params:get("probability"))
    screen.stroke()
  end
  
  screen.update()
end


function key(n,z)
  if z == 1 then
    if n == 1 then
      ALT = true
    elseif n == 2 and ALT then
      seq.shift()
    elseif n == 2 then
      seq.clear_all()
    elseif n == 3 and ALT then
      seq.pop()
    elseif n == 3 then
      seq.toggle_lock()
    end
  else
    ALT = false
  end
end

function enc(n,d)
  if n == 1 and ALT then
    params:delta("probability",d)
  elseif n == 1 then
    params:delta("step_div",d)
  elseif n == 2 and ALT then
    params:delta("density",d)
  elseif n == 2 then
    crosshair.y = Util.clamp(crosshair.y + d, 0, 64 - 1)
  elseif n == 3 and ALT then
    params:delta("size",d)
  elseif n == 3 then
    crosshair.x = Util.clamp(crosshair.x + d, 0, 128 - 1)
  end
end

local function setup_params()
  params:add_separator("constellations")

  -- output params 
  params:add_group("output & midi",5)
  params:add{type = "option", id = "output", name = "output",
    options = options.OUTPUT,
    action = function(value)
      midi_util.all_notes_off()
      if value == 4 or value == 5 then 
        crow.output[2].action = "pulse()"
        crow.output[3].shape = "sine"
        crow.output[4].shape = "sine"
        crow.input[2].mode("stream", 0.01)
        crow.input[2].stream = crosshair.set_xy_crow
      end
      if value == 5 or value == 6 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      end
    end
  }

  -- midi params
  params:add{type = "option", id = "midi_out_device", 
    name = "midi out device",
    options = midi_util.out_devices, default = 1,
    action = function(value) 
      midi_util.out_device = midi.connect(value) 
      midi_util.attach_out_event()
    end
  }
  params:add{type = "number", id = "midi_out_channel", 
    name = "midi out channel",
    min = 1, max = 16, default = 1,
    action = function(value)
      midi_util.all_notes_off()
      midi_util.out_channel = value
    end
  }
  params:add{type = "option", id ="midi_in_devices", 
    name= "midi in device",
    options = midi_util.in_devices, default = 1,
    action = function(value) 
      midi_util.in_device = midi.connect(value) 
      midi_util.attach_in_event()
    end
  }
  params:add{type = "number", id = "midi_in_channel", 
    name = "midi in channel",
    min = 1, max = 16, default = 1,
    action = function(value) 
      midi_util.in_channel = value 
    end
  }
  
  -- sequencer params
  params:add_group("sequencer params",10)
  params:add{type = "number", id = "max_size", name = "max sequence size", 
    min = 1, max = 2000, default = 128
  }
  params:add{type = "option", id = "overwrite_logic", 
    name = "overwrite logic", 
    options = { "low to high", "random", "none" }, 
    default = 1
  }
  params:add{type = "number", id = "step_div", name = "step division", 
    min = 1, max = 16, default = 4
  }
  params:add{type = "option", id = "note_length", name = "note length",
    options = {"25%", "50%", "75%", "100%"},
    default = 4
  }
  params:add{type = "option", id = "scale_mode", name = "scale mode",
    options = seq.scale_names, default = 5,
    action = function() seq.build_scale() end
  }
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, 
    formatter = function(param) 
      return Mu.note_num_to_name(param:get(), true) 
    end,
    action = function() seq.build_scale() end
  }
  params:add{type = "number", id = "probability", name = "probability",
    min = 0, max = 100, default = 100
  }
  params:add{type = "trigger", id = "stop", name = "stop",
    action = function() stop() reset() end
  }
  params:add{type = "trigger", id = "start", name = "start",
    action = function() start() end
  }
  params:add{type = "trigger", id = "reset", name = "reset",
    action = function() reset() end
  }
 
  -- engine params
  params:add_group("engine params",6)
  cs_AMP = controlspec.new(0,1,'lin',0,0.5,'')
  params:add{type="control",id="amp",
    name="max amplitude",controlspec=cs_AMP,
    action=function(x) engine.amp(x) end
  }
  
  cs_REL = controlspec.new(0.1,3.2,'lin',0,1.2,'s')
  params:add{type="control",id="release", 
    name="max release",controlspec=cs_REL,
    action=function(x) engine.release(x) end
  }
  
  cs_PW = controlspec.new(0,100,'lin',0,50,'%')
  params:add{type="control",id="pulsewidth",controlspec=cs_PW,
    action=function(x) engine.pw(x/100) end
  }
  
  cs_CUT = controlspec.new(50,5000,'exp',0,800,'hz')
  params:add{type="control",id="cutoff",controlspec=cs_CUT,
    action=function(x) engine.cutoff(x) end
  }
  
  cs_GAIN = controlspec.new(0,4,'lin',0,1,'')
  params:add{type="control",id="gain",controlspec=cs_GAIN,
    action=function(x) engine.gain(x) end
  }
  
  cs_PAN = controlspec.new(-1,1, 'lin',0,0,'')
  params:add{type="control",id="pan",controlspec=cs_PAN,
    action=function(x) engine.pan(x) end
  }
 
  -- star params
  params:add{type = "number", id = "density", name = "star density",
    min = 1, max = 100, default = 25} 
  params:add{type = "number", id = "size", name = "star size",
    min = 1, max = 100, default = 1}
 end

function init()
  seq.build_scale_list()
  
  math.randomseed(Util.time())
  norns.enc.sens(2,2)
  norns.enc.sens(3,2)
  
  midi_util.build_midi_out_device_list()
  midi_util.build_midi_in_device_list()
  setup_params()
  seq.build_scale()
  midi_util.out_device = midi.connect(value) 
  midi_util.attach_out_event()

  function midi_util.in_event(data)
    msg = midi.to_msg(data)
    if msg.type == "cc" then
      if msg.cc == 0 then
        crosshair.set_y_midi(msg.val)
      elseif msg.cc == 1 then
        params:set("density",msg.val)
      elseif msg.cc == 2 then
        params:set("size",msg.val)
      end
    end
  end
  midi_util.in_device = midi.connect(value) 
  midi_util.attach_in_event()

  main_clock = clock.run(main_event)
end

notes_off_metro = metro.init()
notes_off_metro.event = midi_util.all_notes_off
animate = metro.init()
animate.time = 1/15
animate.event = function()
  -- create a star according to density param
  if math.random(100) <= params:get("density") then
    local star = StarFactory:new()
    local size = math.floor(math.log(math.random(params:get("size") * 15)))
    local qt = math.floor(size/4)
    local y = math.random(qt, 64 - qt)
    star.note = math.floor(Util.linlin(qt,64-qt,0,32,64-y))
    star.brightness = math.floor(math.random(1,15))
    star.size = size
    star.y = y
    stars.add(star)
  end
  -- apply changes
  stars.iterate(seq,crosshair)
  -- and then draw them
  redraw()
end
animate:start()

function rerun()
  norns.script.load(norns.state.script)
end

function cleanup()
  stop()
  clock.cancel(main_clock)
end
