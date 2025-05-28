defmodule PrintClientWeb.PrintForm do
  alias PrintClient.AssetsApi.SearchResult
  use PrintClientWeb, :live_component

  alias Phoenix.LiveView.AsyncResult
  alias PrintClientWeb.Forms.AssetForm
  alias PrintClient.AssetsApi
  alias PrintClientWeb.ApiSearchComponent

  require Logger

  # For now, we only persist the copies field.
  @persisted_form_fields ~w(copies)

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:query_field, nil)
      |> assign(:field, nil)
      |> assign(:results, AsyncResult.loading())
      |> assign(:query_field, AsyncResult.loading())
      |> assign_changes()

    {:ok, socket}
  end

  @impl true
  attr :fields, :list, required: true

  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        id="print-form"
        phx-target={@myself}
        phx-submit="print"
        phx-change="validate"
        phx-reset="reset"
        class="flex flex-col gap-3"
        target="_blank"
        phx-hook="AutoFocus"
      >
        <ApiSearchComponent.search
          :for={field <- @fields}
          id={f[field].id}
          field={f[field]}
          debounce="300"
          target={@myself}
          results={if @query_field.result == field, do: @results, else: nil}
        />

        <.input field={f[:copies]} phx-debounce="300" type="number" label="Copies" placeholder="1" />

        <div class="flex flex-row gap-2">
          <.button type="reset" class="h-12">
            <.icon name="hero-arrow-path-rounded-square" />
          </.button>
          <.button type="submit" class="flex-grow h-12" phx-disable-with="Submitting..">
            Submit
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  # --- Event handlers ---

  @impl true
  def handle_event("print", %{"asset_form" => params}, socket) do
    fields = Map.get(socket.assigns, :fields, [])

    with changeset <- AssetForm.changeset(%AssetForm{}, params, fields),
         {:ok, validated} <- Ecto.Changeset.apply_action(changeset, :validate) do
      send(self(), {:print, validated})

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
        |> assign(:field, nil)
        |> assign_changes(params)
        |> put_flash(:error, "Error printing: #{inspect(reason)}")
    end
    |> then(&{:noreply, &1})
  end

  def handle_event("print", _params, socket), do: {:noreply, socket}

  def handle_event(
        "validate",
        %{"_target" => ["undefined"], "asset_form" => params},
        socket
      ) do
    persisted =
      Enum.filter(params, fn {param, _value} ->
        param in @persisted_form_fields
      end)
      |> Map.new()

    {:noreply, assign_changes(socket, persisted)}
  end

  def handle_event(
        "validate",
        %{"_target" => ["asset_form", field], "asset_form" => params},
        socket
      ),
      do:
        {:noreply,
         socket |> assign(:field, String.to_existing_atom(field)) |> assign_changes(params)}

  def handle_event("clear", %{"selection" => key}, socket),
    do: {:noreply, socket |> assign(:selection, Map.put(socket.assigns.selection, key, nil))}

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

  defp assign_changes(socket, changes \\ %{})

  defp assign_changes(%{assigns: %{fields: nil}} = socket, _changes),
    do: assign(socket, :changeset, nil)

  defp assign_changes(socket, changes) do
    changeset =
      AssetForm.changeset(
        %AssetForm{},
        changes,
        Map.get(socket.assigns, :fields, [])
      )
      |> dbg()

    case Ecto.Changeset.apply_action(changeset, :validate) do
      {:ok, applied} ->
        send(self(), {:changed, applied})

      {:error, changeset} ->
        send(self(), {:changed, changeset.changes})
    end

    socket
    |> assign(:changeset, %{changeset | action: :validate})
    |> assign_query_results()
  end

  defp assign_query_results(socket) do
    with %{} = changes <- Map.get(socket.assigns, :changeset, %{changes: %{}}).changes,
         field when field != nil <- Map.get(socket.assigns, :field) do
      socket
      |> assign_async([:results, :query_field], fn -> query_api(field, changes[field]) end)
    else
      _ ->
        socket
        |> assign_async([:results, :query_field], fn ->
          {:ok, %{results: [], query_field: nil}}
        end)
    end
  end

  defp query_api(field, value) do
    with value when is_binary(value) <- value,
         len when len >= 3 <- String.length(value),
         {:ok, results} <- perform_query(field, value) do
      {:ok, %{results: results, query_field: field}}
    else
      {:error, reason} ->
        Logger.error("PrintForm: Failed to perform API query: #{inspect(reason)}")
        {:ok, %{results: [], query_field: field}}

      _ ->
        {:ok, %{results: [], query_field: field}}
    end
  end

  defp perform_query(field, value) when field in [:username], do: AssetsApi.search_users(value)
  defp perform_query(_field, value), do: AssetsApi.search_assets(value)
end
