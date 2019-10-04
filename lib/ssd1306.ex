defmodule SSD1306 do
  @moduledoc """
  SSD1306 Driver for Elixir using ElixirALE.

  ## Usage:
  Add your devices to your config like so:

      config :ssd1306,
        devices: [
          %{bus: "i2c-1", address: 0x3d, reset_pin: 17}
        ]

  Then use the functions in [SSD1306.Device] to send image data.
  Pretty simple.
  """
end
