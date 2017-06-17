// CREDIT TO JOSEPH ANDERSON AND DANIEL PETERSON: DXARTS 462
// sinc
// normalized sinc function
//
// see: "http://en.wikipedia.org/wiki/Sinc_function".openOS
(
~sinc = { arg x;
    (x == 0).if({ 1 }, { sin(pi * x) / (pi * x) })
    }
)

// CREDIT TO JOSEPH ANDERSON AND DANIEL PETERSON: DXARTS 462
// sinc lowpass
// ideal lowpass filter kernel - rectangular window
(
~lowpass = { arg size, freq, sampleRate;
    var bandWidth;

    // compute normalised bandwidth
    bandWidth = 2 * freq / sampleRate;

    // generate kernel
    size.collect({arg n;
        bandWidth * ~sinc.value(bandWidth * (n - ((size-1)/2)))
    }).as(Signal)
}
)


(
~highpass = { arg size, freq, sampleRate;
    var bandWidth;

	~lowpass.value(size, sampleRate / 2, sampleRate) - ~lowpass.value(size, freq, sampleRate);
}
)

(
~bandpass = { arg size, centerFreq, bandwidth, sampleRate;

	~lowpass.value(size, bandwidth / 2 + centerFreq, sampleRate) - ~lowpass.value(size, bandwidth / -2 + centerFreq, sampleRate);
}
)

// CREDIT TO JOSEPH ANDERSON AND DANIEL PETERSON: DXARTS 462
// -------------------------------------------
// Example 2
//
// kernel size = 127, 1Hz cutoff, 10Hz sampling rate
// 0.2 or 20% of the bandwidth
//
// NOTE: we'll have to zero pad the kernel for odd size
// -------------------------------------------
(
var size = 1023, freq = 30, sampleRate = 44100;
var kernel, fftResponse, fftMagnitude;
var plotDbMin = -60, plotDbMax = 3;


// generate filter kernel and test that it fills out spectrum
kernel = ~lowpass.value(size, 29.223673123475, sampleRate);
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
	kernel = kernel + ~bandpass.value(size, centerFreq, bandwidth, sampleRate);
	//("Center Freq " ++ centerFreq).postln;
	("Lower " ++ (bandwidth / -2 + centerFreq) ++ " Upper " ++ (bandwidth / 2 + centerFreq)).postln;

});
kernel = kernel + ~highpass.value(size, 20938.560940961, sampleRate);

// zero pad
kernel = kernel.extend(size.nextPowerOfTwo, 0);


// FFT analysis here!
fftResponse = fft(
    kernel.as(Signal),
    Signal.newClear(kernel.size),
    Signal.fftCosTable(kernel.size)
);

// find (& trim magnitude)
fftMagnitude = fftResponse.magnitude;
fftMagnitude = fftMagnitude.copyFromStart((size/2).asInteger);


// --------------------
// display

// look at the kernel
kernel.plot(
    name: "Filter Kernel - Impulse Response",
    bounds: Rect.fromPoints(Point.new(0, 0), Point.new(400, 300))
);

// look at the magnitude spectrum of the kernel
fftMagnitude.copyFromStart((size/2).asInteger).ampdb.plot(
    name: "Filter Magnitude Response",
    bounds: Rect.fromPoints(Point.new(400, 0), Point.new(800, 300)),
    minval: plotDbMin,
    maxval: plotDbMax
);
)

