defmodule PrintClient.Printer.Adapter.NetworkPrinter do
  use GenServer

  @request_timeout 1000
  @packet_size 1000

  ## 
  ## Helpers

  @doc """
  Closes an open connection to a printer.
  """
  def close(pid),
    do: {:reply, GenServer.call(pid, :close, @request_timeout)}

  @doc """
  Sends a binary string to a printer.
  """
  def write(pid, data),
    do: GenServer.call(pid, {:write, data}, @request_timeout)

  @doc """
  Receives a binary string from a printer.
  """
  def read(pid),
    do: GenServer.call(pid, :read, @request_timeout)

  @doc """
  Performs a healthcheck on the printer.
  """
  def healthcheck(pid),
    do: GenServer.call(pid, :healthcheck, @request_timeout)

  ##
  ## GenServer implementation

  def start_link(printer) do
    hostname = Keyword.fetch!(printer, :hostname)
    GenServer.start_link(__MODULE__, printer, name: hostname)
  end

  @impl true
  def init(printer) do
    open(printer)
    |> case do
      {:ok, socket} ->
        {:ok, %{conn: socket, printer: printer}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:write, command}, _from, %{conn: conn} = state),
    do: {:reply, :gen_tcp.send(conn, command), state}

  @impl true
  def handle_call(:read, _from, %{conn: conn} = state),
    do: {:reply, :gen_tcp.recv(conn, @packet_size), state}

  @impl true
  def handle_call(:close, %{conn: conn} = state) do
    if not is_nil(conn), do: :gen_tcp.close(conn)
    {:reply, :ok, %{state | conn: nil}}
  end

  def handle_call(:healthcheck, %{printer: printer} = state) do
    hostname = to_charlist(Keyword.fetch!(printer, :hostname))

    healthy? =
      :gen_icmp.ping(hostname)
      |> case do
        {:ok, _host, _addr, _reply, _details, _payload} ->
          :ok

        {:error, icmp_error, _host, _addr, _reply, _details, _payload} ->
          {:error, icmp_error}

        {:error, error, _host, _addr} ->
          {:error, error}
      end

    {:reply, healthy?, state}
  end

  defp open(printer) do
    hostname = to_charlist(Keyword.fetch!(printer, :hostname))
    port = Keyword.fetch!(printer, :port)

    :gen_tcp.connect(hostname, port)
  end
end
