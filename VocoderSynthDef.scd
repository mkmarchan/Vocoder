(
var soundFilePath;
var sampleRate;
var kernel;

var score, synthDef;
var buffers;

var plotKernelSpectrum;
var sinc, lowpass, highpass, bandpass;

// vars for NRT output
var    outputPath, headerFormat, sampleFormat, numOutputChannels;

// set the NRT vars here...
outputPath = "".resolveRelative ++ "/testOut.wav"; // output file path
soundFilePath = "".resolveRelative ++ "/testIn.wav"; // input file path
headerFormat = "WAV";                 // soundfile header format
sampleFormat = "int24";               // soundfile sample format
numOutputChannels = 2;                // stereo --> 2 channels

// ----------------------------
// functions...
sinc = { arg x;
    (x == 0).if({ 1 }, { sin(pi * x) / (pi * x) })
}

lowpass = { arg size, freq, sampleRate;
    var bandWidth;

    // compute normalised bandwidth
    bandWidth = 2 * freq / sampleRate;

    // generate kernel
    size.collect({arg n;
        bandWidth * sinc.value(bandWidth * (n - ((size-1)/2)))
    }).as(Signal)
}

highpass = { arg size, freq, sampleRate;
    var bandWidth;

	lowpass.value(size, sampleRate / 2, sampleRate) - lowpass.value(size, freq, sampleRate);
}

bandpass = { arg size, centerFreq, bandwidth, sampleRate;

	lowpass.value(size, bandwidth / 2 + centerFreq, sampleRate) - lowpass.value(size, bandwidth / -2 + centerFreq, sampleRate);
}

//------------------------------------------
// Create kernels & throw them into buffers
size = 1023;
sampleRate = 44100;
buffers = Array.newClear(129);

kernel = lowpass.value(size, 29.223673123475, sampleRate);
buffers[0] = CtkBuffer.collection(kernel);

127.do({arg i;
	// magicValue: mv^127 - 22050 / (2mv * freq) = 22050 / (2freq)
	// since we don't care about zero:
	// 2mv^128 - 735mv = 735
	var magicValue = 1.05313;
	var centerFreq = freq * magicValue.pow(i);
	// q is calculated so that the bandwidth will result in the upper frequency being
	// halfway between the ratio of the magicValue and 1.
	var q = 2 * (2 * freq * magicValue / (magicValue + 1) - freq);
	var bandwidth = q * magicValue.pow(i);
	kernel = bandpass.value(size, centerFreq, bandwidth, sampleRate);
	//("Center Freq " ++ centerFreq).postln;
	("Lower " ++ (bandwidth / -2 + centerFreq) ++ " Upper " ++ (bandwidth / 2 + centerFreq)).postln;
	buffers[i+1] = CtkBuffer.collection(kernel);
});

kernel = highpass.value(size, 20938.560940961, sampleRate);
buffers[128] = CtkBuffer.collection(kernel);


// -------------------------------------------
// synthesis block - Filtered WhiteNoise
//
synthDef = CtkSynthDef.new(\convSynth, {arg dur, gain = 0.0, inGain = 0.0, ris = 0.1, dec = 0.1, inBuffer = 0, kernelBuffers = Array.newClear(129);

    // variables
    var bus = 0;      // var to specify output bus: first output
    var numChannels = 2; // stereo buffer
	var numFilters = 129
    var in, out;     // vars assigned to audio signals
	var inFilters = Array.newClear(numFilters);
    var amp;          // a few vars for synthesis
    var ampEnv;       // var for envelope signal

    // calcs
    amp = gain.dbamp;  // convert from gain in dB to linear amplitude scale

    // the amplitude envelope nested in the UGen that synthesises the envelope
    ampEnv = EnvGen.kr(
        Env.linen(ris, 1.0 - (ris + dec), dec),
        timeScale: dur
    );

    // filter input
	in = PlayBuf.ar(numChannels, inBuffer);
	numFilters.do({arg i;
		inFilters[i] = Convolution2.ar(in, kernelBuffers[i], framesize: kernelBuffers[i].size);
	});

	out = numFilters.sum * ampEnv;

    // out!!
    Out.ar(bus, out)
});

// create a score
score = CtkScore.new;

// add the buffers to the score
buffers.do({ arg thisBuffer;
	score.add(thisBuffer);
});
CtkBuffer.playbuf(soundFilePath).addTo(score);

// filtered white noise


// write score to sound file with the -write message
// NOTE: we're using argument names to specify the args. For 'duration', we're letting Ctk
//       do the work for us!
score.write(
    outputPath.standardizePath,
    sampleRate: s.sampleRate,
    headerFormat: headerFormat,
    sampleFormat: sampleFormat,
    options: ServerOptions.new.numOutputBusChannels_(numOutputChannels)
);
)

SFPlayer("".resolveRelative ++ "/testOut.wav".standardizePath).gui;