local MPCgrain = {}
local Formatters = require 'formatters'

-- ranges
local specs = {
  ["step"] = controlspec.new(1, 16, "lin", 1, 4, ""),
  ["amp"] = controlspec.new(0, 12, 'lin', 0, 1, ""),
  ["att"] = controlspec.new(0, 4, "lin", 0.05, 0, "s"),
  ["rel"] = controlspec.new(0, 8, "lin", 0.1, 1, "s"),
  ["grainatt"] = controlspec.new(-64, 64, "lin", 1, 0, ""),
  ["grainrel"] = controlspec.new(-64, 64, "lin", 1, 0, ""),
  ["rnode"] = controlspec.new(0, 2, "lin", 1, 1, ""),
  ["trgsel"] = controlspec.new(0, 1, "lin", 1, 0, ""),
  ["trgfrq"] = controlspec.new(1, 128, "lin", 1, 16, ""),
  ["rate"] = controlspec.new(0, 4, "lin", 0, 1, ""),
  ["dur"] = controlspec.new(0, 2, "lin", 0.02, 1, ""),
  ["transp"] = controlspec.new(-24, 24, "lin", 0.5, 0, ""),
  ["samplerate"] = controlspec.new(8, 48, "lin", 0.5, 48, "k"),
  ["bits"] = controlspec.new(4, 24, "lin", 0.2, 24, ""),
  ["filtcut"] = controlspec.new(8, 127, "lin", 1, 127, ""),
  ["rq"] = controlspec.new(0, 1, "lin", 0, 0, ""),
  ["delr"] = controlspec.new(0, 127, "lin", 1, 0, "ms"),
  ["dell"] = controlspec.new(0, 127, "lin", 1, 0, "ms"),
  ["drywet"] = controlspec.new(0, 1, "lin", 0, 0, ""),
  ["pan"] = controlspec.PAN
}

local param_names = {"step", "amp", "att", "rel", "grainatt", "grainrel", "rnode", "trgsel", "trgfrq", "rate", "dur", "transp", "samplerate", "bits", "filtcut", "rq", "delr", "dell", "drywet", "pan"}

local mspecs = {
  ["lfoatt"] = controlspec.new(0, 4, "lin", 0.05, 1, "s"),
  ["lforel"] = controlspec.new(0, 8, "lin", 0.1, 2, "s"),
  ["lfornode"] = controlspec.new(0, 2, "lin", 1, 1, ""),
  ["lfof"] = controlspec.new(0, 4, "lin", 0, 0, ""),
  ["lfoph"] = controlspec.new(0, 3.14, "lin", 0, 0, ""),
  ["noiseatt"] = controlspec.new(0, 4, "lin", 0.05, 1, "s"),
  ["noiserel"] = controlspec.new(0, 8, "lin", 0.1, 2, "s"),
  ["noisernode"] = controlspec.new(0, 2, "lin", 1, 1, ""),
  ["noisecut"] = controlspec.new(0.5, 127, "lin", 1, 8, ""),
  ["pitchlfo"] = controlspec.new(-0.5, 0.5, "lin", 0.01, 0, ""),
  ["durlfo"] = controlspec.new(-0.5, 0.5, "lin", 0.01, 0, ""),
  ["trigflfo"] = controlspec.new(-0.5, 0.5, "lin", 0.01, 0, ""),
  ["poslfo"] = controlspec.new(-0.5, 0.5, "lin", 0, 0.01, ""),
  ["filtlfo"] = controlspec.new(-0.5, 0.5, "lin", 0, 0.01, ""),
  ["panlfo"] = controlspec.new(-0.5, 0.5, "lin", 0, 0.01, ""),
  ["delllfo"] = controlspec.new(-0.5, 0.5, "lin", 0, 0.01, ""),
  ["delrlfo"] = controlspec.new(-0.5, 0.5, "lin", 0, 0.01, ""),
  ["pitchnoise"] = controlspec.new(-0.5, 0.5, "lin", 0.01, 0, ""),
  ["durnoise"] = controlspec.new(-0.5, 0.5, "lin", 0, 0.01, ""),
  ["trigfnoise"] = controlspec.new(-0.5, 0.5, "lin", 0.01, 0, ""),
  ["posnoise"] = controlspec.new(-0.5, 0.5, "lin", 0.01, 0, ""),
  ["filtnoise"] = controlspec.new(-0.5, 0.5, "lin", 0.01, 0, ""),
  ["pannoise"] = controlspec.new(-0.5, 0.5, "lin", 0.01, 0, ""),
  ["dellnoise"] = controlspec.new(-0.5, 0.5, "lin", 0.01, 0, ""),
  ["delrnoise"] = controlspec.new(-0.5, 0.5, "lin", 0.01, 0, ""),
  ["masterm"] = controlspec.new(0, 1, "lin", 0, 0, "")
}

local mparam_names = {"lfoatt", "lforel", "lfornode", "lfof", "lfoph", "noiseatt", "noiserel", "noisernode", "noisecut", "pitchlfo", "durlfo", "trigflfo", "poslfo", "filtlfo", "panlfo", "delllfo", "delrlfo", "pitchnoise", "durnoise", "trigfnoise", "posnoise", "filtnoise", "pannoise", "dellnoise", "delrnoise", "masterm"}

local rspecs = {
  ["rpos"] = controlspec.new(1, 8, "lin", 1, 1, ""),
  ["rlvl"] = controlspec.new(0, 1, 'lin', 0, 1, ""),
  ["plvl"] = controlspec.new(0, 4, "lin", 0.05, 1, "s"),
  ["loop"] = controlspec.new(0, 1, "lin", 1, 0, "")
}

local rparam_names = {"rpos", "rlvl", "plvl", "loop"}

-- initialize parameters:
function MPCgrain.add_params()
  
  params:add_group("MPCgrain", #param_names+1)
  params:add_separator("prog")
  for i = 1,#param_names do
    local p_name = param_names[i]
    params:add{
      type = "control",
      id = "MPCgrain_"..p_name,
      name = p_name,
      controlspec = specs[p_name],
      formatter = p_name == "pan" and Formatters.bipolar_as_pan_widget or nil,
      action = function(x) engine[p_name](x) end
    }
  end
  params:add_group("MPCgrainmod", #mparam_names+1)
  params:add_separator("modulation")
  for i = 1,#mparam_names do
    local mp_name = mparam_names[i]
    params:add{
      type = "control",
      id = "MPCgrain_"..mp_name,
      name = mp_name,
      controlspec = mspecs[mp_name],
      action = function(x) engine[mp_name](x) end
    }
  end
  params:add_group("MPCgrainrec", #rparam_names+2)
  params:add_separator("recorder")
  for i = 1,#rparam_names do
    local rp_name = rparam_names[i]
    params:add{
      type = "control",
      id = "MPCgrain_"..rp_name,
      name = rp_name,
      controlspec = rspecs[rp_name],
      action = function(x) engine[rp_name](x) end
    }
  end
  params:add_binary("MPCgrain_run", "run", "toggle",0)
  params:set_action("MPCgrain_run",function(x) if x==1 then engine.run(params:get("MPCgrain_rpos")) else engine.runOff() end end)
end

-- a single-purpose triggering command fire a note
function MPCgrain.trig(gate)
  if gate ~= nil then
    engine.gate(gate) 
  end
end 

 -- we return these engine-specific Lua functions back to the host script:
return MPCgrain
