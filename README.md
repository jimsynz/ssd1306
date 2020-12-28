# SSD1306

SSD1306 is an Elixir driver for SSD1306 devices like the
[Adafruit Monochrome 1.3" OLED display](https://www.adafruit.com/product/938)
connected via I2C.  It should be possible to modify this library to use the SPI
interface also, because all the commands are the same, but I'm only using them
via I2C.  Patches welcome.

We make use of [Elixir ALE](https://hex.pm/packages/elixir_ale), so all the
caveats about installing that also apply here.

## Usage

Add your devices to your config like so:

```elixir
use Config

config :ssd1306,
  devices: [
    %{bus: "i2c-1", address: 0x3d, reset_pin: 17}
  ]
```

And start your application.  Your devices will be reset, initialised with
defaults and a blank buffer will be sent to them.  Note that this library
assumes that you have the reset pin of the device connected to a GPIO pin on the
local device.

### Sending images

You need to generate buffers (Erlang binaries) of `width` * `height` * 8 bytes
long.  We do validate that the buffer is of the correct size, but there's no way
to validate that it is of the correct geometry.

How you generate buffers is up to you, but I suggest
[Vivid](https://hex.pm/packages/vivid).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ssd1306` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ssd1306, "~> 0.1.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/SSD1306](https://hexdocs.pm/SSD1306).

