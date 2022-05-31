// CroneEngine_mpcgrain
//
// v1.0.0 
// marcocinque d('u')b

Engine_mpcgrain : CroneEngine {
  
  var padGroup;
  var padList;
  var modGroup;
  var modList;
  var recGroup;
  var recList;
  var recparams;
  var padparams;
  var modparams;
	
  var sbuff;
  var wbuff;
  var winenv;
  var buffread;
  var diskwrite;
  var diskread;
  var rec;
  var recorder;
  var grainwindow;
  
  var bpm=120;
  var step=1;
  var pitchBendRatio=0;
  var watt=0.125;
  var wrel=0.5;
	
  *new { arg context, doneCallback;
	^super.new(context, doneCallback);
  }

  alloc {
	
    sbuff = Buffer.alloc(context.server, context.server.sampleRate * 64, 1);
    
    grainwindow = {
      arg watt=0.125, wrel=0.5;
      winenv = Env([0, 1, 0], [watt, wrel], [8, -8]);
      wbuff = Buffer.sendCollection(context.server, winenv.discretize, 1);
    };
    grainwindow.value(0.125,0.5);
	  
    diskread = {
      arg pos = 0, path = "/home/we/dust/audio/tape/0011.wav", step=step, bpm=bpm;
      var bufpos = context.server.sampleRate*(60/bpm)*step*pos;
      sbuff.readChannel(path, 0, -1, bufpos, channels:[0]);
    };
       
    diskwrite = {
      arg numsamp=1, path="/home/we/dust/code/MPCgrain/data/", buf=0;
      buf.write(path ++ "MPCgrain_" ++ numsamp ++ ".wav", headerFormat: "wav", sampleFormat: "int24");
    };
    
    ~pitchmod = Bus.audio(context.server,8);
    ~durationmod = Bus.control(context.server,8);
    ~trigfreqmod = Bus.audio(context.server,8);
    ~positionmod = Bus.audio(context.server,8);
    ~filtcutmod = Bus.audio(context.server,8);
    ~panmod = Bus.control(context.server,8);
    ~delayleftmod = Bus.audio(context.server,8);
    ~delayrightmod = Bus.audio(context.server,8);

    recGroup = Group.new(context.xg);
    recList = List.new();
    padGroup = Group.new(context.xg);
    padList = List.new();
    modGroup = Group.new(context.xg);
    modList = List.new();
    

		// Synths
		
	  SynthDef(\srecorder, { arg rpos=0, rbuf=0, rstep=step, rbpm=bpm, rlvl=1, plvl=1, run=0, loop=0;
    	var input, trigger, kill;
    	input = Mix.new(SoundIn.ar(0))+Mix.new(SoundIn.ar(1));
      RecordBuf.ar(input, rbuf, (context.server.sampleRate*(60/rbpm)*rstep*(rpos-1)), rlvl, plvl, run, loop);
      kill = EnvGen.kr(envelope: Env.asr( 0, 1, 0), gate: run, doneAction: Done.freeSelf);
    }).add;
    
    SynthDef(\lfosmod, {
    	arg mpos=0, mbpm=bpm, mgate=0, mvel=0, lfoatt=0, lforel=1, lfornode=1, lfof=1, lfoph=0, noiseatt=0, noiserel=1, noisernode=1, noisecut=127,
	      masterm=0, pitchlfo=0, durlfo=0, trigflfo=0, poslfo=0, filtlfo=0, panlfo=0, delllfo=0, delrlfo=0, 
	      pitchnoise=0, durnoise=0, trigfnoise=0, posnoise=0, filtnoise=0, pannoise=0, dellnoise=0, delrnoise=0;
    	var lfoenv, noiseenv, siglfo, signoise, envlfo, envnoise;
      envlfo = Env.new([0,(mvel/127),0],[lfoatt,lforel], releaseNode: lfornode);
      envnoise = Env.new([0,(mvel/127),0],[noiseatt,noiserel], releaseNode: noisernode);
    	lfoenv = EnvGen.kr(envlfo, mgate, doneAction: Done.freeSelf);
    	noiseenv = EnvGen.kr(envnoise, mgate, doneAction: Done.freeSelf);
    	siglfo = lfoenv * (1 - (SinOsc.ar((mbpm/240)*lfof, lfoph, 0.5, 0.5)));
    	signoise = noiseenv * (1 - (TwoPole.ar(WhiteNoise.ar(1), noisecut.midicps, mul: 0.5, add: 0.5)));
    	Out.ar(~pitchmod.index + mpos, (siglfo * pitchlfo) * masterm);
    	Out.kr(~durationmod.index  + mpos, ((siglfo * durlfo) + (signoise * durnoise)) * masterm);
    	Out.ar(~trigfreqmod.index + mpos, ((siglfo * trigflfo) + (signoise * trigfnoise)) * masterm);
    	Out.ar(~positionmod.index + mpos, ((siglfo * poslfo) + (signoise * posnoise)) * masterm);
     	Out.ar(~filtcutmod.index  + mpos, ((siglfo * filtlfo) + (signoise * filtnoise)) * masterm);
    	Out.kr(~panmod.index + mpos, ((siglfo * panlfo) + (signoise * pannoise)) * masterm);
    	Out.ar(~delayleftmod.index + mpos, ((siglfo * delllfo) + (signoise * dellnoise)) * masterm);
    	Out.ar(~delayrightmod.index + mpos, ((siglfo * delrlfo) + (signoise * delrnoise)) * masterm);
   }).add;
   
   SynthDef(\grainsampler, {
    	arg buf=0, pos=0, bpm=bpm, step=step, gate=1, amp=1, vel=0, att=0.1, rel=1, rnode=1,
    	  rate=1, dur=0.5, transp=0, pitchBendRatio=0, pan=0, trgsel=0, trgfrq=8,
      	 filtcut=127, rq=1, delr=0.0225, dell=0.0127, drywet=0, envbuf=wbuff;
    	var sig, trigger, grainpos, env, tfmod, durmod, pitchmod, posmod, panmod, cutmod, delrmod, dellmod;
    	tfmod = In.ar(~trigfreqmod.index + pos);
    	durmod = In.kr(~durationmod.index + pos);
    	pitchmod = In.ar(~pitchmod.index + pos);
    	posmod = In.ar(~positionmod.index + pos);
    	panmod = In.kr(~panmod.index + pos);
    	cutmod = In.ar(~filtcutmod.index + pos);
    	delrmod = In.ar(~delayrightmod.index + pos);
      dellmod = In.ar(~delayleftmod.index + pos);
    	trigger = Select.ar(trgsel,
    		[Impulse.ar((bpm/(1.875*trgfrq)) + ((bpm/(1.875*trgfrq))*tfmod)), Dust.ar((bpm/(1.875*trgfrq)) + ((bpm/(1.875*trgfrq))*tfmod))]
	 		);
    	grainpos = Phasor.ar(0, rate*(step/8) / context.server.sampleRate, ((60/bpm)*step*(pos-1))/64, ((60/bpm)*step*pos)/64);
	    sig = GrainBuf.ar(2,
	    	trigger,
	    	(((1.875*trgfrq*step)/bpm)*dur) + (((1.875*trgfrq*step)/bpm)*dur*durmod),
	    	buf,
    		transp.midiratio + pitchmod + pitchBendRatio,
    		grainpos+(grainpos*posmod),
    		2,
	    	pan+panmod,
	    	envbuf,
	    	maxGrains: 128
	    );
    	sig = RLPF.ar(sig, Clip.kr(filtcut + (cutmod*36),0,127).midicps, rq);
    	sig = XFade2.ar(sig, DelayL.ar(sig, [(delr/1000)+((delr/1000)*delrmod), (dell/1000)+((dell/1000)*dellmod)]), drywet);
    	env = Env.new([0,amp*(vel/127),0],[att,rel], releaseNode: rnode);
    	sig = ((sig+Mix.new(SoundIn.ar(0))) * EnvGen.kr(env, gate, doneAction: Done.freeSelf));
    	Out.ar(0, sig);
   }).add;

		// Commands
		
		recparams = Dictionary.newFrom([
		  \rpos, 1,
		  \rlvl, 1, 
		  \plvl, 0, 
		  \loop, 1;
		]);

		recparams.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				recparams[key] = msg[1];
				recGroup.set(key, msg[1]);
			});
		});
		
		padparams = Dictionary.newFrom([
			\amp, 1,
			\att, 0.1, 
			\rel, 1, 
			\rnode, 1,
    	\rate, 1, 
    	\dur, 0.5, 
    	\transp, 0, 
    	\pan, 0, 
    	\trgsel, 0, 
    	\trgfrq, 8,
      \filtcut, 127, 
      \rq, 1, 
      \delr, 0.0225, 
      \dell, 0.0127, 
      \drywet, 0,
      \envbuf, wbuff;
		]);
		
		padparams.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				padparams[key] = msg[1];
				padGroup.set(key, msg[1]);
			});
		});
		
		modparams = Dictionary.newFrom([
			\lfoatt, 0, 
			\lforel, 1, 
			\lfornode, 1, 
			\noiseatt, 0, 
			\noiserel, 1, 
			\noisernode, 1, 
			\lfof, 1, 
			\lfoph, 0, 
			\noisecut, 127,
	    \pitchlfo, 0, 
	    \durlfo, 0, 
	    \trigflfo, 0, 
	    \poslfo, 0, 
	    \filtlfo, 0, 
	    \panlfo, 0, 
	    \delllfo, 0, 
	    \delrlfo, 0,
	    \pitchnoise, 0, 
	    \durnoise, 0, 
	    \trigfnoise, 0, 
	    \posnoise, 0, 
	    \filtnoise, 0, 
	    \pannoise, 0, 
	    \dellnoise, 0, 
	    \delrnoise, 0,
	    \masterm, 0;
		]);
		
		modparams.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				modparams[key] = msg[1];
				modGroup.set(key, msg[1]);
			});
		});

		// noteOn(id, note, vel)
		this.addCommand(\noteOn, "iff", { arg msg;
			var id = msg[1], note = msg[2], vel = msg[3];
			var mpc, mod;
			("playing " ++ id).postln;
			context.server.makeBundle(nil, {
		   	mpc = (id: id, theSynth: Synth.new(defName: \grainsampler, args: [
		  		\buf, sbuff, \pos, id, \gate, 1, \vel, vel, \bpm, bpm, \step, step]
		  		++ padparams.getPairs, target: padGroup).onFree({ padList.remove(mpc); }), gate: 1);
		  	padList.addFirst(mpc);
		  	mod = (id: id, theMod: Synth.new(defName: \lfosmod, args: [
		  		\mpos, id, \mgate, 1, \mvel, vel, \rbpm, bpm] ++ modparams.getPairs, target: modGroup).onFree({ modList.remove(mod); }), mgate: 1);
		  	modList.addFirst(mod);
		  });
		});

		// noteOff(id)
		this.addCommand(\noteOff, "i", { arg msg;
			var ompc = padList.detect{arg v; v.id == msg[1]};
			var omod = modList.detect{arg v; v.id == msg[1]};
			if(ompc.notNil, {
				ompc.theSynth.set(\gate, 0);
				ompc.gate = 0;
			});
			if(omod.notNil, {
				omod.theMod.set(\mgate, 0);
				omod.mgate = 0;
			});
		});

		// noteOffAll()
		this.addCommand(\noteOffAll, "", { arg msg;
			padGroup.set(\gate, 0);
			padList.do({ arg v; v.gate = 0; });
			modGroup.set(\mgate, 0);
			modList.do({ arg v; v.mgate = 0; });
		});
		
		// pitchBend(ratio)
		this.addCommand(\pitchBend, "f", { arg msg;
			pitchBendRatio = msg[1];
			padGroup.set(\pitchBendRatio, pitchBendRatio);
		});
		
		// bpm(value)
		this.addCommand(\bpm, "f", { arg msg;
			bpm = msg[1];
			padGroup.set(\bpm, bpm);
			modGroup.set(\mbpm, bpm);
			recGroup.set(\rbpm, bpm);
		});
		
		// step(value)
		this.addCommand(\step, "f", { arg msg;
			step = msg[1];
			padGroup.set(\step, step);
			recGroup.set(\rstep, step);
		});
		
		// run(id)
		this.addCommand(\run, "i", { arg msg;
		var id = msg[1];
		"sampling".postln;
    recorder = Synth.new(\srecorder, [
        \rbuf, sbuff.bufnum,
        \rstep, step,
        \rbpm, bpm,
        \rpos, id,
        \run, 1
      ] ++ recparams.getPairs, target: rec);
		});
		
		// runOff()
		this.addCommand(\runOff, "", {
		  "stop sampling".postln;
      recorder.set(\run, 0);
		});
		
		// readsamp(id, path)
		this.addCommand(\readsamp, "is", { arg msg;
			var id = msg[1], path = msg[2];
			"read".postln;
			diskread.value(id, path, step, bpm);
		});

		// writesamp(value)
		this.addCommand(\writesamp, "i", { arg msg;
			var numsamp = msg[1];
			"write".postln;
			diskwrite.value(numsamp, "/home/we/dust/code/MPCgrain/data/", sbuff);
		});

		// grainatt(value)
		this.addCommand(\grainatt, "f", { arg msg;
			watt = msg[1];
			grainwindow.value(watt,wrel);
		});
		
		// grainrel(value)
		this.addCommand(\grainrel, "f", { arg msg;
			wrel = msg[1];
			grainwindow.value(watt,wrel);
		});


	}

	free {
		padGroup.free;
		modGroup.free;
		recGroup.free;
		sbuff.close;
    sbuff.free;
	}
}
