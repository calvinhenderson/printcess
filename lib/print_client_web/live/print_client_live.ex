defmodule PrintClientWeb.PrintClientLive do
  use PrintClientWeb, :live_view

  @timeout_info_ms 1000
  @timeout_warn_ms 10000

  require Logger

  @impl true
  def mount(%{"tab" => tab}, _session, socket) do
    PubSub.subscribe(:menu_action)
    {:ok, assign(socket, dynamic_attrs: [x_data: "{tab: '#{tab}'}"])}
  end

  @impl true
  def mount(args, _session, socket) do
    PubSub.subscribe(:menu_action)
    {:ok, assign(socket, dynamic_attrs: [x_data: "{tab: 'text'}"])}
  end

  @impl true
  def handle_event("text", %{"text" => _text}, socket) do
    notification_event("Printing text label")
    {:noreply, socket}
  end

  @impl true
  def handle_event("asset", %{"asset" => asset, "serial" => serial}, socket) do

    # Verify the asset number is only numeric
    if ! Regex.match?(~r/[0-9]\+/, asset) do
      warning_event "Asset \"#{asset}\" may be misformatted!"
    end

    # Verify the serial number is only alphanumeric
    if ! Regex.match?(~r/[A-z0-9]\+/, serial) do
      warning_event "Serial \"#{serial}\" may be misformatted!"
    end

    print_event("Printing asset label")
    {:noreply, socket}
  end

  def notification_event(action) do
    Desktop.Window.show_notification(PrintClientWindow, inspect(action),
      id: :click,
      type: :info
    )
  end

  def print_event(action) do
    Desktop.Window.show_notification(PrintClientWindow, action, id: :default, type: :info, timeout: @timeout_info_ms)
  end

  def warning_event(action) do
    Desktop.Window.show_notification(PrintClientWindow, action, id: :default, type: :warning, timeout: @timeout_warn_ms)
  end

  def handle_info(:menu_action, action) do
    {:noreply, dynamic_attrs: [x_data: "{tab: '#{action}'}"]}
  end
end
