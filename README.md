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

- Add autocomplete
  - Show a list of search results similar to iiQ.
    - If only one result, auto select
  - Owner username, asset and serial number from iiQ
  - Add simplified asset search? Lookup asset and then
    have two separate buttons (print owner / asset / both?)

