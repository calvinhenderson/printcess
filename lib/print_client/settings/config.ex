defmodule PrintClient.Settings.Config do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {JSON.Encoder, only: ~w(theme instance token)a}
  schema "settings_v2" do
    field :theme, :string
    field :instance, :string
    field :token, :string
  end

  def changeset(config, attrs \\ %{}) do
    config
    |> cast(attrs, [:theme, :instance, :token])
    |> validate_required([:instance, :token])
  end
end
