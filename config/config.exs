import Config

# config :ssd1306,
#   devices: [
#     %{bus: "i2c-1", address: 0x3D, reset_pin: 16}
#   ]

config :git_ops,
  mix_project: Mix.Project.get!(),
  changelog_file: "CHANGELOG.md",
  repository_url: "https://gitlab.com/jimsy/ssd1306",
  manage_mix_version?: true,
  manage_readme_version: "README.md",
  version_tag_prefix: "v"
