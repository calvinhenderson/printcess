defmodule PrintClient.Printer.Adapter.UsbPrinter do
  @behaviour PrintClient.Printer.Adapter

  alias PrintClient.Printer

  require Logger

  # Default settings, can be overridden
  defstruct vendor: nil,
            product: nil,
            serial_number: nil,
            usb_ref: nil,
            usb_timeout: 10_000

  @type t :: %__MODULE__{
          vendor: non_neg_integer() | nil,
          product: non_neg_integer() | nil,
          serial_number: binary() | nil,
          usb_ref: reference() | nil,
          usb_timeout: non_neg_integer()
        }

  @impl Printer.Adapter
  def connect(%__MODULE__{vendor: vendor, product: product, usb_ref: nil} = adapter_state)
      when is_number(vendor) and is_number(product) do
    Logger.info("UsbPrinter: Attempting to open USB device #{vendor}:#{product}.")

    find_and_claim_usb_device(vendor, product)
    |> case do
      {:ok, ref} ->
        Logger.info("UsbPrinter: Successfully connected to open USB device #{vendor}:#{product}.")

        {:ok, %{adapter_state | usb_ref: ref}}

      {:error, reason} ->
        Logger.error(
          "UsbPrinter: Failed to open USB device #{vendor}:#{product}. #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  def connect(%__MODULE__{vendor: vendor, product: product, usb_ref: _ref} = adapter_state) do
    # Already connected or has a reference, treat as connected for simplicity or re-verify
    Logger.info("UsbPrinter: #{vendor}:#{product} connection attempt on existing ref.")
    {:ok, adapter_state}
  end

  @impl Printer.Adapter
  def print(%__MODULE__{usb_ref: nil}, _data) do
    Logger.error("UsbPrinter: Cannot print, USB device is not open.")
    {:error, :not_connected}
  end

  def print(%__MODULE__{usb_ref: ref, usb_timeout: usb_timeout} = adapter_state, data) do
    # Ensure the uart_pid is alive before writing.
    case :usb.write_bulk(ref, 1, data, usb_timeout) do
      {:ok, written} ->
        dbg(data)

        if written != byte_size(data) do
          Logger.error(
            "UsbPrinter: Message truncated during transit. Wrote #{written}/#{byte_size(data)} bytes."
          )
        else
          Logger.info("UsbPrinter: Successfully wrote #{written}/#{byte_size(data)} bytes.")
        end

        :ok

      {:error, reason} ->
        Logger.error(
          "UsbPrinter: Failed to write to USB device #{adapter_state.vendor}:#{adapter_state.product}. #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  @impl Printer.Adapter
  def disconnect(%__MODULE__{usb_ref: nil} = adapter_state) do
    # Already disconnected
    {:ok, adapter_state}
  end

  def disconnect(%__MODULE__{usb_ref: ref} = adapter_state) do
    Logger.info(
      "UsbPrinter: Closing USB device #{adapter_state.vendor}:#{adapter_state.product}."
    )

    :usb.close_device(ref)
    {:ok, %{adapter_state | usb_ref: nil}}
  end

  @impl Printer.Adapter
  def status(%__MODULE__{usb_ref: nil}) do
    {:ok, :disconnected}
  end

  def status(%__MODULE__{usb_ref: ref, usb_timeout: usb_timeout} = adapter_state) do
    case :usb.read_bulk(ref, 1, 0, usb_timeout) do
      {:ok, _} ->
        :connected

      {:error, reason} ->
        Logger.warning(
          "UsbPrinter: USB device #{adapter_state.vendor}:#{adapter_state.product} is not alive. #{inspect(reason)}"
        )

        :disconnected
    end
  end

  defp merge_device_descriptors(devices) do
    Enum.reduce(devices, %{}, fn dev, acc ->
      case :usb.get_device_descriptor(dev) do
        {:ok, descriptor} ->
          Map.put(acc, dev, descriptor)

        error ->
          Logger.warning(
            "UsbPrinter: Skipping USB device discovery for #{inspect(dev)}. Unable to load descriptors: #{inspect(error)}."
          )

          acc
      end
    end)
  end

  defp filter_usb_device(devices, vendor, product) do
    Enum.find(devices, fn {_, v} ->
      v.vendor_id == vendor and v.product_id == product
    end)
  end

  defp find_and_claim_usb_device(vendor, product) do
    with {:ok, devices} <- :usb.get_device_list(),
         with_descriptors <- merge_device_descriptors(devices),
         {match, _} <- filter_usb_device(with_descriptors, vendor, product),
         {:ok, usb_ref} <- :usb.open_device(match),
         :ok <- :usb.claim_interface(usb_ref, 0) do
      {:ok, usb_ref}
    else
      _ ->
        {:error, :not_found}
    end
  end
end
