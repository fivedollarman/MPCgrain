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
local fileselect = require "fileselect"
local MusicUtil = require "musicutil"

local in_device
local out_device
local msg 
local midiplay
local note
local pad = {}
local padreset = {}
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
local padbtn = 0
local writebtn = 0
local numfile = 1
local testo = "d(L)b"
local readpos = 1

local selected_file_path = 'none'
local selected_file = 'none'

local id_grp = 0
local id_prm = 0
local all_params = {}
local grp_params = {"midi", "trcks", "sampl", "prog", "mods", "file"}
all_params[1] = {"bpm", "midi_ch", "in_device", "out_device", "bend_rng", "note_1", "note_2", "note_3", "note_4", "note_5", "note_6", "note_7", "note_8"}
all_params[2] = {"sel", "num", "den"}
all_params[3] = {"rpos", "rlvl", "plvl", "loop"}
all_params[4] = {"step", "amp", "att", "rel", "rnode", "grainatt", "grainrel", "trgsel", "trgfrq", "rate", "dur", "transp", "filtcut", "rq", "delr", "dell", "drywet", "pan"}
all_params[5] = {"lfoatt", "lforel", "lfornode", "lfof", "lfoph", "noiseatt", "noiserel", "noisernode", "noisecut", "pitchlfo", "durlfo", "trigflfo", "poslfo", "filtlfo", "delllfo", "delrlfo", "panlfo", "pitchnoise", "durnoise", "trigfnoise", "posnoise", "filtnoise", "dellnoise", "delrnoise", "pannoise"}
all_params[6] = {"readpos", "numfile"}

-- MIDI input
local function midi_event(data)
  msg = midi.to_msg(data)
  record_midi()
  midi_act(msg)
end

function midi_act(msg)
    
    local channel_param = params:get("MPCgrain_midi_ch")
    

      -- Note off
    if msg.type == "note_off" then
      note = msg.note
      if msg.ch == channel_param then
        for i=1,#pad do
          if msg.note == pad[i] then
            engine.noteOff(i)
            padon[i]=0
          end
        end
      else
        out_device:note_off(msg.note, 0, msg.ch)
      end
      
    -- Note on
    elseif msg.type == "note_on" then
      note = msg.note
      if msg.ch == channel_param then
        for i=1,#pad do
          if note == pad[i] then
            engine.noteOn(i, note, msg.vel)
            padon[i]=1
          end
        end
      else
        out_device:note_on(note, msg.vel, msg.ch)
      end
      
    -- Pitch bend
    elseif msg.type == "pitchbend" then
      local bend_st = (util.round(msg.val / 2)) / 8192 * 2 -1 
      local bend_range = params:get("MPCgrain_bend_rng")
      if msg.ch == channel_param then
        engine.pitchBend(MusicUtil.interval_to_ratio(bend_st * bend_range))
      else
        out_device:pitchbend(msg.val, msg.ch)
      end
      
    -- CC
    elseif msg.type == "cc" then
      -- Mod wheel
      if msg.cc == 1 then
        -- print("modw " .. msg.val)
        if msg.ch == channel_param then
          params:set("MPCgrain_masterm", msg.val / 127)
        end 
      else
        out_device:cc(msg.cc, msg.val, msg.ch)
      end
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

function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

-- file selection

function callback(file_path) 
  if file_path ~= 'cancel' then 
    local split_at = string.match(file_path, "^.*()/")
    selected_file_path = string.sub(file_path, 9, split_at)
    selected_file_path = util.trim_string_to_width(selected_file_path, 128)
    selected_file = string.sub(file_path, split_at + 1)
    engine.readsamp(params:get("MPCgrain_readpos"), selected_file_path .. selected_file)
    print(selected_file_path .. selected_file)
  end
redraw()
end

function init()
  
  -- tracks
  for i=1,3 do
    track[i] = pattern_time.new()
    track[i].process = parse_midi
    track[i]:set_overdub(0)
  end 
  
  -- MIDI 
  
  local channels = {"All"}
  for i = 1, 16 do 
    table.insert(channels, i) 
  end
  table.insert(channels, "MPE")
  
  params:add_group("MPCgrainMIDI", 16)
  params:add_separator("tracks")
  params:add_control("MPCgrain_bpm", "bpm", controlspec.new(0, 240, "lin", 1, 120, ""))
  params:set_action("MPCgrain_bpm", function(x) params:set("clock_tempo",x) end)
  params:set_action("clock_tempo", function(x) engine.bpm(x) end)
  out_device = midi.connect(2)
  params:add{type = "number", id = "MPCgrain_out_device", name = "MIDI out Device", min = 1, max = 4, default = 1, action = function(value)
    out_device.event = nil
    out_device = midi.connect(value)
  end}
  in_device = midi.connect(1)
  params:add{type = "number", id = "MPCgrain_in_device", name = "MIDI in Device", min = 1, max = 4, default = 1, action = function(value)
    in_device.event = nil
    in_device = midi.connect(value)
    in_device.event = midi_event
  end}
  params:add{type = "option", id = "MPCgrain_midi_ch", name = "MIDI Channel", options = channels}
  params:add{type = "number", id = "MPCgrain_bend_rng", name = "Pitch Bend Range", min = 1, max = 48, default = 2}
  
  for i=1, 8 do
    params:add{type = "number", id = "MPCgrain_note_" .. i, name = "MIDI note pad " .. i, min = 0, max = 127, default = 63+i, action = function(value)
      pad = {table.unpack(padreset)} pad[i]=value padreset = {table.unpack(pad)}
    end}
  end
  
  -- params
  MPCgrain.add_params()
  
  params:add_group("MPCgraintrack", 13)
  params:add_separator("tracks")
  params:add_control("MPCgrain_num", "sync numerator", controlspec.new(1, 24, "lin", 1, 1, ""))
  params:set_action("MPCgrain_num", function(x) tnum=x end)
  params:add_control("MPCgrain_den", "sync denominator", controlspec.new(1, 24, "lin", 1, 1, ""))
  params:set_action("MPCgrain_den", function(x) tden=x end)
  params:add_control("MPCgrain_sel", "track select", controlspec.new(1, 3, "lin", 1, 1, ""))
  params:set_action("MPCgrain_sel", function(x) trcksel=x end)
  for i=1,3 do
    params:add_control("MPCgrain_play_" .. i,"play " .. i, controlspec.new(0, 1, "lin", 1, 0, ""))
    params:set_action("MPCgrain_play_" .. i, function(x) if x==1 then tplay[i]=clock.run(playloop,tnum,tden,i) end end)
    params:add_control("MPCgrain_rec_" .. i,"rec " .. i, controlspec.new(0, 1, "lin", 1, 0, ""))
    params:set_action("MPCgrain_rec_" .. i, function(x) if x==1 then trec[i]=clock.run(recloop,tnum,tden,i) end end)
  end
  
  params:add_group("MPCfile", 3)
  params:add_separator("file")
  params:add_control("MPCgrain_numfile", "numfile", controlspec.new(1, 127, "lin", 1, 1, ""))
  params:set_action("MPCgrain_numfile", function(x) numfile=x end)
  params:add_control("MPCgrain_readpos", "readpos", controlspec.new(1, 8, "lin", 1, 1, ""))
  params:set_action("MPCgrain_readpos", function(x) readpos=x end)

  -- load default pset
  params:read()
  params:bang()
end

function redraw()
  screen.clear()
  
  screen.level(8)
  screen.move(93, 6)
  if runbtn==1 then testo="sampling" elseif trecloop[1]==1 then testo="rec.." elseif trecloop[2]==1 then testo="rec.." elseif trecloop[3]==1 then testo="rec.." elseif writebtn==1 then testo="write" else testo="d(u)b" end
  screen.text(testo)
  
  -- note variation
  if grp_params[id_grp+1] == "mods" then
    screen.level(12) 
  else
    screen.level(5)
  end
  screen.rect(1,24+(34-(params:get("MPCgrain_masterm")*34)),4,2)
  screen.fill()
  screen.rect(1,27+(34-(params:get("MPCgrain_masterm")*34)),4,2)
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
  
  if grp_params[id_grp+1] == "prog" then
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
      screen.rect(85+8+(12*(i-1)), 42, 7, 5)
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
      screen.rect(85+8+(12*(i-1)), 53, 7, 5)
    else
      if playbtn[trcksel]==1 and i==2 then
        screen.rect(85+8+(12*(i-1)), 53, 7, 5)
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
    if grp_params[id_grp+1] == "trcks" and i==1 then
      screen.level(0) 
    elseif grp_params[id_grp+1] == "sampl" and i==2 then
      screen.level(0) 
    elseif grp_params[id_grp+1] == "prog" and i==3 then
      screen.level(0) 
    else
      screen.level(5)
    end
    screen.pixel(104+8+(5*(i-1)), 18)
    screen.stroke()
    if grp_params[id_grp+1] == "mods" and i==1 then
      screen.level(0) 
    elseif grp_params[id_grp+1] == "midi" and i==2 then
      screen.level(0)     
    elseif grp_params[id_grp+1] == "file" and i==3 then
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
  if n==2 and z==1 and grp_params[id_grp+1] == "midi" then
    shuffle(pad)
  elseif n==2 and z==1 and grp_params[id_grp+1] == "trcks" then
    recbtn[trcksel] = (recbtn[trcksel] + 1) % 2
    params:set("MPCgrain_rec_" .. trcksel, recbtn[trcksel])
  elseif n==2 and z==1 and grp_params[id_grp+1] == "sampl" then
    runbtn = 1
    params:set("MPCgrain_run", runbtn)
  elseif n==2 and z==0 and grp_params[id_grp+1] == "sampl" then
    runbtn = 0
    params:set("MPCgrain_run", runbtn)
  elseif n==2 and z==1 and grp_params[id_grp+1] == "prog" then
    for i = 1,#all_params[4]-1 do
      local p_name = all_params[4][i]
      local minmax = params:get_range("MPCgrain_"..p_name)
      params:set("MPCgrain_"..p_name, math.random(minmax[1]*100,minmax[2]*100)/100)
    end
  elseif n==2 and z==1 and grp_params[id_grp+1] == "mods" then
    for i = 1,#all_params[5] do
      local p_name = all_params[5][i]
      local minmax = params:get_range("MPCgrain_"..p_name)
      params:set("MPCgrain_"..p_name, math.random(minmax[1]*100,minmax[2]*100)/100)
    end
  elseif n==2 and z==1 and grp_params[id_grp+1] == "file" then
    writebtn=1
    engine.writesamp(numfile)
  elseif n==2 and z==0 and grp_params[id_grp+1] == "file" then
    writebtn=0
  elseif n==3 and z==1 and grp_params[id_grp+1] == "midi" then
    pad = {table.unpack(padreset)} 
  elseif n==3 and z==1 and grp_params[id_grp+1] == "trcks" then
    playbtn[trcksel] = (playbtn[trcksel] + 1) % 2
    params:set("MPCgrain_play_" .. trcksel, playbtn[trcksel])
  elseif n==3 and z==1 and grp_params[id_grp+1] == "sampl" then
    padbtn = (padbtn + 1) % 2
    engine.noteOn(params:get("MPCgrain_rpos"), 0, 127)
    padon[params:get("MPCgrain_rpos")]=1
  elseif n==3 and z==0 and grp_params[id_grp+1] == "sampl" then
    padbtn = (padbtn + 1) % 2
    engine.noteOffAll()
    padon[params:get("MPCgrain_rpos")]=0
  elseif n==3 and z==1 and grp_params[id_grp+1] == "prog" then
    params:read()
  elseif n==3 and z==1 and grp_params[id_grp+1] == "mods" then
    params:read()
  elseif n==3 and z==1 and grp_params[id_grp+1] == "file" then
    fileselect.enter(_path.dust, callback)
  end
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
