defmodule Ssd1306.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Ssd1306.Worker.start_link(arg)
      # {Ssd1306.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ssd1306.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
