# MPCgrain
granular Music Production Center

# requirements
norns, MIDI

# documentation
enc 1 -> change pages (MIDI, tracks, samples, program, modulations, files)<br>
enc 2 -> select value <br>
enc 3 -> change value <br>

<b>midi page</b> | btn 2 -> shuffle note/pad assignments | btn 3 -> reset assignments<br>
<br>
parameters:
<ul>
  <li>bpm: general bpm for sync functions</li>
  <li>midi_ch: MPCgrain MIDI receive channel</li>
  <li>in_device: norns input device number</li>
  <li>out_device: norns output device number for passthrough and tracks midi looper</li>
  <li>bend_rng: MPCgrain's pitchbend range</li>
  <li>note_1 to note_8: pads MIDI notes</li>
</ul>

<b>trcks page</b> | btn 2 -> record MIDI input on selected track, with synced stop | btn 3 -> play MIDI recording on selected track<br>
<br>
parameters:
<ul>
  <li>sel: select track (1, 2, 3)</li>
  <li>num: synced stop recording numerator</li>
  <li>den: synced stop recording denominator</li>
</ul>

<b>wtables page</b><br>
The synth use envelopes to interpolate between the eight waves you choose in this page, in the square you can set in order oscillator 1 interpolation start and end and oscillator 2 interpolation start and end.
You can add your own waves, they have to be .wav audiofiles made by 512 samples and have to be placed in “wavetables” folder.

<b>envelopes page</b><br>
There are 4 envelopes, one controls amplitude and filter cut, other two navigate through the wavetable and the fourth is a crossfade control between the two waves.
In the first line with enc 2 you can choose the envelope to show and edit, with enc 3 you can activate or deactivate editing. Every change in parameters will update the values of the active envelopes (the bright ones), it’s done for fast editing with so many parameters.
At the end you can choose with enc 2 and 3 the loop and release points.

<b>modulation page</b><br>
Here we have 6 oscillators detune, similar to supersaw… superwave. The “nF” parameters set the frequency for random amplitude lfos and “/” set the destination amplitude modulation, it may point to table interpolation, crossfading or detune. There’s a lowpass resonant filter too. Just listen what happen and enjoy.

# installation
Install from Matron: <code>;install https://github.com/fivedollarman/bidiwave</code>

