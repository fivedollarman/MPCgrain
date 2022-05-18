// CroneEngine_mpcgrain
//
// v1.0.0 
// marcocinque d('u')b

Engine_mpcgrain : CroneEngine {

  classvar maxNumVoices = 8;
  
  var padGroup;
  var padList;
  var modGroup;
  var modList;
  var recGroup;
  var recList;
  var recparams;
  var padparams;
  var modparams;
	
  var buff;
  var buffread;
  var diskwrite;
  var diskread;
  
  var bpm=120;
  var step=1;
  var pitchBendRatio = 1;
	
  *new { arg context, doneCallback;
	^super.new(context, doneCallback);
  }

  alloc {
	
    buff = Buffer.alloc(context.server, 48000 * 128, 1);
	  
    buffread = {
      arg path = "data/reallinn.wav", pos = 0, step=1, bpm = 120;
      var bufpos = 48000*((240/bpm)*(1/step)*pos);
      buff.read(path, 0, -1, bufpos);
    };
       
    diskwrite = {
      buff.write(thisProcess.platform.recordingsDir +/+ "mpcgrain_" ++ Date.localtime.stamp ++ ".wav", sampleFormat: 'int24');
    };
    diskread = {
	    arg path="path";
	    buff.read(path);
    };
    
    ~pitchmod = Bus.audio(context.server,8);
    ~durationmod = Bus.audio(context.server,8);
    ~trigfreqmod = Bus.audio(context.server,8);
    ~positionmod = Bus.audio(context.server,8);
    ~filtcutmod = Bus.audio(context.server,8);
    ~panmod = Bus.audio(context.server,8);
    ~delayleftmod = Bus.audio(context.server,8);
    ~delayrightmod = Bus.audio(context.server,8);

    recGroup = Group.new(context.xg);
    recList = List.new();
    padGroup = Group.new(context.xg);
    padList = List.new();
    modGroup = Group.new(context.xg);
    modList = List.new();
    

		// Synths
		
	  SynthDef(\recorder, { arg rpos=0, rstep=step, rbpm = bpm, rlvl=1, plvl=0, run=1, loop=1, mode=1, da=2;
    	var input, runa, trigger;
    	input = SoundIn.ar(0)*10000;
    	runa = Select(loop, [LFPulse.ar(1/((240/rbpm)*(1/rstep))), run]);
    	trigger = Select(mode, [Impulse.ar(1/((240/rbpm)*(1/rstep))), Impulse.ar(1/((240/rbpm)*(8/rstep)))]);
      RecordBuf.ar(input, buff, 48000*((240/rbpm)*(1/rstep)*rpos), rlvl, plvl, run*runa, loop, trigger, da);
    }).add;
    
    SynthDef(\lfosmod, {
    	arg mpos=0, mbpm=bpm, mgate=0, mvel=0, mamp=1, matt=0, mrel=1, mrnode=1, lfof=1, lfoph=0, lfoq=1, noiseq=0.5, mfiltcut=127,
	      mastermod=0, pitchmod=0, durmod=0, trigfmod=0, posmod=0, filtmod=0, panmod=0, dellmod=0, delrmod=0;
    	var sig, env;
      env = Env.new([0,mamp*(mvel/127),0],[matt,mrel], releaseNode: mrnode);
    	sig = EnvGen.kr(env, mgate, doneAction: Done.freeSelf);
    	sig = sig * (1 - (SinOsc.ar((mbpm/240)*lfof, lfoph, 0.5, 0.5) * lfoq));
    	sig = sig * (1 - (TwoPole.ar(WhiteNoise.ar(1), mfiltcut.midicps) * noiseq));
    	Out.ar(~pitchmod.index + mpos, sig * pitchmod * mastermod);
    	Out.ar(~durationmod.index  + mpos, sig * durmod * mastermod);
    	Out.ar(~trigfreqmod.index + mpos, sig * trigfmod * mastermod);
    	Out.ar(~positionmod.index + mpos, sig * posmod * mastermod);
     	Out.ar(~filtcutmod.index  + mpos, sig * filtmod * mastermod);
    	Out.ar(~panmod.index + mpos, sig * panmod * mastermod);
    	Out.ar(~delayleftmod.index + mpos, sig * dellmod * mastermod);
    	Out.ar(~delayrightmod.index + mpos, sig * delrmod * mastermod);
   }).add;
   
   SynthDef(\grainsampler, {
    	arg buf=buff, pos=0, bpm=bpm, step=step, gate=1, amp=1, vel=0, att=0.1, rel=1, rnode=1,
    	  rate=1, dur=0.5, transp=0, pitchBendRatio=0, pan=0, trgsel=0, trgfrq=8,
      	 filtcut=127, rq=1, delr=0.0225, dell=0.0127, drywet=0;
    	var sig, trigger, grainpos, env, tfmod, durmod, pitchmod, posmod, panmod, cutmod, delrmod, dellmod;
    	tfmod = In.ar(~trigfreqmod.index + pos);
    	durmod = In.ar(~durationmod.index + pos);
    	pitchmod = In.ar(~pitchmod.index + pos);
    	posmod = In.ar(~positionmod.index + pos);
    	panmod = In.ar(~panmod.index + pos);
    	cutmod = In.ar(~filtcutmod.index + pos);
    	delrmod = In.ar(~delayrightmod.index + pos);
      dellmod = In.ar(~delayleftmod.index + pos);
    	trigger = Select.ar(trgsel,
    		[Impulse.ar((bpm/(1.875*trgfrq)) + ((bpm/(1.875*trgfrq))*tfmod)), Dust.ar((bpm/(1.875*trgfrq)) + ((bpm/(1.875*trgfrq))*tfmod))]
	 		);
    	grainpos = Phasor.ar(
	    	0,
	    	(bpm/60)*(1/step),
	    	(((60/bpm)*step*pos)/128) + ((((60/bpm)*step)/128)*posmod),
	    	(((60/bpm)*step*(pos+1)*rate)/128) + ((((60/bpm)*step)/128)*posmod)
    	);
	    sig = GrainBuf.ar(2,
	    	trigger,
	    	((bpm/(1.875*trgfrq))*dur) + ((bpm/(1.875*trgfrq))*dur*durmod),
	    	buf,
    		transp.midiratio + pitchmod.midiratio + pitchBendRatio,
    		grainpos+(grainpos*posmod),
    		2,
	    	pan+panmod,
	    	maxGrains: 64
	    );
    	sig = RLPF.ar(sig, filtcut.midicps + cutmod.midicps, rq);
    	sig = XFade2.ar(sig, DelayL.ar(sig, [(delr/1000)+((delr/1000)*delrmod), (dell/1000)+((dell/1000)*dellmod)]), drywet);
    	env = Env.new([0,amp*(vel/127),0],[att,rel], releaseNode: rnode);
    	sig = sig * EnvGen.kr(env, gate, doneAction: Done.freeSelf);
    	Out.ar(0, sig);
   }).add;
   

		// Commands
		
		recparams = Dictionary.newFrom([
		  \rpos, 0, 
		  \rlvl, 1, 
		  \plvl, 0, 
		  \run, 1, 
		  \loop, 1, 
		  \mode, 1, 
		  \da, 2;
		]);

		recparams.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				recparams[key] = msg[1];
				recGroup.set(key, msg[1]);
			});
		});
		
		padparams = Dictionary.newFrom([
			\gate, 0,
			\vel, 0,
			\pos, 0,
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
      \drywet, 0;
		]);
		
		padparams.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				padparams[key] = msg[1];
				padGroup.set(key, msg[1]);
			});
		});
		
		modparams = Dictionary.newFrom([
			\mgate, 0,
			\mvel, 0,
			\mpos, 0,
			\mamp, 1, 
			\matt, 0, 
			\mrel, 1, 
			\mrnode, 1, 
			\lfof, 1, 
			\lfoph, 0, 
			\lfoq, 1, 
			\noiseq, 0.5, 
			\mfiltcut, 127,
	    \mastermod, 0, 
	    \pitchmod, 0, 
	    \durmod, 0, 
	    \trigfmod, 0, 
	    \posmod, 0, 
	    \filtmod, 0, 
	    \panmod, 0, 
	    \dellmod, 0, 
	    \delrmod, 0;
		]);
		
		modparams.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				modparams[key] = msg[1];
				modGroup.set(key, msg[1]);
			});
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
		
		// record(id, run)
		this.addCommand(\record, "if", { arg msg;
			var id = msg[1], run = msg[2];
			var rec;
			context.server.makeBundle(nil, {
		   	rec = (id: id, theSynth: Synth.new(defName: \recorder, args: [
		  		\rpos, id, \run, run, \rbpm, bpm, \rstep, step]
		  		++ recparams.getPairs, target: recGroup));
		  });
		});

		// noteOn(id, note, vel)
		this.addCommand(\noteOn, "iff", { arg msg;
			var id = msg[1], note = msg[2], vel = msg[3];
			var mpc, mod;
			context.server.makeBundle(nil, {
		   	mpc = (id: id, theSynth: Synth.new(defName: \grainsampler, args: [
		  		\buf, buff, \gate, 1, \vel, vel, \bpm, bpm, \step, step]
		  		++ padparams.getPairs, target: padGroup));
		  	mod = (id: id, theSynth: Synth.new(defName: \lfosmod, args: [
		  		\gate, 1, \mvel, vel, \rbpm, bpm] ++ modparams.getPairs, target: modGroup));
		  });
		});

		// noteOff(id)
		this.addCommand(\noteOff, "i", { arg msg;
			var pad = padList.detect{arg v; v.id == msg[1]};
			var mod = modList.detect{arg v; v.id == msg[1]};
			if(pad.notNil, {
				pad.theSynth.set(\gate, 0);
				pad.gate = 0;
			});
			if(mod.notNil, {
				mod.theSynth.set(\mgate, 0);
				mod.mgate = 0;
			});
		});

		// noteOffAll()
		this.addCommand(\noteOffAll, "", { arg msg;
			padGroup.set(\gate, 0);
			padList.do({ arg v; v.gate = 0; });
			modGroup.set(\gate, 0);
			modList.do({ arg v; v.gate = 0; });
		});
		
		// pitchBend(ratio)
		this.addCommand(\pitchBend, "f", { arg msg;
			pitchBendRatio = msg[1];
			padGroup.set(\pitchBendRatio, pitchBendRatio);
		});

	}

	free {
		padGroup.free;
		modGroup.free;
		buff.close;
    buff.free;
	}
}
