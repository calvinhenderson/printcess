defmodule PrintClient.Settings.SearchPath do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: ~w(path)a}
  schema "search_paths_v2" do
    field :path, :string
    field :disabled, :boolean, default: false
  end

  def changeset(config, attrs \\ %{}) do
    config
    |> cast(attrs, [:path, :disabled])
    |> validate_required([:path])
  end
end
