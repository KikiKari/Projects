"use strict";
const assert = require("node:assert/strict");
const { spawnSync } = require("node:child_process");
const { createPeakLimiter } = require("../browser-extension/content-core.js");
const executable = process.argv[2];
assert.ok(executable, "Pass compiled mobile/shared/native/limiter_trace.c executable");
let cases = 0;
for (const rate of [44100, 48000, 96000]) {
  for (const channels of [1, 2, 6]) {
    for (const [enabled, strength] of [[false, 100], [true, 25], [true, 75], [true, 100]]) {
      const frames = Math.round(rate * 0.25);
      const input = Array.from({ length: channels }, (_, c) => Float32Array.from({ length: frames }, (_, i) => {
        if (i === 5 || i === 129) return c % 2 ? -0.95 : 0.95;
        if (i === 300) return NaN;
        if (i === 301) return Infinity;
        return (c + 1) / channels * Math.sin(i * 2 * Math.PI * (i < 2000 ? 8000 : 220) / rate) * (i < 2000 ? 0.9 : 0.01);
      }));
      const kernel = createPeakLimiter(rate);
      const count = frames + kernel.delaySamples;
      const wire = Buffer.alloc(count * channels * 4);
      for (let i = 0; i < count; i++) for (let c = 0; c < channels; c++) wire.writeFloatLE(input[c][i] ?? 0, (i * channels + c) * 4);
      const rendered = spawnSync(executable, [rate, channels, +enabled, strength].map(String), { input: wire, maxBuffer: wire.length + 1024 });
      assert.equal(rendered.status, 0, rendered.stderr?.toString());
      assert.equal(rendered.stdout.length, wire.length);
      let maxError = 0;
      for (let start = 0; start < count; start += 127) {
        const size = Math.min(127, count - start);
        const block = input.map(channel => Float32Array.from({ length: size }, (_, i) => channel[start + i] ?? 0));
        const output = input.map(() => new Float32Array(size));
        kernel.process(block, output, enabled, strength);
        for (let i = 0; i < size; i++) for (let c = 0; c < channels; c++) {
          const actual = rendered.stdout.readFloatLE(((start + i) * channels + c) * 4);
          assert.ok(Number.isFinite(actual));
          maxError = Math.max(maxError, Math.abs(actual - output[c][i]));
        }
      }
      assert.ok(maxError <= 1e-7, `${rate}/${channels}/${enabled}/${strength}: ${maxError}`);
      cases++;
    }
  }
}
console.log(`${cases} native/JavaScript PCM equivalence cases passed (error <= 1e-7).`);
