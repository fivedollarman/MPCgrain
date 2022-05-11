-- MPCgrain: granular Music
--                     Production 
--       d('u')b        Center
-- 1.0.0 @marcocinque 
-- llllllll.co/t/
-- enc1 > pages
--

engine.name = "mpcgrain"
MPCgrain = include('MPCgrain/lib/mpcgrain_params')

local pattern_time = require "pattern_time"
local in_device
local out_device
local msg 
local midiplay
local note = 0
local vel = 0
local ch = 0
local pad = {}

local id_grp = 0
local id_prm = 0
local all_params = {}
local grp_params = {"midi", "track", "sampl", "prog", "mods"}
all_params[1] = {"in_device", "out_device"}
all_params[2] = {"out_device"}
all_params[3] = {"rpos", "rlvl", "plvl", "loop", "mode"}
all_params[4] = {"pos", "bpm", "step", "amp", "att", "rel", "rnode", "trgsel", "trgfrq", "rate", "dur", "transp", "filtcut", "rq", "delr", "dell", "drywet", "pan"}
all_params[5] = {"mpos", "mamp", "matt", "mrel", "mrnode", "lfof", "lfoph", "lfoq", "noiseq", "mfiltcut", "mastermod", "pitchmod", "durmod", "trigfmod", "posmod", "filtmod", "panmod", "dellmod", "delrmod"}

-- MIDI input
local function midi_event(data)
  
  record_midi()
  msg = midi.to_msg(data)
  local channel_param = params:get("midi_channel")

  if channel_param == 18 then
    channel_param = 1
    mpe_mode = true
  end

  if channel_param == 1 or (channel_param > 1 and msg.ch == channel_param - 1) then
    
    -- Note off
    if msg.type == "note_off" then
      note = msg.note
      vel = msg.vel
      ch = msg.ch
      for i=1,#pad do
        if note == pad[i] then
          engine.noteOff(i)
        end
      end
    
    -- Note on
    elseif msg.type == "note_on" then
      note = msg.note
      vel = msg.vel
      ch = msg.ch
      for i=1,#pad do
        if note == pad[i] then
          engine.noteOn(i, note, vel / 127)
        end
      end
      
    -- Pitch bend
    elseif msg.type == "pitchbend" then
      local bend_st = (util.round(msg.val / 2)) / 8192 * 2 -1 
      local bend_range = params:get("bend_range")
      engine.pitchBend(MusicUtil.interval_to_ratio(bend_st * bend_range))
    end
  end
end

function record_midi()
  trck1_pattern:watch(
    {
      ["midi"] = msg
    }
  )
  trck2_pattern:watch(
    {
      ["midi"] = msg
    }
  )
  trck3_pattern:watch(
    {
      ["midi"] = msg
    }
  )
end

function parse_midi(data)
  midiplay = data.midi
  -- todo
end


function init()
  
  -- MIDI 
  out_device = midi.connect(2)
  out_device.event = midi_event
  
  params:add{type = "number", id = "MPCgrain_out_device", name = "MIDI out Device", min = 1, max = 4, default = 1, action = function(value)
    out_device.event = nil
    out_device = midi.connect(value)
    out_device.event = midi_event
  end}

  in_device = midi.connect(1)
  in_device.event = midi_event
  
  params:add{type = "number", id = "MPCgrain_in_device", name = "MIDI in Device", min = 1, max = 4, default = 1, action = function(value)
    in_device.event = nil
    in_device = midi.connect(value)
    in_device.event = midi_event
  end}
  
  local channels = {"All"}
  for i = 1, 16 do 
    table.insert(channels, i) 
  end
  
  table.insert(channels, "MPE")
  params:add{type = "option", id = "midi_channel", name = "MIDI Channel", options = channels}
  params:add{type = "number", id = "bend_range", name = "Pitch Bend Range", min = 1, max = 48, default = 2}
  
  -- tracks
  trck1_pattern = pattern_time.new()
  trck1_pattern.process = parse_midi
  trck2_pattern = pattern_time.new()
  trck2_pattern.process = parse_midi
  trck3_pattern = pattern_time.new()
  trck3_pattern.process = parse_midi
  
  -- params
  MPCgrain.add_params()
  
end


function redraw()
  screen.clear()
  
  screen.level(8)
  screen.move(93, 6)
  screen.text("$5 d(u)b")
  
  -- note variation
  
  screen.level(10)
  screen.rect(1,18,5,3)
  screen.stroke()
  
  screen.level(5)
  screen.rect(1,24,5,40)
  screen.stroke()
  
  screen.level(7)
  screen.rect(1,31,4,2)
  screen.fill()
  screen.level(7)
  screen.rect(1,34,4,2)
  screen.fill()
  
  -- screen
    
  screen.level(5)  
  screen.move(11, 10)
  screen.line(11, 1)
  screen.level(10) 
  screen.line(84, 1)
  screen.level(5) 
  screen.line(84, 10)
  screen.stroke()
  
  screen.level(12)
  screen.rect (14, 4, 66, 24)
  screen.fill()
  
  screen.level(1)
  screen.move(20, 12)
  screen.text("=== ".. grp_params[id_grp+1] .." ===")
  screen.move(20, 22)
  screen.text(all_params[id_grp+1][id_prm+1] .. ": " .. params:get("MPCgrain_" .. all_params[id_grp+1][id_prm+1]))
  
  -- pads

  screen.level(2)
  screen.rect (12, 32, 70, 32)
  screen.fill()
  
  for i=1,4 do
    screen.level(0) 
    screen.move(18+(16*(i-1)), 46)
    screen.line(28+(16*(i-1)), 46)
    screen.line(28+(16*(i-1)), 36)
    screen.stroke()
    screen.level(5) 
    screen.rect(18+(16*(i-1)), 36, 8, 8)
    screen.fill()
    screen.level(0) 
    screen.move(18+(16*(i-1)), 60)
    screen.line(28+(16*(i-1)), 60)
    screen.line(28+(16*(i-1)), 50)
    screen.stroke()
    screen.level(5) 
    screen.rect(18+(16*(i-1)), 50, 8, 8)
    screen.fill()
  end
  
  --play/rec
  
  screen.level(3)
  screen.rect (90, 39, 38, 22)
  screen.fill()
  
  for i=1,3 do
    screen.level(0) 
    screen.move(85+8+(12*(i-1)), 48)
    screen.line(85+16+(12*(i-1)), 48)
    screen.line(85+16+(12*(i-1)), 42)
    screen.stroke()
    screen.level(5) 
    screen.rect(85+8+(12*(i-1)), 42, 7, 5)
    screen.fill()
    screen.level(0) 
    screen.move(85+8+(12*(i-1)), 59)
    screen.line(85+16+(12*(i-1)), 59)
    screen.line(85+16+(12*(i-1)), 53)
    screen.stroke()
    screen.level(5) 
    screen.rect(85+8+(12*(i-1)), 53, 7, 5)
    screen.fill()
  end
  
  -- rotary

  screen.aa(1)
  screen.level(2)
  screen.circle(98, 21, 7)
  screen.fill()
  screen.level(10)
  screen.circle(97, 20, 6)
  screen.fill()
  screen.aa(0)
  
  --- buttons
  for i=1,3 do
    screen.level(5) 
    screen.pixel(104+8+(5*(i-1)), 18)
    screen.stroke()
    screen.level(5) 
    screen.pixel(104+8+(5*(i-1)), 24)
    screen.stroke()
  end

  screen.update()
end

function key(n,z)

  redraw()
end

function enc(n,d)
  if n == 1 then
    id_grp = (id_grp+d) % #grp_params
    id_prm = 0
  elseif n == 2 then
    id_prm = (id_prm+d) % #all_params[id_grp+1]
  elseif n == 3 then
    params:delta("MPCgrain_" .. all_params[id_grp+1][id_prm+1], d)
  end
  redraw()
end


function cleanup()
  
end
