# Printcess

Printcess (previously *Print Client*) is a desktop application designed for managing label printing. Built with Elixir and Phoenix LiveView, it provides a real-time, responsive interface for managing, and printing dynamic labels. It leverages wxWidgets for native desktop integration. The application supports a wide range of connectivity via adapters (network, USB, serial) and comes with built-in support for TSPL2 encoding. Though, other encoders can easily be added by implementing the `Label.Encoder` protocol (see [PrintClient.Label.Encoder.TSPL](/lib/print_client/label/encoder/tspl.ex)).

![overview video](/docs/overview.avif)

## Usage

```sh
git clone https://github.com/calvinhenderson/phx-label-printing.git phx-label-printing
cd phx-label-printing/rel
make
```

## Roadmap

### V1 - MVP

- [x] Text labels
- [x] Asset/Serial labels
- [x] TSPL2 support
- [x] IP-based printing
- [x] Add/remove IP printers
- [x] Job queues
- [x] Packaged macOS application bundle

### V2 - Implementing User Feedback

- [x] `Printer` Generic api supporting any adapter.
  - [x] `Printer.Adapter` API for adding print drivers
  - [x] `Printer.Adapter.Mock` Mock driver for testing
  - [x] `Printer.Adapter.Network` Network driver
  - [x] `Printer.Adapter.Usb` USB driver
  - [x] `Printer.Adapter.Serial` Serial driver
  - [x] `Printer.PrintJob` Structured job type
  - [x] `Printer.Discovery` Discovery methods for dynamic printer discovery
  - [x] `Printer.Registry` A named registry for printer process discovery
  - [x] `Printer.Supervisor` A printer process supervisor for supervising printers and adapters
  - [x] Health monitoring to provide real-time printer status
- [x] `Label` Label API for managing and rendering labels and templates
  - [x] `Label.Template` Template API for parsing and rendering dynamic label templates
  - [x] `Label.Encoder` Label encoder API supporting any encoding adapter
  - [x] `Label.Encoder.TSPL` Adds support for the TSPL2 protocol
  - [x] `Label.Forms` Handle Ecto.Changesets for dynamic label template form fields
- [x] One-shot application build, packages, and installers
- [x] `AssetsApi` Provides a search API for form auto-completions
- [x] `Assets` and `Users` Provide generic search API for configured search backend.
- [x] `Views` API for attaching printers to templates
- [x] Job queue window for displaying all active/completed jobs
- [x] Template search paths for external template discovery
- [ ] Add support for automatic app updates
  - [ ] Automated CI builds and releases
- [ ] Label template API mappings for search fields
- [ ] Add support for asset owner assignments via `AssetsApi`
  - [ ] Check out view for automatic asset assignment when printing labels
- [ ] Multi-template printing
- [ ] Add support for dynamically sized text fields
- [ ] Integrated svg editor for creating label templates

### Planned - Not Yet Scheduled
