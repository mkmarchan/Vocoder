// sinc
// normalized sinc function
//
// see: "http://en.wikipedia.org/wiki/Sinc_function".openOS
(
~sinc = { arg x;
    (x == 0).if({ 1 }, { sin(pi * x) / (pi * x) })
    }
)

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


~lowpass.value(16, 5.0, 10.0).plot





// -------------------------------------------
// Example 2
//
// kernel size = 127, 1Hz cutoff, 10Hz sampling rate
// 0.2 or 20% of the bandwidth
//
// NOTE: we'll have to zero pad the kernel for odd size
// -------------------------------------------
(
var size = 1023, freq = 30, sampleRate = 44000;
var kernel, fftResponse, fftMagnitude;
var plotDbMin = -60, plotDbMax = 3;


// generate filter kernel - lowpass
//kernel = ~highpass.value(size, freq, sampleRate);
kernel = ~bandpass.value(size, freq, 10, sampleRate);
9.do({arg i;
	var centerFreq = freq * 2.pow(i + 1);
	var bandwidth = 20 * 2.pow(i + 1);
	kernel = kernel + ~bandpass.value(size, centerFreq, bandwidth, sampleRate);
	("Center Freq " ++ centerFreq).postln;
	("Lower " ++ (bandwidth / -2 + centerFreq) ++ " Upper " ++ (bandwidth / 2 + centerFreq)).postln;

});

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