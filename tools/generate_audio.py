"""Reproducible original game audio. No recordings, samples, or external music.

Requires NumPy. Run from any directory; writes only assets/audio in this repo.
"""
from pathlib import Path
import hashlib
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
RATE = 22050
manifest = []


def tone(note, seconds, kind='pad'):
    t = np.arange(round(seconds * RATE)) / RATE
    f = 440 * 2 ** ((note - 69) / 12)
    if kind == 'pad':
        signal = np.sin(2*np.pi*f*t) + .22*np.sin(2*np.pi*f*2*t)
        envelope = np.sin(np.pi*t/seconds) ** 2
    else:
        signal = np.sin(2*np.pi*f*t) + .28*np.sin(2*np.pi*f*3*t)*np.exp(-4*t)
        envelope = (1-np.exp(-t*80))*np.exp(-t*2.3)
        envelope *= np.minimum(1, (seconds-t)/.08)
    return signal * envelope


def add(track, sound, when, gain=1, pan=0, wrap=True):
    indices = np.arange(len(sound)) + round(when*RATE)
    if not wrap:
        sound = sound[indices < len(track)]
        indices = indices[indices < len(track)]
    indices %= len(track)
    np.add.at(track[:, 0], indices, sound*gain*np.sqrt((1-pan)/2))
    np.add.at(track[:, 1], indices, sound*gain*np.sqrt((1+pan)/2))


def save(name, signal, peak):
    signal *= peak / max(float(np.max(np.abs(signal))), 1e-9)
    pcm = np.round(signal*32767).astype('<i2')
    path = ROOT / (name+'.wav')
    with wave.open(str(path), 'wb') as out:
        out.setnchannels(2)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(pcm.tobytes())
    manifest.append({'file': path.name, 'seconds': len(signal)/RATE,
                     'peak': round(float(np.max(np.abs(signal))), 4),
                     'rms': round(float(np.sqrt(np.mean(signal**2))), 4),
                     'boundary_step': round(float(np.max(np.abs(signal[-1]-signal[0]))), 6),
                     'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})


ROOT.mkdir(parents=True, exist_ok=True)
# 48-second circular arrangements. Notes and their echo tails wrap across the
# boundary, preserving ambience without a fade-to-silence at every loop.
for name in ['menu', 'investigation', 'accusation']:
    track = np.zeros((48*RATE, 2))
    chords = [(38,45,53), (34,41,48), (41,48,55), (36,43,50)]
    for bar, chord in enumerate(chords):
        for voice, note in enumerate(chord):
            add(track, tone(note, 18), bar*12-3, .18, (voice-1)*.45)
    if name == 'menu':
        melody = [(1,74),(4,69),(7,77),(10,76),(15,65),(19,72),
                  (25,69),(28,79),(32,77),(37,74),(41,69),(45,72)]
    elif name == 'investigation':
        melody = [(3,74),(14,65),(27,72),(39,69)]
    else:
        melody = [(i*3+1, [62,69,65,70][i % 4]) for i in range(16)]
    for i, (when, note) in enumerate(melody):
        sound = tone(note, 5, 'bell')
        for delay, gain in [(0,.16),(.41,.055),(.83,.025)]:
            add(track, sound, when+delay, gain, (-1)**i*.35)
    save(name, track, .22 if name == 'investigation' else .27)

effects = {
    'click': (.12, [(0,79,.1)]),
    'shortlist': (.55, [(0,67,.25),(.12,74,.35)]),
    'message': (.45, [(0,76,.18),(.09,81,.25)]),
    'scan': (.8, [(i*.09, 62+i*2, .16) for i in range(7)]),
    'analyzed': (.75, [(0,69,.25),(.14,76,.3),(.29,81,.4)]),
    'evidence': (.25, [(0,48,.12),(.08,60,.13)]),
    'success': (3.5, [(0,50,2),(.24,57,2),(.48,62,2),(.8,69,2.5)]),
    'failure': (3.5, [(0,50,2.8),(.3,53,2.6),(.7,45,2.5)]),
}
for name, (length, notes) in effects.items():
    track = np.zeros((round(length*RATE),2))
    for when, note, duration in notes:
        add(track, tone(note,duration,'bell'),when,.3,wrap=False)
    save(name, track, .25 if name in ['success','failure'] else .18)
(ROOT / 'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(f'Generated {len(manifest)} original audio assets in {ROOT}')
