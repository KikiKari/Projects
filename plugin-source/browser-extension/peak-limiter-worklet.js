import "./content-core.js";
const { createPeakLimiter } = globalThis.TLC_CONTENT_CORE;
class TLCPeakLimiter extends AudioWorkletProcessor {
        static get parameterDescriptors() {
          return [
            { name: 'enabled', defaultValue: 0, minValue: 0, maxValue: 1, automationRate: 'k-rate' },
            { name: 'strength', defaultValue: 30, minValue: 0, maxValue: 100, automationRate: 'k-rate' }
          ];
        }
        constructor() {
          super(); this.kernel = createPeakLimiter(sampleRate);
          this.enabled = false; this.strength = 30; this.frames = 0;
          this.inputPeakDbfs = -100; this.outputPeakDbfs = -100; this.reductionDb = 0;
        }
        process(inputs, outputs, parameters) {
          const report = this.kernel.process(inputs[0] || [], outputs[0], parameters.enabled[0] >= 0.5, parameters.strength[0]);
          this.inputPeakDbfs = Math.max(this.inputPeakDbfs, report.inputPeakDbfs);
          this.outputPeakDbfs = Math.max(this.outputPeakDbfs, report.outputPeakDbfs);
          this.reductionDb = Math.max(this.reductionDb, report.reductionDb);
          this.frames += outputs[0][0]?.length || 0;
          if (this.frames >= sampleRate / 10) {
            this.port.postMessage({ ...report, inputPeakDbfs: this.inputPeakDbfs,
              outputPeakDbfs: this.outputPeakDbfs, reductionDb: this.reductionDb });
            this.frames = 0; this.inputPeakDbfs = -100; this.outputPeakDbfs = -100; this.reductionDb = 0;
          }
          return true;
        }
      }
      registerProcessor('tlc-peak-limiter', TLCPeakLimiter);
