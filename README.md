# PrintClient

## Building:

To build the macos image, first configure the build environment:
```sh
pushd

# Setup build versions and targets
export ELIXIR_VERSION=1.14.3
export OTP_VERSION=25.3
export OPENSSL_VERSION=1.1.1-stable
export TARGET=macos-x86_64

# Build standalone elixir and OTP
./scripts/build.sh $ELIXIR_VERSION $OTP_VERSION $OPENSSL_VERSION $TARGET

# Set path to use new build environment
export PATH="$(pwd)/_build/elixir-rel-${ELIXIR_VERSION}/bin:$(pwd)/_build/otp-rel-${OTP_VERSION}-openssl-${OPENSSL_VERSION}-${TARGET}/bin:$PATH"

popd
```

Next build the application release:
```sh
export MIX_ENV=prod

mix assets.deploy
mix release
```

Finally, copy the release into the macos app:
```sh
cp rel/macos/ExPrint.app _build/ExPrint.app
cp -r _build/prod/{lib,rel} _build/ExPrint.app/Contents/Resources/
```

You now have a built and packaged app at `_build/ExPrint.app`.

## Usage:

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
