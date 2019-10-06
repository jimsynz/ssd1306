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

  @doc """
  Connect to an SSD1306 device.
  """
  def connect(config),
    do:
      Supervisor.start_child(SSD1306.Supervisor, %{
        id: {SSD1306.Device, Map.fetch!(config, :bus), Map.fetch!(config, :address)},
        start: {SSD1306.Device, :start_link, [config]}
      })

  @doc """
        Disconnect an SSD1306 device.
  """
  def disconnect(device_name),
    do: Process.exit({:via, Registry, {SSD1306.Registry, device_name}}, :normal)
end
