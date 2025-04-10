# SPDX-FileCopyrightText: 2018 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Connor Rigby
#
# SPDX-License-Identifier: BSD-2-Clause
#
defmodule NervesKey.PKCS11 do
  @moduledoc """
  This module contains helper methods for loading and using the PKCS #11
  module for NervesKey in Elixir. You don't need to use these methods to
  use the shared library.
  """

  @typedoc "I2C bus"
  @type i2c_bus :: 0..31

  @typedoc "The device/signer certificate pair to use"
  @type certificate_pair() :: :primary | :aux

  @typedoc """
  Option for which NervesKey and certificate to use.

  * `:i2c` - which I2C bus
  * `:certificate` - which NervesKey certificate to use (`:primary` or `:aux`)
  * `:type` - if using pre-provisioned ATECC608B Trust and Go parts, specify `:trust_and_go`
  """
  @type option ::
          {:i2c, i2c_bus()}
          | {:certificate, certificate_pair()}
          | {:type, :nerves_key | :trust_and_go}

  @doc """
  Load the OpenSSL engine
  """
  @spec load_engine() :: {:ok, :crypto.engine_ref()} | {:error, any()}
  def load_engine() do
    libpkcs = pkcs11_path()

    unless libpkcs do
      raise """
      Can't find libpkcs11.so. Please make sure that it is installed.
      """
    end

    nk = Application.app_dir(:nerves_key_pkcs11, ["priv", "nerves_key_pkcs11.so"])

    # Load the p11 adapter and configure it with the nerves_key_pkcs11.so implementation
    with {:ok, engine} <- :crypto.ensure_engine_loaded("pkcs11", libpkcs),
         :ok <- :crypto.engine_ctrl_cmd_string(engine, "MODULE_PATH", nk) do
      {:ok, engine}
    end
  end

  @doc """
  Return the key map for passing a private key to ssl_opts.

  This method creates the key map that the `:crypto` library can
  use to properly route private key operations to the PKCS #11
  shared library.

  Options:

  * `:i2c` - which I2C bus (defaults to I2C bus 0 (`/dev/i2c-0`))
  * `:type` - :nerves_key or :trust_and_go (defaults to :nerves_key)
  * `:certificate` - which certificate on the NervesKey to use (defaults to `:primary`)

  Passing `{:i2c, 1}` is still supported, but should be updated to use keyword
  list form for the options.
  """
  @spec private_key(:crypto.engine_ref(), [option()] | {:i2c, i2c_bus()}) :: map()

  def private_key(engine, {:i2c, _addr} = location), do: private_key(engine, [location])

  def private_key(engine, opts) do
    slot_id = Enum.reduce(opts, 0, &process_option/2)

    %{
      algorithm: :ecdsa,
      engine: engine,
      key_id: "pkcs11:token=#{slot_id}"
    }
  end

  defp process_option({:i2c, bus_number}, acc), do: acc + bus_number

  defp process_option({:type, :nerves_key}, acc), do: acc
  defp process_option({:type, :trust_and_go}, acc), do: acc + 16

  # These are currently unused by the shared library, but validate them if they exist
  defp process_option({:certificate, :primary}, acc), do: acc
  defp process_option({:certificate, :aux}, acc), do: acc

  defp pkcs11_path() do
    [
      "/usr/lib/engines-1.1/libpkcs11.so",
      "/usr/lib/engines-3/libpkcs11.so",
      "/usr/lib/x86_64-linux-gnu/engines-1.1/libpkcs11.so",
      "/usr/lib/x86_64-linux-gnu/engines-3/libpkcs11.so",
      "/usr/lib/engines/libpkcs11.so"
    ]
    |> Enum.find(&File.exists?/1)
  end
end
