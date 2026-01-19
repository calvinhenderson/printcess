defmodule PrintClient.PubSub do
  @moduledoc false

  def subscribe(pubsub, topic) do
    Phoenix.PubSub.subscribe(pubsub, topic)
  end

  def subscribe(%Phoenix.LiveView.Socket{assigns: %{myself: myself}} = socket, pubsub, topic) do
    if Phoenix.LiveView.connected?(socket) do
      metadata = [metadata: %{pid: self(), cid: myself}]
      Phoenix.PubSub.subscribe(pubsub, topic, metadata)
      socket
    else
      socket
    end
  end

  def subscribe(%Phoenix.LiveView.Socket{} = socket, pubsub, topic) do
    Phoenix.PubSub.subscribe(pubsub, topic)
    socket
  end

  def unsubscribe(%Phoenix.LiveView.Socket{assigns: %{myself: _myself}} = socket, pubsub, topic) do
    if Phoenix.LiveView.connected?(socket) do
      Phoenix.PubSub.unsubscribe(pubsub, topic)
      socket
    else
      socket
    end
  end

  def unsubscribe(pubsub, topic) do
    Phoenix.PubSub.unsubscribe(pubsub, topic)
  end

  def broadcast(pubsub, topic, message) do
    Phoenix.PubSub.broadcast(
      pubsub,
      topic,
      message,
      __MODULE__
    )
  end

  def broadcast_from(pubsub, pid, topic, message) do
    Phoenix.PubSub.broadcast_from(
      pubsub,
      pid,
      topic,
      message,
      __MODULE__
    )
  end

  def local_broadcast(pubsub, topic, message) do
    Phoenix.PubSub.local_broadcast(
      pubsub,
      topic,
      message,
      __MODULE__
    )
  end

  def dispatch(entries, _dispatch_identificator, message) do
    entries
    |> Enum.each(fn
      {_pid, %{cid: cid, pid: pid}} ->
        Phoenix.LiveView.send_update(pid, cid, source: :pubsub, message: message)

      {pid, _} ->
        send(pid, message)
    end)

    :ok
  end
end
