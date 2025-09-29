defmodule PrintClient.Views do
  @moduledoc """
  Provides an API for accessing saved and recent views.
  """

  alias PrintClient.Repo

  alias PrintClient.Views.View

  import Ecto.Query

  require Logger

  # --- Views ---

  @doc """
  Retreives a single view from the database.
  """
  def get_view(view_id), do: Repo.get(View, view_id) |> preload
  def get_view!(view_id), do: Repo.get!(View, view_id) |> preload

  @doc """
  Builds a view changeset for making changes.
  """
  def change_view(view, attrs \\ %{}),
    do: View.changeset(view, attrs)

  @doc """
  Fetches all saved views.
  """
  def all_views do
    Repo.all(
      from(v in View,
        select: v,
        preload: [:printers],
        order_by: [desc: v.id]
      )
    )
  end

  @doc """
  Fetches only saved views.
  """
  def saved_views do
    Repo.all(
      from(v in View,
        select: v,
        where: not v.temp,
        preload: [:printers],
        order_by: [desc: v.id]
      )
    )
  end

  @doc """
  Fetches only recent (unsaved) views.
  """
  def recent_views do
    Repo.all(
      from(v in View,
        select: v,
        where: v.temp,
        preload: [:printers],
        order_by: [desc: v.id],
        order_by: v.name
      )
    )
  end

  @doc """
  Saves a view to the database.
  """
  def save_view(view, attrs \\ %{}) do
    change_view(view, attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Deletes a view from the database.
  """
  def delete_view(view) when is_binary(view), do: delete_view(%View{id: view})

  def delete_view(view) when is_struct(view) do
    Repo.delete(view)
  end

  defp preload(view) do
    Repo.preload(view, [:printers])
  end
end
