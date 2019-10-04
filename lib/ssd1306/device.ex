defmodule SSD1306.Device do
  use GenServer
  use Bitwise
  alias ElixirALE.{I2C, GPIO}
  alias SSD1306.{Commands, Device}
  require Logger

  @moduledoc """
  An individual SSD1306 device.
  """

  @default_config %{
    width: 128,
    height: 64,
    address: 0x3C,
    bus: "i2c-1"
  }

  # The name of a valid I2C bus. See ElixirALE documentation for more information.
  @type bus :: String.t()
  # A valid I2C address for the device.
  @type address :: non_neg_integer
  # A binary buffer of monochrome image data.
  @type buffer :: binary

  @doc false
  def start_link(config), do: GenServer.start_link(Device, config)

  @doc """
  Turn on all pixels of the attached device.
  """
  @spec all_on(bus, address) :: :ok | {:error, term}
  def all_on(bus, address),
    do:
      GenServer.call(
        {:via, Registry, {SSD1306.Registry, {SSD1306.Device, bus, address}}},
        :all_on
      )

  @doc """
  Turn off all pixels of the attached device.
  """
  @spec all_off(bus, address) :: :ok | {:error, term}
  def all_off(bus, address),
    do:
      GenServer.call(
        {:via, Registry, {SSD1306.Registry, {SSD1306.Device, bus, address}}},
        :all_off
      )

  @doc """
  Send the contents of `buffer` to the device for display.
  """
  @spec display(bus, address, buffer) :: :ok | {:error, term}
  def display(bus, address, buffer) when is_binary(buffer),
    do:
      GenServer.call(
        {:via, Registry, {SSD1306.Registry, {SSD1306.Device, bus, address}}},
        {:display, buffer}
      )

  @doc """
  Send arbitrary commands to the device.

  This is useful for any advanced usage that doesn't involve just sending a
  buffer to the display.

  The `function` argument is a function which will be called from within the
  device process with the PID of the I2C connection as it's only argument.  Be
  aware that if this function takes a while to execute the device will be unable
  to respond to other messages.

  The commands are listed in the [SSD1306.Commands] module, and information
  about them can be found in the
  [SSD1306 Datasheet](https://cdn-shop.adafruit.com/datasheets/SSD1306.pdf).

  ## Example

  To invert the display.

      iex> alias SSD1306.{Device, Commands}
      ...> Device.commands("i2c-1", 0x3D, fn pid -> Commands.invert_display!(pid) end)
      :ok
  """
  @spec execute(bus, address, function) :: :ok
  def execute(bus, address, function) when is_function(function, 1),
    do:
      GenServer.call(
        {:via, Registry, {SSD1306.Registry, {SSD1306.Device, bus, address}}},
        {:execute, function}
      )

  @impl true
  def init(config) do
    state = @default_config |> Map.merge(config)

    Registry.register(SSD1306.Registry, {Device, state.bus, state.address}, self())
    Process.flag(:trap_exit, true)

    Logger.info(
      "Connecting to SSD1306 display #{device_name(state)} (#{state.width}x#{state.height} pixels)"
    )

    {:ok, i2c} = I2C.start_link(state.bus, state.address)
    {:ok, reset_pid} = GPIO.start_link(state.reset_pin, :output)

    state =
      state
      |> Map.put(:i2c, i2c)
      |> Map.put(:reset_pid, reset_pid)

    case reset_device(state) do
      :ok -> {:ok, state}
      {:error, e} -> {:stop, e}
    end
  end

  @impl true
  def handle_call(:all_on, from, state) do
    buffer = all_on_buffer(state)
    handle_call({:display, buffer}, from, state)
  end

  def handle_call(:all_off, from, state) do
    buffer = all_off_buffer(state)
    handle_call({:display, buffer}, from, state)
  end

  def handle_call({:display, buffer}, _from, state) do
    with :ok <- validate_buffer(buffer, state),
         :ok <- Commands.display(state, buffer) do
      {:reply, :ok, state}
    else
      err -> {:reply, err, state}
    end
  end

  def handle_call({:exectute, function}, _from, %{i2c: pid} = state) do
    function.(pid)
    {:reply, :ok, state}
  end

  @impl true
  def terminate(_reason, %{i2c: i2c, reset_pid: gpio}) when is_pid(i2c) and is_pid(gpio) do
    I2C.release(i2c)
    GPIO.release(gpio)
    :ok
  end

  @impl true
  def terminate(_, _), do: :ok

  defp device_name(%{bus: bus, address: address}) do
    "#{bus}:0x#{Integer.to_string(address, 16)}"
  end

  defp reset_device(%{reset_pid: reset_pid, i2c: i2c} = state) do
    with :ok <- Commands.reset!(reset_pid),
         :ok <- Commands.initialize!(state),
         :ok <- Commands.display(state, all_off_buffer(state)),
         :ok <- Commands.display_on!(i2c) do
      :ok
    end
  end

  defp all_on_buffer(state), do: initialize_buffer(state, 1)
  defp all_off_buffer(state), do: initialize_buffer(state, 0)

  def initialize_buffer(%{width: width, height: height}, value) when value == 0 or value == 1 do
    byte_len = div(width * height, 8)

    bytes =
      0..15
      |> Enum.reduce(0, &((value <<< &1) + &2))

    1..byte_len
    |> Enum.reduce(<<>>, fn _, buf -> buf <> <<bytes>> end)
  end

  defp validate_buffer(buffer, %{width: width, height: height})
       when byte_size(buffer) == width * height / 8,
       do: :ok

  defp validate_buffer(buffer, %{width: width, height: height}),
    do:
      {:error,
       "Expected buffer of #{div(width * height, 8)} bytes but received buffer of #{
         byte_size(buffer)
       } bytes."}
end
