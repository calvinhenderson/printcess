defmodule PrintClientWeb.PrintComponents do
  use PrintClientWeb, :html

  alias Phoenix.LiveView.AsyncResult
  alias PrintClient.Label
  alias PrintClientWeb.PrinterCardLive

  import PrintClientWeb.CoreComponents

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
  attr :class, :string, default: ""

  def label_template(assigns) do
    ~H"""
    <div
      :if={not is_nil(@template)}
      class={[
        @class,
        "flex flex-col justify-start items-center w-full h-auto max-w-xl mx-auto"
      ]}
    >
      <div class="rounded-md bg-white dark:invert ring-2 ring-base-300 dark:ring-base-content w-full">
        {raw(Label.render(@template, @params))}
      </div>
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

  @doc """
  Renders a label template selection as a stylized vertical list.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField
  attr :multiple, :boolean, default: false
  attr :errors, :list, default: []
  attr :options, :list, required: true

  def template_select(assigns) do
    field = assigns.field
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(:field, nil)
      |> assign(:id, assigns.id || field.id)
      |> assign(:type, "select")
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
      |> assign_new(:value, fn -> field.value end)

    ~H"""
    <fieldset class="fieldset w-full">
      <div class="flex flex-col gap-4">
        <label :for={t <- @options} class="relative cursor-pointer group">
          <input
            id={@id}
            name={@name}
            class="peer sr-only"
            value={t.id}
            type={if @multiple, do: "checkbox", else: "radio"}
            checked={checked?(t.id, @value)}
          />
          <div class="
            card bg-base-100 border-2 border-base-200 overflow-hidden transition-all duration-200
            hover:border-primary/50 hover:shadow-md
            peer-checked:border-primary peer-checked:ring-1 peer-checked:ring-primary peer-checked:shadow-lg
          ">
            <div class="bg-base-200/50 p-6 flex justify-center items-center">
              <div class="w-full shadow-sm bg-white rounded transform transition-transform duration-300 group-hover:scale-[1.02]">
                <.label_template
                  class="w-full h-auto pointer-events-none select-none"
                  template={t}
                  params={placeholder_for_template_fields(t.form_fields)}
                />
              </div>
            </div>

            <div class="p-4 bg-base-100 flex items-center justify-between">
              <div>
                <h2 class="font-bold text-base-content group-hover:text-primary transition-colors">
                  {t.name}
                </h2>
                <p class="text-xs text-base-content/50 font-mono mt-1">ID: {t.id}</p>
              </div>
              <div class="opacity-0 peer-checked:opacity-100 text-primary transition-opacity duration-200">
                <.icon name="hero-check-circle-solid" class="w-6 h-6" />
              </div>
            </div>
          </div>
        </label>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  @doc """
  Renders a printer selection as a list of toggleable cards.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField
  attr :multiple, :boolean, default: false
  attr :errors, :list, default: []
  attr :options, :list, required: true

  def printer_select(assigns) do
    field = assigns.field
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(:id, assigns.id || field.id)
      |> assign(:type, "select")
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
      |> assign_new(:value, fn -> field.value end)
      |> assign(:field, nil)

    ~H"""
    <fieldset class="fieldset w-full">
      <div class="flex flex-col gap-3">
        <label :for={p <- @options} class="cursor-pointer group">
          <input
            id={@id}
            name={@name}
            class="peer sr-only"
            value={p.id}
            type={if @multiple, do: "checkbox", else: "radio"}
            checked={
              cond do
                @multiple and is_list(@value) and to_string(p.id) in @value -> true
                to_string(p.id) == to_string(@value) -> true
                true -> false
              end
            }
          />
          <div class="
            relative flex items-center gap-4 p-4 rounded-xl border border-base-200 bg-base-100 transition-all duration-200
            hover:bg-base-50 hover:border-base-300
            peer-checked:border-primary peer-checked:bg-primary/5 peer-checked:shadow-md
          ">
            <div class="flex-1 min-w-0 pointer-events-none">
              <.live_component
                module={PrinterCardLive}
                id={"#{@id}-#{p.id}-card"}
                printer={p}
                class="bg-transparent shadow-none border-none p-0"
                nolink
                compact
              />
            </div>

            <div class="hidden peer-checked:block text-primary animate-in fade-in zoom-in duration-200">
              <.icon name="hero-printer-solid" class="w-5 h-5" />
            </div>
          </div>
        </label>
      </div>
      <.error :for={msg <- @errors}>{msg}</.error>
    </fieldset>
    """
  end

  @doc """
  Renders an empty placeholder.
  """
  attr :label, :string, default: nil, doc: "the action item label"
  attr :navigate, :string, doc: "the action item href"

  def empty_placeholder(assigns) do
    ~H"""
    <div class="flex flex-col-reverse sm:flex-row gap-4 sm:gap-8 justify-center items-center">
      <h2 class="text-2xl font-bold text-content-100 opacity-50 sm:text-center">
        <p>It's pretty empty here.</p>
        <p :if={@navigate}>
          You should <.link class="text-primary" href={@navigate}>{@label || "go here"}</.link>.
        </p>
      </h2>
      <img
        src={~p"/images/undraw_barbecue.svg"}
        class="hidden sm:block w-full max-w-40 grayscale brightness-150"
      />
    </div>
    """
  end

  def placeholder_for_template_fields(fields),
    do:
      Enum.reduce(fields, %{}, fn f, acc ->
        Map.put(acc, f, "[ #{Atom.to_string(f)} ]")
      end)

  defp checked?(id, values) when is_list(values), do: Enum.find(values, &(&1.id == id)) && true
  defp checked?(id, %{id: value_id}), do: id == value_id
  defp checked?(id, value), do: id == value
end
