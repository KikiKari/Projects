"use strict";
const assert = require("node:assert/strict");
const test = require("node:test");
const { createPeakLimiter, limiterStrengthToDbfs } = require("../browser-extension/content-core.js");

function render(signal, strength, rate = 48000, enabled = true) {
  const kernel = createPeakLimiter(rate);
  const output = signal.map(channel => new Float32Array(channel.length + kernel.delaySamples));
  for (let start = 0; start < output[0].length; start += 128) {
    const length = Math.min(128, output[0].length - start);
    const input = signal.map(channel => Float32Array.from({ length }, (_, i) => channel[start + i] || 0));
    kernel.process(input, output.map(channel => channel.subarray(start, start + length)), enabled, strength);
  }
  return { output, delay: kernel.delaySamples };
}
const peak = channel => channel.reduce((result, value) => Math.max(result, Math.abs(value)), 0);

for (const rate of [44100, 48000, 96000]) {
  test(`isolated and high-frequency peaks are bounded at ${rate} Hz`, () => {
    const signal = new Float32Array(rate);
    signal[1] = 1;
    signal[127] = -1;
    for (let i = 1000; i < 1100; i++) signal[i] = Math.sin(2 * Math.PI * 8000 * i / rate);
    let previous = 1;
    for (const strength of [25, 75, 100]) {
      const { output, delay } = render([signal], strength, rate);
      const measured = peak(output[0]);
      const ceiling = 10 ** (limiterStrengthToDbfs(strength) / 20);
      assert.ok(measured <= ceiling + 1e-7, `${measured} exceeds ${ceiling}`);
      assert.ok(measured < previous, "higher strength must attenuate more");
      assert.ok(delay / rate <= 0.01);
      previous = measured;
    }
  });
}

test("bypass preserves every sample with the documented delay", () => {
  const signal = Float32Array.from({ length: 10000 }, (_, i) => Math.sin(i * 0.7) * 0.8);
  const { output, delay } = render([signal], 100, 48000, false);
  assert.deepEqual(output[0].slice(delay), signal);
});

test("quiet speech-band signal is not permanently attenuated", () => {
  const signal = Float32Array.from({ length: 48000 }, (_, i) => 0.01 * Math.sin(i * 2 * Math.PI * 200 / 48000));
  const { output, delay } = render([signal], 100);
  assert.deepEqual(output[0].slice(delay), signal);
});

test("linked stereo gain preserves balance and limits either channel", () => {
  const left = new Float32Array(1000); left[127] = 0.5;
  const right = new Float32Array(1000); right[127] = 1;
  const { output, delay } = render([left, right], 100);
  assert.equal(output[0][127 + delay] * 2, output[1][127 + delay]);
  assert.ok(peak(output[1]) <= 10 ** (-30 / 20) + 1e-7);
});

test("gain recovers after a transient and invalid samples cannot poison the graph", () => {
  const signal = new Float32Array(48000); signal[10] = 1;
  signal[100] = NaN; signal[200] = Infinity;
  for (let i = 24000; i < signal.length; i++) signal[i] = 0.01;
  const { output } = render([signal], 100);
  assert.ok(output[0].every(Number.isFinite));
  assert.ok(output[0][40000] > 0.00999);
});

test("empty input drains delayed audio and then returns to silence", () => {
  const kernel = createPeakLimiter(48000);
  const block = new Float32Array(128).fill(0.01);
  const out = new Float32Array(128);
  kernel.process([block], [out], true, 100);
  for (let n = 0; n < 4; n++) kernel.process([], [out], true, 100);
  assert.equal(peak(out), 0);
});
