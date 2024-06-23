defmodule SSD1306.Commands do
  import Bitwise
  alias ElixirALE.{GPIO, I2C}

  @moduledoc """
  This module contains all the constants and commands for manipulating the
  SSD1306 device.  More information about the available commands can be found in
  the _COMMAND TABLE_ section of the
  [Datasheet](https://cdn-shop.adafruit.com/datasheets/SSD1306.pdf).

  For simple use cases you will most likely want to simply use the
  `SSD1306.Device` module to automatically handle your display needs, however if
  you have something more complicated in mind then you can use the functions in
  this module to interact with an I2C device directly.
  """

  @control_register 0x00
  @data_register 0x40

  @cmd_set_contrast 0x81
  @cmd_display_all_on_resume 0xA4
  @cmd_display_all_on 0xA5
  @cmd_normal_display 0xA6
  @cmd_invert_display 0xA7
  @cmd_display_off 0xAE
  @cmd_display_on 0xAF
  @cmd_set_display_offset 0xD3
  @cmd_set_com_pins 0xDA
  @cmd_set_vcom_detect 0xDB
  @cmd_set_display_clock_div 0xD5
  @cmd_set_pre_charge 0xD9
  @cmd_set_multiplex 0xA8
  @cmd_set_low_column 0x00
  @cmd_set_high_column 0x10
  @cmd_set_start_line 0x40
  @cmd_set_memory_mode 0x20
  @cmd_set_column_address 0x21
  @cmd_set_page_address 0x22
  @cmd_com_scan_inc 0xC0
  # @cmd_com_scan_dec 0xC8
  @cmd_set_seg_remap 0xA0
  @cmd_set_charge_pump 0x8D
  @cmd_activate_scroll 0x2F
  @cmd_deactivate_scroll 0x2E
  @cmd_set_vertical_scroll_area 0xA3
  @cmd_right_horizontal_scroll 0x26
  @cmd_left_horizontal_scroll 0x27
  @cmd_vertical_and_right_horizontal_scroll 0x29
  @cmd_vertical_and_left_horizontal_scroll 0x2A

  @doc """
  Reset the SSD1306 using the GPIO reset pin.
  """
  def reset!(gpio_pid) do
    with :ok <- GPIO.write(gpio_pid, 1),
         :ok <- :timer.sleep(1),
         :ok <- GPIO.write(gpio_pid, 0),
         :ok <- :timer.sleep(10),
         do: GPIO.write(gpio_pid, 1)
  end

  @doc """
  Initialize the device using "sane defaults" based on the display size.

  Configurable options (configure by adding these keys to your device's keys
  in your application configuration) and their defaults below:

      config :ssd1306,
        device: [%{
          display_clock_div: 0x80,
          multiplex: 0x3f,
          external_vcc: false,
          charge_pump: 0x10, # or 0x14 if :external_vcc is true
          memory_mode: 0x80,
          segment_remap: 0x01,
          com_pins: 0x12,
          contrast: 0x9f, # or 0xcf if :external_vcc is true
          pre_charge: 0x22, # or 0xf1 if :external_vcc is true
          vcom_detect: 0x40
        }]
  """
  def initialize!(%{i2c: pid} = state) do
    with :ok <- display_off!(pid),
         :ok <- display_clock_div(pid, Map.get(state, :display_clock_div, 0x80)),
         :ok <- multiplex(pid, Map.get(state, :multiplex, 0x3F)),
         :ok <- display_offset(pid, 0),
         :ok <- start_line(pid, 0),
         :ok <-
           charge_pump(pid, Map.get(state, :charge_pump, vcc_is_external(state, 0x10, 0x14))),
         :ok <- memory_mode(pid, Map.get(state, :memory_mode, 0x00)),
         :ok <- segment_remap(pid, Map.get(state, :segment_remap, 0x01)),
         :ok <- com_scan_dec!(pid),
         :ok <- com_pins(pid, Map.get(state, :com_pins, 0x12)),
         :ok <- contrast(pid, Map.get(state, :contrast, vcc_is_external(state, 0x9F, 0xCF))),
         :ok <- pre_charge(pid, Map.get(state, :pre_charge, vcc_is_external(state, 0x22, 0xF1))),
         :ok <- vcom_detect(pid, Map.get(state, :vcom_detect, 0x40)),
         :ok <- display_all_on_resume!(pid),
         do: normal_display!(pid)
  end

  @doc """
  Send a frame to the display.

  Arguments:
    * A map with `:i2c` set to the I2C connection pid, `:width` and `:height` in pixels.
    * A bytestring containing the buffer to be displayed.
  """
  def display(%{i2c: pid, width: width, height: height}, buffer) do
    pages = div(height, 8)

    with :ok <- column_address(pid, 0, width - 1),
         :ok <- page_address(pid, 0, pages - 1),
         do: send_buffer(pid, buffer)
  end

  @doc "set contrast"
  def contrast(pid, value) when is_integer(value),
    do: send_commands(pid, [@cmd_set_contrast, value])

  @doc "set display all on resume"
  def display_all_on_resume!(pid), do: send_command(pid, @cmd_display_all_on_resume)

  @doc "set display all on"
  def display_all_on!(pid), do: send_command(pid, @cmd_display_all_on)

  @doc "set normal display"
  def normal_display!(pid), do: send_command(pid, @cmd_normal_display)

  @doc "set invert display"
  def invert_display!(pid), do: send_command(pid, @cmd_invert_display)

  @doc "set display off"
  def display_off!(pid), do: send_command(pid, @cmd_display_off)

  @doc "set display on"
  def display_on!(pid), do: send_command(pid, @cmd_display_on)

  @doc "set display offset"
  def display_offset(pid, value), do: send_commands(pid, [@cmd_set_display_offset, value])

  @doc "set com pins"
  def com_pins(pid, value), do: send_commands(pid, [@cmd_set_com_pins, value])

  @doc "set vcom detect"
  def vcom_detect(pid, value), do: send_commands(pid, [@cmd_set_vcom_detect, value])

  @doc "display clock div"
  def display_clock_div(pid, value), do: send_commands(pid, [@cmd_set_display_clock_div, value])

  @doc "set pre charge"
  def pre_charge(pid, value), do: send_commands(pid, [@cmd_set_pre_charge, value])

  @doc "set multiplex"
  def multiplex(pid, value), do: send_commands(pid, [@cmd_set_multiplex, value])

  @doc "set low column"
  def low_column(pid, value), do: send_commands(pid, [@cmd_set_low_column, value])

  @doc "set high column"
  def high_column(pid, value), do: send_commands(pid, [@cmd_set_high_column, value])

  @doc "set start line"
  def start_line(pid, value), do: send_command(pid, @cmd_set_start_line ||| value)

  @doc "set memory node"
  def memory_mode(pid, value), do: send_commands(pid, [@cmd_set_memory_mode, value])

  @doc "set column address"
  def column_address(pid, start, fin),
    do: send_commands(pid, [@cmd_set_column_address, start, fin])

  @doc "set page address"
  def page_address(pid, start, fin), do: send_commands(pid, [@cmd_set_page_address, start, fin])

  @doc "set com scan inc"
  def com_scan_inc!(pid), do: send_command(pid, @cmd_com_scan_inc)

  @doc "set com scan dec"
  def com_scan_dec!(pid), do: send_command(pid, @cmd_com_scan_inc)

  @doc "set segment remap"
  def segment_remap(pid, value), do: send_command(pid, @cmd_set_seg_remap ||| value)

  @doc "set charge pump"
  def charge_pump(pid, value), do: send_commands(pid, [@cmd_set_charge_pump, value])

  @doc "set activate scroll"
  def activate_scroll!(pid), do: send_command(pid, @cmd_activate_scroll)

  @doc "set deactivate scroll"
  def deactivate_scroll!(pid), do: send_command(pid, @cmd_deactivate_scroll)

  @doc "set vertical scroll area"
  def vertical_scroll_area(pid, value),
    do: send_commands(pid, [@cmd_set_vertical_scroll_area, value])

  @doc "set right horizontal scroll"
  def right_horizontal_scroll!(pid), do: send_command(pid, @cmd_right_horizontal_scroll)

  @doc "set left horizontal scroll"
  def left_horizontal_scroll!(pid), do: send_command(pid, @cmd_left_horizontal_scroll)

  @doc "set vertical and right horizontal scroll"
  def vertical_and_right_horizontal_scroll!(pid),
    do: send_command(pid, @cmd_vertical_and_right_horizontal_scroll)

  @doc "set vertical and left horizontal scroll"
  def vertical_and_left_horizontal_scroll!(pid),
    do: send_command(pid, @cmd_vertical_and_left_horizontal_scroll)

  defp send_data(pid, buffer), do: I2C.write(pid, <<@data_register>> <> buffer)

  defp send_command(pid, byte), do: I2C.write(pid, <<@control_register, byte>>)

  defp send_commands(pid, commands) do
    Enum.reduce(commands, :ok, fn
      _, {:error, _} = error -> error
      byte, :ok -> send_command(pid, byte)
    end)
  end

  defp send_buffer(pid, buffer) when byte_size(buffer) < 512, do: send_data(pid, buffer)

  defp send_buffer(pid, <<data::binary-size(511), rest::binary>>) do
    case send_data(pid, data) do
      :ok -> send_buffer(pid, rest)
      {:error, reason} -> {:error, reason}
    end
  end

  defp vcc_is_external(%{external_vcc: true}, value, _), do: value
  defp vcc_is_external(_, _, value), do: value
end
