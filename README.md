# volumio-rtlsdr-binaries

Cross-architecture binary builder for DAB/DAB+ command-line tools used in Volumio RTL-SDR Radio plugin.

## Overview

This repository provides Docker-based cross-compilation for dab-cmdline binaries targeting multiple architectures used by Volumio audio systems.

**Built Binaries:**
- `dab-rtlsdr-3` - DAB/DAB+ decoder with stdout PCM output
- `dab-scanner-3` - DAB channel scanner

**Source:** [JvanKatwijk/dab-cmdline](https://github.com/JvanKatwijk/dab-cmdline)  
**License:** GPL-2.0

## Supported Architectures

- **armv6** - Raspberry Pi Zero, Pi 1 (ARMv6 hard-float)
- **armhf** - Raspberry Pi 2, Pi 3 (ARMv7)
- **arm64** - Raspberry Pi 3, Pi 4, Pi 5 (64-bit)
- **amd64** - x86/x64 systems

## Build Requirements

- Docker
- bash
- git

## Quick Start

Build all architectures:
```bash
./build-matrix.sh --verbose
```

Build specific architecture:
```bash
./docker/run-docker-dab.sh dab armv6 --verbose
```

Clean all build artifacts:
```bash
./clean-all.sh
```

## Output

Binaries are placed in:
```
out/
  armv6/
    dab-rtlsdr-3
    dab-scanner-3
  armhf/
    dab-rtlsdr-3
    dab-scanner-3
  arm64/
    dab-rtlsdr-3
    dab-scanner-3
  amd64/
    dab-rtlsdr-3
    dab-scanner-3
```

## Build Process

1. `scripts/clone-source.sh` - Clone dab-cmdline repository
2. `scripts/build-binaries.sh` - Build and strip binaries
3. Docker containers provide isolated build environments per architecture
4. Binaries copied to `out/<arch>/`

## Binary Usage

### dab-rtlsdr-3
Decode DAB/DAB+ and output PCM audio to stdout:
```bash
dab-rtlsdr-3 -C 12C -P "BBC Radio 1" -G 80 | aplay -D hw:0,0 -f S16_LE -r 48000 -c 2
```

### dab-scanner-3
Scan all DAB channels in Band III:
```bash
dab-scanner-3 -B "BAND III" -G 80
```

## Integration

These binaries are intended for use with the Volumio RTL-SDR Radio plugin:
- Plugin repo: `volumio-plugins-sources-bookworm/rtlsdr_radio/`
- Binaries copied to: `rtlsdr_radio/bin/<arch>/`

## Dependencies

### Build-time (Docker)
- git, cmake, build-essential, g++, pkg-config
- libsndfile1-dev, libfftw3-dev, portaudio19-dev
- libfaad-dev, zlib1g-dev, libusb-1.0-0-dev
- mesa-common-dev, libgl1-mesa-dev, libsamplerate0-dev
- librtlsdr-dev

### Runtime (target system)
- librtlsdr0
- libfftw3-3
- libsamplerate0
- libfaad2

## Architecture Notes

### ARMv6 (Volumio Universal Pi Image)
Volumio uses a single 32-bit universal image for all Raspberry Pi models (Zero through 5). Binaries are compiled with:
```
-march=armv6 -mfpu=vfp -mfloat-abi=hard -marm
```

This ensures compatibility across all Pi generations while maintaining hard-float performance.

## Maintainer

Nerd  
GitHub: [foonerd](https://github.com/foonerd)

## Related Projects

- [volumio-mpd-core](https://github.com/foonerd/volumio-mpd-core)
- [volumio-bluetooth-core](https://github.com/foonerd/volumio-bluetooth-core)
- [cdspeedctl](https://github.com/foonerd/cdspeedctl)

## License

GPL-2.0 (matching upstream dab-cmdline)
