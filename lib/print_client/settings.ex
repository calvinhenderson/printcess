defmodule PrintClient.Settings do
  alias PrintClient.Repo

  alias PrintClient.Settings.{Printer, Config}

  import Ecto.Query

  require Logger

  # --- Printers ---

  @doc """
  Retreives a single printer from the database.
  """
  def get_printer(printer_id), do: Repo.get(Printer, printer_id)
  def get_printer!(printer_id), do: Repo.get!(Printer, printer_id)

  @doc """
  Builds a printer changeset for making changes.
  """
  def change_printer(printer, attrs \\ %{}),
    do: Printer.changeset(printer, attrs)

  @doc """
  Fetches all saved printers.
  """
  def all_printers() do
    Repo.all(
      from(p in Printer,
        select: p,
        order_by: [desc: p.id],
        order_by: p.name
      )
    )
  end

  @doc """
  Saves a printer to the database.
  """
  def save_printer(printer, attrs \\ %{}) do
    change_printer(printer, attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Deletes a printer from the database.
  """
  def delete_printer(printer = %Printer{}) do
    printer
    |> Repo.delete()
  end

  def delete_printer(printer), do: Logger.error("Invalid printer given: #{inspect(printer)}")

  # --- API Settings ---

  @doc """
  Returns an `Ecto.Changeset` for tracking config changes.
  """
  def change_api(attrs \\ %{}) do
    get_config()
    |> Config.api_changeset(attrs)
  end

  @doc """
  Writes the config to the database.
  """
  def save_api(attrs \\ %{}) do
    get_config()
    |> Config.api_changeset(attrs)
    |> Repo.insert_or_update()
  end

  # --- User Preferences ---

  @doc """
  Returns a list of available UI themes.
  """
  def available_themes, do: Config.available_themes()

  @doc """
  Returns an `Ecto.Changeset` for tracking config changes.
  """
  def change_preferences(attrs \\ %{}) do
    get_config()
    |> Config.preferences_changeset(attrs)
  end

  @doc """
  Writes the config to the database.
  """
  def save_preferences(attrs \\ %{}) do
    get_config()
    |> Config.preferences_changeset(attrs)
    |> Repo.insert_or_update()
  end

  # --- Internal API ---

  def get_config do
    Repo.one(Config)
    |> case do
      nil -> %Config{}
      config -> config
      [config | _] -> config
    end
  end
end
