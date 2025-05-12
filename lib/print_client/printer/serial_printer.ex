defmodule PrintClient.Printer.SerialPrinter do
  @request_timeout 1000
  @packet_size 1000

  @impl Adapter
  def close(pid), do: UART.close(pid)

  @impl Adapter
  @spec write(pid(), term())
  def write(pid, data), do: UART.write(pid, data, @request_timeout)

  @impl Adapter
  def read(pid), do: UART.read(pid, @request_timeout)

  @impl Adapter
  def healthcheck(pid), do: :ok
end
