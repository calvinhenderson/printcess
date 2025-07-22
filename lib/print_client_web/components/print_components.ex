defmodule PrintClientWeb.PrintComponents do
  use PrintClientWeb, :html

  alias Phoenix.LiveView.AsyncResult
  alias PrintClient.Label

  @doc """

  """
  attr :results, :any, default: AsyncResult.loading()
  attr :class, :string, default: ""
  attr :results_id, :any, default: nil
  attr :rest, :global

  slot :label do
    attr :class, :string
  end

  slot :option do
    attr :id, :any
  end

  def dropdown(assigns) do
    ~H"""
    <div tabindex="0" class={["dropdown", @class]} {@rest}>
      <div class={@label |> Enum.at(0) |> Map.get(:class, "")}>
        {render_slot(@label)}
      </div>
      <ul
        :if={not is_nil(@results)}
        id={@results_id}
        class="dropdown-content menu bg-base-200 rounded-box z-1 min-w-max w-full p-2 shadow-sm"
      >
        <%= case @results do %>
          <% %AsyncResult{} -> %>
            <li :if={@results.loading} class="contents"><.loading_indicator /></li>
            <li :if={@results.failed} class="text-error">An error occurred.</li>
            <li :for={row <- @results.result} :if={@results.result} class="contents">
              {render_slot(@option, row)}
            </li>
          <% options when options == [] -> %>
            <li>No results..</li>
          <% options when is_list(options) -> %>
            <li :for={row <- options} class="contents">{render_slot(@option, row)}</li>
        <% end %>
      </ul>
    </div>
    """
  end

  @doc """
  Renders a label template with the specified params.
  """

  attr :template, :map, required: true
  attr :params, :map, default: %{}

  def label_template(assigns) do
    ~H"""
    <div
      :if={not is_nil(@template)}
      class="flex flex-col justify-center items-center w-full h-full max-w-full input input-neutral rounded-md mx-auto bg-white dark:invert"
    >
      {raw(Label.render(@template, @params))}
    </div>
    """
  end

  @doc """
  An animated loading indicator component.
  """
  attr :class, :string, default: ""

  def loading_indicator(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" class={["w-auto h-8", @class]}>
      <circle class="fill-base-content stroke-base-content" stroke-width="15" r="15" cx="40" cy="100">
        <animate
          attributeName="opacity"
          calcMode="spline"
          dur="2"
          values="1;0;1;"
          keySplines=".5 0 .5 1;.5 0 .5 1"
          repeatCount="indefinite"
          begin="-.4"
        >
        </animate>
      </circle>
      <circle class="fill-base-content stroke-base-content" stroke-width="15" r="15" cx="100" cy="100">
        <animate
          attributeName="opacity"
          calcMode="spline"
          dur="2"
          values="1;0;1;"
          keySplines=".5 0 .5 1;.5 0 .5 1"
          repeatCount="indefinite"
          begin="-.2"
        >
        </animate>
      </circle>
      <circle class="fill-base-content stroke-base-content" stroke-width="15" r="15" cx="160" cy="100">
        <animate
          attributeName="opacity"
          calcMode="spline"
          dur="2"
          values="1;0;1;"
          keySplines=".5 0 .5 1;.5 0 .5 1"
          repeatCount="indefinite"
          begin="0"
        >
        </animate>
      </circle>
    </svg>
    """
  end
end
