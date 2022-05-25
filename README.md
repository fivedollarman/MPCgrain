# MPCgrain
granular Music Production Center

# requirements
norns, MIDI

# documentation
enc 1 -> change pages (MIDI, tracks, samples, program, modulations, files)<br>
enc 2 -> select value <br>
enc 3 -> change value <br>
<br><br>

<b>midi page</b> | btn 2 -> shuffle note/pad assignments | btn 3 -> reset assignments<br>
<ul>
  <li>bpm: general bpm for sync functions</li>
  <li>midi_ch: MPCgrain MIDI receive channel</li>
  <li>in_device: norns input device number</li>
  <li>out_device: norns output device number for passthrough and tracks midi looper</li>
  <li>bend_rng: MPCgrain's pitchbend range</li>
  <li>note_1 to note_8: pads MIDI notes</li>
</ul>
<br>

<b>trcks page</b> | btn 2 -> record MIDI input on selected track, with synced stop | btn 3 -> play MIDI recording on selected track<br>
<i>you can just use this page as a three track MIDI looper</i>
<br>
<ul>
  <li>sel: select track (1, 2, 3)</li>
  <li>num: synced stop recording numerator</li>
  <li>den: synced stop recording denominator</li>
</ul>
<br>

<b>sampl page</b> | btn 2 -> record audio input starting from selected buffer position (1 to 8) | btn 3 -> play buffer starting from buffer position<br>
<i>The MPCgrain audio buffer is max 64 seconds long and it's divided in 8 sync slices assigned to 8 pads</i>
<br>
<ul>
  <li>rpos: recording position, the buffer is divided in 8 slices/positions synced to bpm and assigned to the eight pads</li>
  <li>rlvl: audio input recording level</li>
  <li>plvl: overdub recording level</li>
  <li>loop: loop recording</li>
</ul>
<br>

<b>prog page</b> | btn 2 -> randomize parameters | btn 3 -> restore preset<br>
<i>The granular sampler paramaters</i>
<ul>
  <li>step: slice duration in quarter notes</li>
  <li>amp: amplitude</li>
  <li>att: evelope attack</li>
  <li>rel: envelope release</li>
  <li>rnode: envelope release point, 1 for normal sustain</li>
  <li>grainatt: single grain attack</li>
  <li>grainrel: single grain release</li>
  <li>trgsel: grain trigger selector (impulse or dust)</li>
  <li>trgfrq: grain trigger synced frequency</li>
  <li>rate: grains' buffer read rate</li>
  <li>dur: grains duration</li>
  <li>transp: single grain note transpose</li>
  <li>filtcut: filter cutoff</li>
  <li>rq: filter resonance</li>
  <li>delr: delay of right channel in ms</li>
  <li>dell: delay of left channel in ms</li>
  <li>drywet: fade from dry singnal to delayed signal</li>
  <li>pan</li>
</ul>
<br>

# installation
Install from Matron: <code>;install https://github.com/fivedollarman/bidiwave</code>

