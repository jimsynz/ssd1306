defmodule SSD1306.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: SSD1306.Registry}
    ]

    devices =
      :ssd1306
      |> Application.get_env(:devices, [])
      |> Enum.map(&{SSD1306.Device, &1})

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SSD1306.Supervisor]
    Supervisor.start_link(children ++ devices, opts)
  end
end
