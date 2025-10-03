defmodule PrintClientWeb.PrintForm do
  use PrintClientWeb, :live_component

  alias Phoenix.LiveView.AsyncResult
  alias PrintClient.Label.Forms.LabelForm
  alias PrintClient.AssetsApi
  alias PrintClientWeb.ApiSearchComponent
  alias PrintClient.AssetsApi.SearchResult
  alias PrintClient.Printer

  require Logger

  # For now, we only persist the copies field.
  @persisted_form_fields ~w(copies)

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     %{
       :query_field => nil,
       :field => nil,
       :results => AsyncResult.loading()
     }
     |> Map.merge(assigns)
     |> Map.merge(socket.assigns)
     |> then(&Map.put(socket, :assigns, &1))
     |> assign_template()
     |> assign_changes()}
  end

  @impl true
  attr :fields, :list, required: true

  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        as={:form}
        id="print-form"
        phx-target={@myself}
        phx-submit="print"
        phx-change="validate"
        phx-reset="reset"
        target="_blank"
        phx-hook="AutoFocus"
      >
        <div class="grid sm:grid-cols-2 gap-x-4 lg:gap-x-8">
          <ApiSearchComponent.search
            :for={field <- @fields}
            id={f[field].id}
            field={f[field]}
            debounce="300"
            target={@myself}
            results={if @query_field == field, do: @results, else: nil}
          />

          <.input field={f[:copies]} phx-debounce="300" type="number" label="Copies" placeholder="1" />
        </div>

        <div class="grid grid-cols-[auto_1fr] gap-4">
          <.button type="reset" variant="error" class="h-12">
            <.icon name="hero-arrow-path-rounded-square" />
          </.button>
          <.button type="submit" variant="primary" class="h-12" phx-disable-with="Printing..">
            Print
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  # --- Event handlers ---

  @impl true
  def handle_event("print", %{"form" => params}, socket) do
    fields = Map.get(socket.assigns, :fields, [])

    with changeset <- LabelForm.changeset(fields, params),
         {:ok, validated} <- Ecto.Changeset.apply_action(changeset, :validate) do
      print(socket.assigns.printers, socket.assigns.template, validated)

      persisted =
        params
        |> Map.take(@persisted_form_fields)

      socket
      |> assign(:field, nil)
      |> assign_changes(persisted)
    else
      {:error, %Ecto.Changeset{}} ->
        socket
        |> assign(:field, nil)
        |> assign_changes(params)
        |> put_flash(:error, "Check form errors")

      {:error, reason} ->
        socket
        |> assign_changes(params)
        |> put_flash(:error, "Error printing: #{inspect(reason)}")
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("print", _params, socket), do: {:noreply, socket}

  def handle_event("validate", %{"_target" => ["undefined"], "form" => params}, socket) do
    persisted =
      Enum.filter(params, fn {param, _value} ->
        param in @persisted_form_fields
      end)
      |> Map.new()

    {:noreply, assign_changes(socket, persisted)}
  end

  def handle_event("validate", %{"_target" => ["form", field], "form" => params}, socket) do
    {:noreply,
     socket
     |> assign(:field, String.to_existing_atom(field))
     |> assign_changes(params)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    case socket.assigns.results do
      %AsyncResult{result: results} when is_list(results) ->
        entry = Enum.find(results, &(&1.id == id))

        case entry do
          nil ->
            socket

          %SearchResult.User{} = user ->
            user = Map.from_struct(user)

            changes =
              socket.assigns.changeset
              |> Map.get(:changes, %{})
              |> Map.merge(user)

            socket
            |> assign_changes(changes)
            |> assign(field: nil)

          %SearchResult.Asset{} = asset ->
            asset = Map.from_struct(asset)

            changes =
              socket.assigns.changeset
              |> Map.get(:changes, %{})
              |> Map.merge(asset)

            socket
            |> assign_changes(changes)
            |> assign(field: nil)
        end

      _ ->
        socket |> put_flash(:error, "An error occurred.")
    end
    |> then(&{:noreply, &1})
  end

  # --- Internal API ---

  defp print(printers, template, params) do
    printers
    |> Enum.map(fn printer ->
      Printer.add_job(printer, template, params)
    end)
  end

  defp assign_template(%{assigns: %{template: template}} = socket) do
    socket
    |> assign(fields: template.form_fields)
  end

  defp assign_changes(socket, changes \\ %{})

  defp assign_changes(%{assigns: %{fields: nil}} = socket, _changes),
    do: assign(socket, :changeset, nil)

  defp assign_changes(socket, changes) do
    changeset =
      socket.assigns.fields
      |> LabelForm.changeset(changes)

    changeset
    |> Ecto.Changeset.apply_action(:validate)
    |> case do
      {:ok, applied} ->
        send(self(), {:changed, applied})
        assign(socket, :changeset, changeset)

      {:error, changeset} ->
        applied = map_changes_keys(changeset.changes)

        send(self(), {:changed, applied})
        assign(socket, :changeset, %{changeset | action: :validate})
    end
    |> assign_query_results()
  end

  defp map_changes_keys(changes) do
    Enum.reduce(changes, %{}, fn {k, v}, acc ->
      cond do
        is_atom(k) -> Map.put(acc, k, v)
        is_binary(k) -> Map.put(acc, String.to_atom(k), v)
        true -> acc
      end
    end)
  end

  defp assign_query_results(socket) do
    with %{} = changes <- Map.get(socket.assigns, :changeset, %{changes: %{}}).changes,
         field when not is_nil(field) <- Map.get(socket.assigns, :field) do
      socket
      |> assign(:query_field, field)
      |> assign_async([:results], fn -> query_api(field, changes[field]) end)
    else
      _ ->
        socket
        |> assign_async([:results], fn ->
          {:ok, %{results: []}}
        end)
    end
  end

  defp query_api(field, value) do
    with value when is_binary(value) <- value,
         len when len >= 3 <- String.length(value),
         {:ok, results} <- perform_query(field, value) do
      Logger.info(
        "PrintForm: Performed query for field: #{inspect(field)}. With results: #{length(results)}"
      )

      {:ok, %{results: results}}
    else
      {:error, reason} ->
        Logger.error("PrintForm: Failed to perform API query: #{inspect(reason)}")
        {:ok, %{results: []}}

      _ ->
        {:ok, %{results: []}}
    end
  end

  defp perform_query(field, value) when field in [:username], do: AssetsApi.search_users(value)
  defp perform_query(_field, value), do: AssetsApi.search_assets(value)
end
