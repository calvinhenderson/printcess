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
      |> validate_required([:copies | required])
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

  # For now, we only persist the copies field.
  @persisted_form_fields ~w(copies)

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
      |> assign(selected_printers: [])
      |> assign(selected_template: nil)
      |> assign(template_params: %{})
      |> assign_changes()
      |> assign_options()

    {:ok, socket, temporary_assigns: [results: %AsyncResult{}]}
  end

  @impl true
  def handle_info({:select_printer, printer}, socket) do
    # Tell the current printer to stop.
    socket =
      case printer do
        %Printer{printer_id: _} = printer ->
          Printer.Supervisor.start_printer(printer)

          socket
          |> assign(selected_printers: [printer | socket.assigns.selected_printers])

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def handle_info({:select_template, template}, socket),
    do: {:noreply, socket |> assign(:selected_template, template)}

  @impl true
  def handle_event(
        "print",
        %{"asset_form" => params},
        %{assigns: %{selected_printers: printers, selected_template: template}} = socket
      ) do
    dbg(socket.assigns)

    with true <- length(printers) > 0,
         %Label.Template{required_fields: fields} <- template,
         changeset <- AssetForm.changeset(%AssetForm{}, params, fields),
         {:ok, validated} <- Ecto.Changeset.apply_action(changeset, :validate),
         {:ok, job_id} <- print(printers, template, validated) do
      # We have valid params, print the document and reset the form
      Logger.debug("PrintLive: sent job #{template.name} with params #{inspect(params)}")

      persisted =
        params
        |> Map.take(@persisted_form_fields)
        |> dbg()

      socket
      |> assign_changes(persisted)
      |> put_flash(:info, "Printing..")
    else
      false ->
        socket
        |> assign_changes(params)
        |> put_flash(:error, "Please select a printer.")

      nil ->
        socket
        |> assign_changes(params)
        |> put_flash(:error, "Please select a template.")

      {:error, %Ecto.Changeset{}} ->
        socket
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

  def handle_event("validate", %{"_target" => ["reset"]}, socket),
    do: {:noreply, assign_changes(socket, %{})}

  def handle_event("validate", %{"asset_form" => params}, socket),
    do: {:noreply, assign_changes(socket, params)}

  def handle_event("clear-printer", %{"id" => printer_id}, socket) do
    # Stop the printer service
    Printer.Supervisor.stop_printer(printer_id)

    # Remove it from the selected list
    printers =
      socket.assigns.selected_printers
      |> Enum.reject(&(&1.printer_id == printer_id))

    {:noreply, socket |> assign(selected_printers: printers)}
  end

  def handle_event("clear-template", _params, socket) do
    send(self(), {:select_template, nil})
    {:noreply, socket}
  end

  def handle_event("options", params, socket),
    do: {:noreply, socket |> assign_options(params)}

  def handle_event("select-user", %{"value" => value, "id" => id}, socket) do
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
end
