defmodule PrintClient.Settings do
  alias PrintClient.Repo

  alias PrintClient.Settings.{Printer, Config}

  import Ecto.Query

  ##
  ## Printers

  def get_printer(printer_id), do: Repo.get(Printer, printer_id)

  def change_printer(printer, attrs \\ %{}), do: Printer.changeset(printer, attrs)

  def all_printers() do
    Repo.all(
      from(p in Printer,
        select: p,
        order_by: p.id,
        order_by: p.selected
      )
    )
  end

  def update_printer(%Ecto.Changeset{} = changeset) do
    multi =
      if changeset.data.selected == 1 do
        unset_selected_printers_multi()
      else
        Ecto.Multi.new()
      end

    with {:ok, transaction} <-
           multi
           |> Ecto.Multi.update(:update_printer, changeset)
           |> Repo.transaction() do
      {:ok, transaction.update_printer}
    else
      _ -> :error
    end
  end

  def create_printer(attrs) do
    multi =
      if attrs.selected == 1 do
        unset_selected_printers_multi()
      else
        Ecto.Multi.new()
      end

    changeset = Printer.changeset(%Printer{}, attrs)

    with {:ok, transaction} <-
           multi
           |> Ecto.Multi.insert(:create_printer, changeset)
           |> Repo.transaction() do
      {:ok, transaction.create_printer}
    else
      _ -> :error
    end
  end

  defp unset_selected_printers_multi() do
    Ecto.Multi.new()
    |> Ecto.Multi.update_all(
      :unset_selected_all,
      Printer,
      set: [selected: 0]
    )
  end

  def delete_printer(printer = %Printer{}) do
    printer
    |> Repo.delete()
  end

  def delete_printer(_), do: raise("Invalid printer given")

  ##
  ## IncidentIQ

  @doc """
  Returns the current Settings.Config. If it
  does not exist, a blank config is returned.
  """
  @spec get_settings :: Config.t()
  def get_settings do
    Repo.one(Config)
    |> case do
      nil -> %Config{}
      config -> config
    end
  end

  @doc """
  Returns an `Ecto.Changeset` for tracking config changes.
  """
  def change_settings(attrs \\ %{}) do
    get_settings()
    |> Config.changeset(attrs)
  end

  @doc """
  Writes the config to the database.
  """
  def save_settings(attrs \\ %{}) do
    get_settings()
    |> Config.changeset(attrs)
    |> Repo.insert_or_update()
  end
end
