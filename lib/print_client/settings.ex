defmodule PrintClient.Settings do
  alias PrintClient.Repo

  alias PrintClient.Settings.{Printer, Config}

  import Ecto.Query

  ##
  ## Printers

  @doc """
  Retreives a single printer from the database.
  """
  def get_printer(printer_id), do: Repo.get(Printer, printer_id)

  @doc """
  Builds a printer changeset for making changes.
  """
  def change_printer(printer, attrs \\ %{}), do: Printer.changeset(printer, attrs)

  @doc """
  Fetches all saved printers.
  """
  def all_printers() do
    Repo.all(
      from(p in Printer,
        select: p,
        order_by: p.id,
        order_by: p.name
      )
    )
  end

  @doc """
  Saves a printer to the database.
  """
  def save_printer(printer, attrs \\ %{}) do
    printer
    |> Printer.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def delete_printer(printer = %Printer{}) do
    printer
    |> Repo.delete()
  end

  def delete_printer(printer), do: Logger.error("Invalid printer given: #{inspect(printer)}")

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
