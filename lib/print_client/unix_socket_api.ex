defmodule PrintClient.UnixSocketApi do
  @moduledoc """
  Manages a local Unix file socket for local API access.

  ## API
  The socket API expects JSON-encoded data frames. The data can either
  be a single job: text/[asset, serial] with the number of copies, or
  a list of jobs may be specified.

  The following examples are all valid message formats:

      {"text": "ExPrint Rocks!", "copies": 10}

      {"asset": "asset number", "serial": "serial number", "copies": 1}

      [{"text": "ExPrint Rocks!"},{"asset":"12345","serial":"123ABC"}]


  ## Example:
  Socket exposed at `/var/run/exprint.sock` by default.
  Sending data:

      iex> exprint_socket = "/var/run/exprint.sock"
      iex> {:ok, sock} = :gen_udp.open(0, {:ifaddr, {:local, ...}})
      iex> :gen_udp.send(sock, {:local, exprint_socket}, '{"text": "hello, world!"}')
  """

  require Logger

  use GenServer
  @impl true
  def init(_args) do
    with {:ok, socket} <- open_socket() do
      {:ok, [socket: socket]}
    else
      {:error, reason} ->
        {:stop, reason}
    end
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def handle_info({:udp, _socket, _addr, _port, data}, state) do
    printer = Enum.find(PrintClient.Settings.all_printers(), fn p -> p.selected == 1 end)

    with {:ok, json} <- Jason.decode(data) do
      {_, state} = handle_cast({:push, Map.merge(%{printer: printer}, json)}, state)
      Logger.debug("pushing job to queue: #{inspect json}")
      {:reply, Jason.encode(%{success: "adding job to queue."}), state}
    else
      error ->
      Logger.debug("invalid json struct: #{inspect error}")
      {:reply, Jason.encode(%{error: "invalid json struct", reason: inspect(error)}), state}
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:push, data}, state) do
    with {:ok, data} <- PrintClient.Printer.Labels.validate_label_map(data) do
      Logger.debug("casting data: #{inspect data}")
      GenServer.cast(PrintQueue, {:push, data})
    else
      {:error, reason} -> Logger.warn(reason)
    end

    {:noreply, state}
  end

  defp open_socket() do
    socket_path = Path.join(System.user_home!(), "Library/exprint.sock")
    File.rm(socket_path)
    {:ok, socket} = :gen_udp.open(0, [{:ifaddr, {:local, socket_path}}])
    {:ok, socket}
  end
end
