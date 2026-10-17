"""UTF-8 JSON transport for the official Sherpa Python API on Windows."""
import json
import sys
import wave
from pathlib import Path

import numpy as np
import sherpa_onnx as sherpa


def synthesize(request):
    directory = Path(request['modelDir'])
    model = sherpa.OfflineTtsModelConfig()
    model.num_threads = 2
    model.provider = 'cpu'
    if request['family'] == 'supertonic':
        model.supertonic = sherpa.OfflineTtsSupertonicModelConfig(
            duration_predictor=str(directory / 'duration_predictor.int8.onnx'),
            text_encoder=str(directory / 'text_encoder.int8.onnx'),
            vector_estimator=str(directory / 'vector_estimator.int8.onnx'),
            vocoder=str(directory / 'vocoder.int8.onnx'),
            tts_json=str(directory / 'tts.json'),
            unicode_indexer=str(directory / 'unicode_indexer.bin'),
            voice_style=str(directory / 'voice.bin'))
    else:
        models = sorted(directory.glob('*.onnx'))
        if not models:
            raise ValueError('ONNX model missing')
        model.vits = sherpa.OfflineTtsVitsModelConfig(
            model=str(models[0]), tokens=str(directory / 'tokens.txt'),
            lexicon=str(directory / 'lexicon.txt') if (directory / 'lexicon.txt').is_file() else '',
            data_dir=str(directory / 'espeak-ng-data') if (directory / 'espeak-ng-data').is_dir() else '')
    rules = [directory / name for name in ('phone.fst', 'date.fst', 'number.fst')]
    config = sherpa.OfflineTtsConfig(model=model, rule_fsts=','.join(str(p) for p in rules if p.is_file()))
    if not config.validate():
        raise ValueError('Invalid Sherpa model configuration')
    tts = sherpa.OfflineTts(config)
    sid = request['sid']
    if not isinstance(sid, int) or sid < 0 or sid >= tts.num_speakers:
        raise ValueError('Invalid speaker ID')
    generation = sherpa.GenerationConfig()
    generation.sid = sid
    generation.extra = {'lang': request['language']}
    audio = tts.generate(request['text'], generation)
    samples = np.asarray(audio.samples)
    if samples.size == 0 or not np.isfinite(samples).all():
        raise ValueError('Invalid generated audio')
    with wave.open(request['output'], 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(audio.sample_rate)
        output.writeframes((np.clip(samples, -1, 1) * 32767).astype('<i2').tobytes())


if __name__ == '__main__':
    synthesize(json.loads(sys.stdin.buffer.read().decode('utf-8')))
