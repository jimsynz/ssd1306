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
    do: Supervisor.start_child(SSD1306.Supervisor, {SSD1306.Device, config})

  @doc """
  Disconnect an SSD1306 device.
  """
  def disconnect(device_name) do
    case Supervisor.terminate_child(SSD1306.Supervisor, {SSD1306.Device, device_name}) do
      :ok -> Supervisor.delete_child(SSD1306.Supervisor, {SSD1306.Device, device_name})
      {:error, reason} -> {:error, reason}
    end
  end
end
