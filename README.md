# fanctl

A command-line tool for controlling Apple Silicon Mac fan speeds.

## Install

```bash
brew install HaiH1ep/fanctl/fanctl
```

Or build from source:

```bash
git clone https://github.com/HaiH1ep/fanctl.git
cd fanctl
swift build -c release
sudo cp .build/release/fanctl /usr/local/bin/
```

## Usage

```bash
# Show temperatures and fan speeds
fanctl

# Live monitoring (refreshes every 2s)
fanctl monitor
fanctl monitor 1          # 1-second refresh

# Set fan speed (requires sudo)
sudo fanctl set 0 2000    # Fan 0 at 2000 RPM
sudo fanctl set 1 3000    # Fan 1 at 3000 RPM

# Reset all fans to automatic
sudo fanctl reset
```

## Requirements

- macOS 14.0+
- Apple Silicon (M1/M2/M3/M4)

## License

MIT
