defmodule PrintClientWeb.Modal do
  @moduledoc """
  Provides a reusable modal component.
  """

  use PrintClientWeb, :html

  @doc """
  Shows a modal.
  """
  attr :id, :any, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  attr :close, JS, default: %JS{}
  attr :class, :any, default: ""

  slot :inner_block

  def modal(assigns) do
    ~H"""
    <dialog
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class={["modal", @class]}
    >
      <div class="modal-box">
        {render_slot(@inner_block, %{close: hide_modal(@id), cancel: cancel_modal(@id)})}
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  @spec show_modal(JS.t() | Phoenix.LiveView.Socket.t(), binary()) ::
          JS.t() | Phoenix.LiveView.Socket.t()
  def show_modal(js \\ %JS{}, id)

  def show_modal(%Phoenix.LiveView.Socket{} = socket, target) do
    Phoenix.LiveView.push_event(socket, "show-dialog-modal", %{id: target})
  end

  def show_modal(%JS{} = js, id) do
    JS.dispatch(js, "show-dialog-modal", to: "##{id}")
  end

  @spec hide_modal(JS.t() | Phoenix.LiveView.Socket.t(), binary()) ::
          JS.t() | Phoenix.LiveView.Socket.t()
  def hide_modal(js \\ %JS{}, id)

  def hide_modal(%Phoenix.LiveView.Socket{} = socket, target) do
    Phoenix.LiveView.push_event(socket, "hide-dialog-modal", %{id: target})
  end

  def hide_modal(%JS{} = js, id) do
    JS.dispatch(js, "hide-dialog-modal", to: "##{id}")
  end

  # We want to allow cancelling from other places as well
  def cancel_modal(js \\ %JS{}, id) do
    JS.exec(js, "data-cancel", to: "##{id}")
  end
end
