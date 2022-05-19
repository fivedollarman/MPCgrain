local MPCgrain = {}
local Formatters = require 'formatters'

-- ranges
local specs = {
  ["step"] = controlspec.new(1, 128, "lin", 1, 1, ""),
  ["amp"] = controlspec.new(0, 1, 'lin', 0, 1, ""),
  ["att"] = controlspec.new(0, 4, "lin", 0.05, 0, "s"),
  ["rel"] = controlspec.new(0, 8, "lin", 0.1, 1, "s"),
  ["rnode"] = controlspec.new(0, 2, "lin", 1, 1, ""),
  ["trgsel"] = controlspec.new(0, 1, "lin", 1, 0, ""),
  ["trgfrq"] = controlspec.new(1, 128, "lin", 1, 16, ""),
  ["rate"] = controlspec.new(0, 1, "lin", 0, 1, ""),
  ["dur"] = controlspec.new(0, 2, "lin", 0.02, 1, ""),
  ["transp"] = controlspec.new(-36, 36, "lin", 0, 0, ""),
  ["filtcut"] = controlspec.new(12, 139, "lin", 1, 127, ""),
  ["rq"] = controlspec.new(1, 0, "lin", 0, 0, ""),
  ["delr"] = controlspec.new(0, 127, "lin", 1, 0, "ms"),
  ["dell"] = controlspec.new(0, 127, "lin", 1, 0, "ms"),
  ["drywet"] = controlspec.new(0, 1, "lin", 0, 0, ""),
  ["pan"] = controlspec.PAN
}

local param_names = {"step", "amp", "att", "rel", "rnode", "trgsel", "trgfrq", "rate", "dur", "transp", "filtcut", "rq", "delr", "dell", "drywet", "pan"}

local mspecs = {
  ["mamp"] = controlspec.new(0, 1, 'lin', 0, 1, ""),
  ["matt"] = controlspec.new(0, 4, "lin", 0.05, 1, "s"),
  ["mrel"] = controlspec.new(0, 8, "lin", 0.1, 2, "s"),
  ["mrnode"] = controlspec.new(0, 2, "lin", 1, 1, ""),
  ["lfof"] = controlspec.new(0, 4, "lin", 0, 0, ""),
  ["lfoph"] = controlspec.new(0, 3.14, "lin", 0, 0, ""),
  ["lfofq"] = controlspec.new(0, 1, "exp", 0, 0, ""),
  ["noiseq"] = controlspec.new(0, 2, "exp", 0, 0, ""),
  ["mfiltcut"] = controlspec.new(1, 128, "lin", 1, 1, ""),
  ["pitchmod"] = controlspec.new(0, 1, "lin", 0, 1, ""),
  ["durmod"] = controlspec.new(0, 1, "lin", 0, 1, ""),
  ["trigftmod"] = controlspec.new(0, 1, "lin", 0, 1, ""),
  ["posmod"] = controlspec.new(0, 1, "lin", 0, 1, ""),
  ["filtmod"] = controlspec.new(0, 1, "lin", 0, 1, ""),
  ["panmod"] = controlspec.new(0, 1, "lin", 0, 1, ""),
  ["dellmod"] = controlspec.new(0, 1, "lin", 0, 1, ""),
  ["delrmod"] = controlspec.new(0, 1, "lin", 0, 1, ""),
  ["masterm"] = controlspec.new(0, 1, "lin", 0, 1, "")
}

local mparam_names = {"mamp", "matt", "mrel", "mrnode", "lfof", "lfoph", "lfoq", "noiseq", "mfiltcut", "pitchmod", "durmod", "trigfmod", "posmod", "filtmod", "panmod", "dellmod", "delrmod", "masterm"}

local rspecs = {
  ["run"] = controlspec.new(0, 1, "lin", 1, 0, ""),
  ["rpos"] = controlspec.new(1, 8, "lin", 1, 1, ""),
  ["rlvl"] = controlspec.new(0, 1, 'lin', 0, 1, ""),
  ["plvl"] = controlspec.new(0, 4, "lin", 0.05, 1, "s"),
  ["loop"] = controlspec.new(0, 1, "lin", 1, 0, ""),
  ["mode"] = controlspec.new(0, 1, "lin", 1, 0, "")
}

local rparam_names = {"run", "rpos", "rlvl", "plvl", "loop", "mode"}

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
  params:add_group("MPCgrainrec", #rparam_names+1)
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
end

-- a single-purpose triggering command fire a note
function MPCgrain.trig(gate)
  if gate ~= nil then
    engine.gate(gate) 
  end
end 

 -- we return these engine-specific Lua functions back to the host script:
return MPCgrain
