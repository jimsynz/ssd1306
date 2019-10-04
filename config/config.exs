import Config

config :ssd1306,
  devices: [
    %{bus: "i2c-1", address: 0x3D, reset_pin: 16}
  ]
