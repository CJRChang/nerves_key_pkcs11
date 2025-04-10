defmodule NervesKey.PKCS11.MixProject do
  use Mix.Project

  @version "1.2.0"
  @source_url "https://github.com/nerves-hub/nerves_key_pkcs11"

  def project do
    [
      app: :nerves_key_pkcs11,
      version: @version,
      elixir: "~> 1.13",
      description: description(),
      package: package(),
      source_url: @source_url,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      dialyzer: dialyzer(),
      docs: docs(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    [extra_applications: [:crypto]]
  end

  defp description do
    "PKCS #11 module for using the NervesKey"
  end

  defp package do
    [
      files: [
        "CHANGELOG.md",
        "lib",
        "LICENSES/*",
        "src/*.[ch]",
        "Makefile",
        "mix.exs",
        "README.md",
        "REUSE.toml"
      ],
      licenses: ["BSD-2-Clause"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.20", only: :docs, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs]
    ]
  end
end
