#!/usr/bin/env python3
"""Write a short royalty-free stereo bed as 48 kHz 16-bit PCM WAV."""

from __future__ import annotations

import math
import sys
import wave

import numpy as np


def render(seconds: float, sample_rate: int = 48000) -> np.ndarray:
    n = int(seconds * sample_rate)
    t = np.arange(n, dtype=np.float64) / sample_rate
    # Soft fifth + octave pad. Original generated audio, safe to upload.
    left = (
        0.18 * np.sin(2 * math.pi * 110.0 * t)
        + 0.12 * np.sin(2 * math.pi * 164.81 * t)
        + 0.07 * np.sin(2 * math.pi * 220.0 * t)
    )
    right = (
        0.16 * np.sin(2 * math.pi * 110.0 * t + 0.15)
        + 0.13 * np.sin(2 * math.pi * 164.81 * t + 0.35)
        + 0.08 * np.sin(2 * math.pi * 329.63 * t)
    )
    noise = (np.random.default_rng(8).standard_normal(n) * 0.008).astype(np.float64)
    fade = np.minimum(1.0, t / 0.6) * np.minimum(1.0, (seconds - t) / 0.8)
    fade = np.clip(fade, 0, 1)
    stereo = np.stack([(left + noise) * fade, (right + noise) * fade], axis=1)
    peak = np.max(np.abs(stereo)) or 1.0
    return (stereo / peak * 0.28).astype(np.float64)


def write_wav(path: str, seconds: float) -> None:
    audio = render(seconds)
    pcm = np.clip(audio, -1, 1)
    pcm_i16 = (pcm * 32767.0).astype(np.int16)
    with wave.open(path, "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(48000)
        wav.writeframes(pcm_i16.tobytes())


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: make_audio_bed.py <seconds> <out.wav>", file=sys.stderr)
        sys.exit(1)
    write_wav(sys.argv[2], float(sys.argv[1]))
    print(sys.argv[2])
