defmodule SSD1306.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :ssd1306,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      description: "Provides a driver for SSD1306-based monochrome displays connected via I2C",
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SSD1306.Application, []}
    ]
  end

  def package do
    [
      maintainers: ["James Harton <james@harton.nz>"],
      licenses: ["MIT"],
      links: %{
        "Source" => "https://gitlab.com/jimsy/ssd1306"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:earmark, ">= 0.2.1", only: ~w[dev test]a, runtime: false},
      {:ex_doc, ">= 0.0.0", only: ~w[dev test]a, runtime: false},
      {:elixir_ale, "~> 1.2", optional: true},
      {:credo, "~> 1.6", only: ~w[dev test]a, runtime: false},
      {:git_ops, "~> 2.3", only: ~w[dev test]a, runtime: false}
    ]
  end
end
