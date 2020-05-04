// by ixi-audio.net

// custom stereo level indicator. it can be used to monitor the input/output like s.meter but also can be used
// to monitor de signal inside a synth

s.boot;

( // monitor signal INSIDE a synth
var levels=List.new, monitor, oscF;

// the synth
SynthDef(\monitor, {|in=2, out=0|
	var insignal, outsignal, imp, delimp;

	imp = Impulse.kr(10);
	delimp = Delay1.kr(imp);

	insignal = In.ar(in, 2);

	// process the sound. for instance blow the output
	outsignal = insignal * 3;

	SendPeakRMS.kr(insignal++outsignal, 10, 3, '/levels'); // sends an array like [1,1,1,1]

	//Out.ar(out, outsignal); // optional
}).send;

monitor = Synth(\monitor); //

// responder
oscF = OSCFunc({|msg| {
	levels.do({|lvl, i|
		var values =  msg[3..]; // get just the actual PeakRMS values
		lvl.peakLevel = values[i*2].ampdb.linlin(-80, 0, 0, 1, \min);
		lvl.value = values[(i*2)+1].ampdb.linlin(-80, 0, 0, 1);
	});
}.defer;
}, '/levels', s.addr);

// GUI
w = Window.new("asd", Rect(100,100, 210, 100)).alwaysOnTop=true;
w.view.decorator = FlowLayout(w.view.bounds);
w.view.decorator.gap=2@2;
w.onClose_({ oscF.free; monitor.free });

v = VLayoutView(w, 200@22); // size
4.do{|i|
	levels.add( LevelIndicator(v, 5).warning_(0.9).critical_(1.0).drawsPeak_(true) ); // 5 the height
	if (i==1, {CompositeView(v, 2)}); // 2px separator
};

w.front
)







// Monitor the output signal like s.meter
/* if you want to monitor the signal that goes out of supercollider, instead of the signal at a particular point in a synth, you need to create a separated synth for the input and the output and have separated OSC responders. The output monitor synth must be added to tail, as far as I undestand

The code is not very good because everything it is duplicate but it is intended to show how to do it.
*/
(
var inlevels=List.new, outlevels=List.new, outF, inF, insynth, outsynth;

{SinOsc.ar(444, 0, 0.2)}.play; // just play something

SynthDef(\inmon, {|in=0|
	SendPeakRMS.kr(In.ar(in, 2), 10, 3, '/inlvl');
}).send;

SynthDef(\outmon, {|out=2|
	SendPeakRMS.kr(In.ar(out, 2), 10, 3, '/outlvl'); // catch the audio output in the very last point
}).send;

insynth = Synth.head(s, \inmon);
outsynth = Synth.tail(s, \outmon);

outF = OSCFunc({|msg| {
	outlevels.do({|lvl, i| // ONLY out levels
		var values =  msg[3..];
		lvl.peakLevel = values[0].ampdb.linlin(-80, 0, 0, 1, \min);
		lvl.value = values[1].ampdb.linlin(-80, 0, 0, 1);
	});
}.defer;
}, '/outlvl', s.addr);

inF = OSCFunc({|msg| {
	inlevels.do({|lvl, i| // ONLY in levels
		var values =  msg[3..];
		lvl.peakLevel = values[0].ampdb.linlin(-80, 0, 0, 1, \min);
		lvl.value = values[1].ampdb.linlin(-80, 0, 0, 1);
	});
}.defer;
}, '/inlvl', s.addr);

w = Window.new("asd", Rect(100,100, 210, 100)).alwaysOnTop=true;
w.view.decorator = FlowLayout(w.view.bounds);
w.view.decorator.gap=2@2;
w.onClose_({ outF.free; inF.free; inlevels.free; outlevels.free });

v = VLayoutView(w, 200@22); // size
inlevels.add( LevelIndicator(v, 5).warning_(0.9).critical_(1.0).drawsPeak_(true) ); // 5 the height
inlevels.add( LevelIndicator(v, 5).warning_(0.9).critical_(1.0).drawsPeak_(true) ); // 5 the height
CompositeView(v, 1); // 1px separator
outlevels.add( LevelIndicator(v, 5).warning_(0.9).critical_(1.0).drawsPeak_(true) ); // 5 the height
outlevels.add( LevelIndicator(v, 5).warning_(0.9).critical_(1.0).drawsPeak_(true) ); // 5 the height

w.front
)















