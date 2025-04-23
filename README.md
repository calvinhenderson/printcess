# PrintClient

## Usage:

```sh
pushd rel

# Build standalone elixir and OTP
./build_macos.sh -e [elixir-version] -o [otp-version]

# Set path to use new build environment
export PATH="$(pwd)/_build/elixir-rel-otp-${otp-version}/bin:$(pwd)/_build/erlang-otp-[otp_version]-[arch]/bin:$PATH"

popd
```

Next build the application release:

```sh
export MIX_ENV=prod

mix assets.deploy
mix release
```

You now have a bundled desktop app at `_build/prod/rel/bundle/[app name].app`.

## Todo

- Refactor Printing API:
  - [ ] Add `Printer.Adapter` API:
  - [ ] Support IP/networked printers
  - [ ] Support USB Serial printers

- Consolidate application views
  - There's too many windows. Consolidate to one larger window with better UX.

- Add autocomplete
  - Show a list of search results similar to iiQ.
    - If only one result, auto select
  - Owner username, asset and serial number from iiQ
  - Add simplified asset search? Lookup asset and then
    have separate buttons (print owner / asset / both?)
  - Add support for label templates

- Printer - Main API for printing. Specifies base protocol that can be overridden for printer adapters
  - Adapter - Behaviour for specifying printer adapters (ie: network, serial, etc.)
    - Network - Communicates with printers over a binary tcp socket.
    - USB Serial - Communicates with a printer via a local usb serial adapter.
  - Command - API for creating commands. Specifies behaviour for each supported language.
    - TSPL2 - Generates commands for printers supporting the TSPL2 spec.
    - IPP (example) - Generates commands for printers supporting the IPP protocol.

Storing printer configs:
- Add Network Printer:
  - Host IP
  - Port
  - Language (TSPL2, IPP, etc.)
- USB Serial Printer:
  - Auto-discovery
  - Manufacturer Name (optional, to bind config to manufacturer)
  - Model Name (optional, to bind config to model of printers)
  - Serial Number (optional, to bind config to specific printer)
  - Language (TSPL2, IPP, etc.)
