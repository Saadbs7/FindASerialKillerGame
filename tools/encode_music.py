"""Encode the original music masters as MP3 without altering their arrangement.

Run after generate_audio.py:
    python tools/encode_music.py --ffmpeg /path/to/ffmpeg
FFmpeg is a development tool only; it is not bundled with the game.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import wave

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ffmpeg', default=shutil.which('ffmpeg'))
args = parser.parse_args()
if not args.ffmpeg:
    parser.error('Provide --ffmpeg pointing to an FFmpeg executable.')

root = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
manifest = []
for name in ('menu', 'investigation', 'accusation'):
    source = root / f'{name}.wav'
    output = root / f'{name}.mp3'
    subprocess.run([
        args.ffmpeg, '-hide_banner', '-loglevel', 'error', '-nostdin', '-y',
        '-i', str(source), '-map_metadata', '-1', '-vn',
        '-c:a', 'libmp3lame', '-b:a', '192k', '-ar', '44100', '-ac', '2',
        '-write_xing', '1', str(output),
    ], check=True)
    with wave.open(str(source)) as original:
        seconds = original.getnframes() / original.getframerate()
    manifest.append({
        'file': output.name,
        'source': source.name,
        'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
        'source_seconds': seconds,
        'codec': 'MP3 / libmp3lame',
        'sample_rate': 44100,
        'channels': 2,
        'bitrate_kbps': 192,
        'bytes': output.stat().st_size,
    })
(root / 'music_manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
print(f'Encoded {len(manifest)} music tracks; '
      f'{sum(item["bytes"] for item in manifest)/1024/1024:.2f} MiB total.')
