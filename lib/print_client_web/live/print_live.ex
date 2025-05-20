defmodule PrintClientWeb.PrintLive do
  defmodule OptionsForm do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :bind_asset_to_user, :boolean
    end

    def changeset(options, attrs \\ %{}), do: cast(options, attrs, [:bind_asset_to_user])
  end

  defmodule AssetForm do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :username, :string
      field :asset, :string
      field :serial, :string
      field :copies, :integer, default: 1
    end

    def changeset(asset, attrs \\ %{}, required \\ [:username, :asset, :serial, :copies]) do
      asset
      |> cast(attrs, [:username, :asset, :serial, :copies])
      |> validate_required(required)
      |> validate_number(:copies, greater_than: 0)
    end
  end

  alias Phoenix.LiveView.AsyncResult
  alias PrintClient.AssetsApi
  use PrintClientWeb, :live_view

  alias __MODULE__.{AssetForm, OptionsForm}
  alias PrintClient.{Assets, Users, Printer, Label}
  alias PrintClientWeb.ApiSearchComponent
  import PrintClientWeb.PrintComponents

  require Logger

  def print(%Printer{} = printer, %Label.Template{} = template, params) do
    Logger.info(
      "PrintLive: printing #{template.name} to #{printer.printer_id} with params #{inspect(params)}"
    )

    with %{} = validated when map_size(validated) > 0 <- params,
         rendered <- Label.render(template, validated),
         {:ok, data} <- Label.encode(:tspl, rendered, copies: validated.copies) do
      Printer.add_job(printer.printer_id, data)
    else
      {:error, reason} ->
        Logger.error("PrintLive: failed to render template #{inspect(reason)}")
    end
  end

  def print(printer, template, params), do: dbg([printer, template, params])

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(selected_printer: nil)
      |> assign(selected_template: nil)
      |> assign(template_params: %{})
      |> assign_changes()
      |> assign_options()

    {:ok, socket, temporary_assigns: [results: %AsyncResult{}]}
  end

  @impl true
  def handle_info({:select_printer, printer}, socket) do
    # Tell the current printer to stop.
    if is_struct(socket.assigns.selected_printer, Printer) do
      Printer.Supervisor.stop_printer(socket.assigns.selected_printer.printer_id)
    end

    case printer do
      %Printer{printer_id: _} = printer ->
        Printer.Supervisor.start_printer(printer)

      _ ->
        nil
    end

    {:noreply, socket |> assign(:selected_printer, printer)}
  end

  def handle_info({:select_template, template}, socket),
    do: {:noreply, socket |> assign(:selected_template, template)}

  @impl true
  def handle_event(
        "print",
        params,
        %{assigns: %{selected_printer: printer, selected_template: template}} = socket
      ) do
    {:noreply,
     socket.assigns.template_params
     |> case do
       %{} = validated when map_size(validated) == 0 ->
         # We don't have valid params..
         socket
         |> assign_changes(params)
         |> put_flash(:error, "check form errors")

       params ->
         # We have valid params, print the document and reset the form
         Logger.debug("PrintLive: printing #{template.name} with params #{inspect(params)}")

         print(printer, template, params)

         socket
         |> assign_changes(%{})
         |> put_flash(:info, "sent job")
     end}
  end

  @impl true
  def handle_event("print", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("validate", %{"_target" => ["reset"]}, socket),
    do: {:noreply, assign_changes(socket, %{})}

  @impl true
  def handle_event("validate", params, socket), do: {:noreply, assign_changes(socket, params)}

  @impl true
  def handle_event("clear-printer", _params, socket) do
    send(self(), {:select_printer, nil})
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear-template", _params, socket) do
    send(self(), {:select_template, nil})
    {:noreply, socket}
  end

  def handle_event("options", params, socket),
    do: {:noreply, socket |> assign_options(params)}

  @impl true
  def handle_event("select-user", %{"value" => value, "id" => id}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select-raw", %{"value" => value}, socket) do
    {:noreply, socket}
  end

  defp assign_changes(socket, changes \\ %{}) do
    changeset =
      if socket.assigns.selected_template do
        AssetForm.changeset(
          %AssetForm{},
          changes,
          socket.assigns.selected_template.required_fields
        )
      else
        AssetForm.changeset(%AssetForm{})
      end

    applied =
      Ecto.Changeset.apply_action(changeset, :validate)
      |> case do
        {:ok, applied} -> applied
        {:error, _changeset} -> %{}
      end

    socket =
      socket
      |> assign_async([:results], fn ->
        backend = AssetsApi.backend()

        changes = Map.get(changes, "asset_form", %{})

        all_results =
          changes
          |> Map.take(["asset", "serial", "username"])
          |> Enum.filter(fn {_, v} -> String.length(v) > 3 end)
          |> Enum.reduce(%{}, fn {k, v}, acc ->
            k = String.to_existing_atom(k)

            field_results =
              if k in [:username] do
                AssetsApi.search_users(backend, v)
              else
                AssetsApi.search_assets(backend, v)
              end
              |> case do
                {:ok, results} ->
                  results

                {:error, reason} ->
                  Logger.error("PrintLive: unable to perform search #{inspect(reason)}")
                  []
              end
              |> then(&[%{value: v} | &1])

            Map.put(acc, k, field_results)
          end)

        {:ok, %{results: all_results}}
      end)

    socket
    |> assign(:changeset, %{changeset | action: :validate})
    |> assign(template_params: applied)
  end

  defp assign_options(socket, params \\ %{}) do
    changeset = OptionsForm.changeset(%OptionsForm{}, params)

    socket
    |> assign(options: %{changeset | action: :validate})
  end

  defp get_options(socket) do
    %OptionsForm{}
    |> OptionsForm.changeset(socket.assigns.options)
    |> Ecto.Changeset.apply_action(:validate)
  end
end
