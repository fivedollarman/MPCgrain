-- MPCgrain: granular Music
--                     Production 
--       d('u')b        Center
-- 1.0.0 @marcocinque 
-- llllllll.co/t/
-- enc1 > pages
--

engine.name = "mpcgrain"
MPCgrain = include('MPCgrain/lib/mpcgrain_params')

local MusicUtil = require "musicutil"
local pattern_time = require "pattern_time"
local in_device
local out_device
local msg 
local midiplay
local note = 0
local vel = 0
local ch = 0
local pad = {}
local padon = {0,0,0,0,0,0,0,0}
local track = {}
local tnum = 8
local tden = 1
local tplay = {}
local trec = {}
local tplayloop = {}
local trecloop = {}
local recbtn = {0,0,0}
local playbtn = {0,0,0}
local trcksel = 1
local runbtn = 0
local testo = "d(L)b"

local id_grp = 0
local id_prm = 0
local all_params = {}
local grp_params = {"midi", "trcks", "sampl", "prog", "mods"}
all_params[1] = {"in_device", "out_device"}
all_params[2] = {"sel", "bpm", "num", "den"}
all_params[3] = {"rpos", "rlvl", "plvl", "loop", "mode"}
all_params[4] = {"pos", "step", "amp", "att", "rel", "rnode", "trgsel", "trgfrq", "rate", "dur", "transp", "filtcut", "rq", "delr", "dell", "drywet", "pan"}
all_params[5] = {"mpos", "mamp", "matt", "mrel", "mrnode", "lfof", "lfoph", "lfoq", "noiseq", "mfiltcut", "mastermod", "pitchmod", "durmod", "trigfmod", "posmod", "filtmod", "panmod", "dellmod", "delrmod"}

-- MIDI input
local function midi_event(data)
  msg = midi.to_msg(data)
  record_midi()
  local channel_param = params:get("midi_channel")
  if channel_param == 1 or (channel_param > 1 and msg.ch == channel_param - 1) then
    midi_act(msg)
  end
end

function midi_act(msg)
      -- Note off
    if msg.type == "note_off" then
      note = msg.note
      print("note off " .. note)
      vel = msg.vel
      ch = msg.ch
      for i=1,#pad do
        if note == pad[i] then
          engine.noteOff(i)
          padon[i]=0
        end
      end
    
    -- Note on
    elseif msg.type == "note_on" then
      note = msg.note
      print("note on " .. note)
      vel = msg.vel
      ch = msg.ch
      for i=1,#pad do
        if note == pad[i] then
          engine.noteOn(i, note, vel / 127)
          padon[i]=1
        end
      end
      
    -- Pitch bend
    elseif msg.type == "pitchbend" then
      local bend_st = (util.round(msg.val / 2)) / 8192 * 2 -1 
      local bend_range = params:get("bend_range")
      engine.pitchBend(MusicUtil.interval_to_ratio(bend_st * bend_range))
    end
  redraw()
end

-- midi looper funcs

function record_midi()
  for i=1,3 do
    track[i]:watch(
      {
        ["value"] = msg
      }
    )
  end
end

function parse_midi(data)
  midiplay = data.value
  midi_act(midiplay)
end
 
function playloop(num, den, i)
  tplayloop[i]=1
  track[i]:start()
  while tplayloop[i]==1 do
    print("play sync")
    clock.sync(num*4/den)
    if params:get("MPCgrain_play_" .. i) == 0 then
      track[i]:stop()
      print("play stop")
      tplayloop[i]=0
      redraw()
      clock.cancel(tplay[i])
    end
  end
end

function recloop(num, den, i)
  trecloop[i]=1
  track[i]:rec_start()
  while trecloop[i]==1 do
    print("rec sync")
    clock.sync(num*4/den)
    if params:get("MPCgrain_rec_" .. i) == 0 then
      track[i]:rec_stop()
      print("rec stop")
      trecloop[i]=0
      redraw()
      clock.cancel(trec[i])
    end
  end
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
  
  for i=1, 8 do
    params:add{type = "number", id = "MPCgrain_note_" .. i, name = "MIDI note pad " .. i, min = 0, max = 127, default = 63+i, action = function(value)
      pad[i]=value
    end}
  end
  
  -- tracks
  for i=1,3 do
    track[i] = pattern_time.new()
    track[i].process = parse_midi
    track[i]:set_overdub(1)
  end 
  
  -- params
  MPCgrain.add_params()
  
  params:add_group("MPCgraintrack", 4)
  params:add_separator("tracks")
  params:add_control("MPCgrain_bpm", "bpm", controlspec.new(0, 240, "lin", 1, 120, ""))
  params:set_action("MPCgrain_bpm", function(x) params:set("clock_tempo",x) end)
  params:set_action("clock_tempo", function(x) engine.bpm(x) end)
  params:add_control("MPCgrain_num", "sync numerator", controlspec.new(1, 24, "lin", 1, 1, ""))
  params:set_action("MPCgrain_num", function(x) tnum=x end)
  params:add_control("MPCgrain_den", "sync denominator", controlspec.new(1, 24, "lin", 1, 1, ""))
  params:set_action("MPCgrain_den", function(x) tden=x end)
  params:add_control("MPCgrain_sel", "track select", controlspec.new(1, 3, "lin", 1, 1, ""))
  params:set_action("MPCgrain_sel", function(x) trcksel=x end)
  for i=1,3 do
    params:add_control("MPCgrain_play_" .. i,"play", controlspec.new(0, 1, "lin", 1, 0, ""))
    params:set_action("MPCgrain_play_" .. i, function(x) if x==1 then tplay[i]=clock.run(playloop,tnum,tden,i) end end)
    params:add_control("MPCgrain_rec_" .. i,"play", controlspec.new(0, 1, "lin", 1, 0, ""))
    params:set_action("MPCgrain_rec_" .. i, function(x) if x==1 then trec[i]=clock.run(recloop,tnum,tden,i) end end)
  end
  params:bang()
end

function redraw()
  screen.clear()
  
  screen.level(8)
  screen.move(93, 6)
  if trecloop[1]==1 then testo="rec.." elseif trecloop[2]==1 then testo="rec.." elseif trecloop[3]==1 then testo="rec.." else testo="d(u)b" end
  screen.text(testo)
  
  -- note variation
  screen.level(10)
  screen.rect(1,18,5,3)
  screen.stroke()
  
  if grp_params[id_grp+1] == "mods" then
    screen.level(12) 
  else
    screen.level(5)
  end
  screen.rect(1,24,5,40)
  screen.stroke()
  
  screen.level(8)
  screen.rect(1,31,4,2)
  screen.fill()
  screen.level(8)
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
  
  if grp_params[id_grp+1] == "prog" or grp_params[id_grp+1] == "sampl" then
    screen.level(12)
    screen.rect (12, 32, 70, 32)
    screen.stroke() 
  end
  
  for i=1,4 do
    if padon[i+4]==1 then
      screen.level(2) 
    else
      screen.level(0) 
    end
    screen.move(18+(16*(i-1)), 46)
    screen.line(28+(16*(i-1)), 46)
    screen.line(28+(16*(i-1)), 36)
    screen.stroke()
    screen.level(5)
    if padon[i+4]==1 then
      screen.rect(18+(16*(i-1))+1, 36+1, 8, 8)
    else
      screen.rect(18+(16*(i-1)), 36, 8, 8) 
    end
    screen.fill()
    if padon[i]==1 then
      screen.level(2) 
    else
      screen.level(0) 
    end 
    screen.move(18+(16*(i-1)), 60)
    screen.line(28+(16*(i-1)), 60)
    screen.line(28+(16*(i-1)), 50)
    screen.stroke()
    screen.level(5) 
    if padon[i]==1 then
      screen.rect(18+(16*(i-1))+1, 50+1, 8, 8)
    else
      screen.rect(18+(16*(i-1)), 50, 8, 8)
    end
    screen.fill()
  end
  
  --play/rec
  screen.level(3)
  screen.rect (90, 39, 38, 22)
  screen.fill()
  
  if grp_params[id_grp+1] == "trcks" then
    screen.level(12)
    screen.rect (90, 39, 38, 23)
    screen.stroke() 
  end
  
  for i=1,3 do
    if trcksel==i then
      screen.level(3)
    else
      screen.level(0) 
    end
    screen.move(85+8+(12*(i-1)), 48)
    screen.line(85+16+(12*(i-1)), 48)
    screen.line(85+16+(12*(i-1)), 42)
    screen.stroke()
    screen.level(5)
    if trcksel==i then
      screen.rect(85+8+(12*(i-1))+1, 42+1, 7, 5)
    else
      screen.rect(85+8+(12*(i-1)), 42, 7, 5)
    end
    screen.fill()
    if recbtn[trcksel]==1 and i==1 then
      screen.level(3)
    else
      if playbtn[trcksel]==1 and i==2 then
        screen.level(3)
      else
        screen.level(0)
      end 
    end
    screen.move(85+8+(12*(i-1)), 59)
    screen.line(85+16+(12*(i-1)), 59)
    screen.line(85+16+(12*(i-1)), 53)
    screen.stroke()
    screen.level(5) 
    if recbtn[trcksel]==1 and i==1 then
      screen.rect(85+8+(12*(i-1))+1, 53, 7, 5)
    else
      if playbtn[trcksel]==1 and i==2 then
        screen.rect(85+8+(12*(i-1))+1, 53, 7, 5)
      else
        screen.rect(85+8+(12*(i-1)), 53, 7, 5)
      end
    end
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
    if grp_params[id_grp+1] == "midi" and i==1 then
      screen.level(0) 
    elseif grp_params[id_grp+1] == "trcks" and i==2 then
      screen.level(0) 
    elseif grp_params[id_grp+1] == "sampl" and i==3 then
      screen.level(0) 
    else
      screen.level(5)
    end
    screen.pixel(104+8+(5*(i-1)), 18)
    screen.stroke()
    if grp_params[id_grp+1] == "prog" and i==1 then
      screen.level(0) 
    elseif grp_params[id_grp+1] == "mods" and i==2 then
      screen.level(0) 
    else
      screen.level(5)
    end
    screen.pixel(104+8+(5*(i-1)), 24)
    screen.stroke()
  end

  screen.update()
end

function key(n,z)
  if n==2 and z==1 and grp_params[id_grp+1] == "trcks" then
    recbtn[trcksel] = (recbtn[trcksel] + 1) % 2
    params:set("MPCgrain_rec_" .. trcksel, recbtn[trcksel])
  elseif n==2 and z==1 and grp_params[id_grp+1] == "sampl" then
    runbtn = (runbtn + 1) % 2
    params:set("MPCgrain_run", runbtn)
  elseif n==3 and z==1 and grp_params[id_grp+1] == "trcks" then
    playbtn[trcksel] = (playbtn[trcksel] + 1) % 2
    params:set("MPCgrain_play_" .. trcksel, playbtn[trcksel])
  end
  redraw()
end

function enc(n,d)
  if n == 1 then
    id_grp = (id_grp+d) % #grp_params
    id_prm = 0
  elseif n == 2 then
    params:delta("MPCgrain_" .. all_params[id_grp+1][id_prm+1], d)
  elseif n == 3 then
    id_prm = (id_prm+d) % #all_params[id_grp+1]
  end
  redraw()
end


function cleanup()
  
end
