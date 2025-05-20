defmodule PrintClient.Settings.Config do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: ~w(theme instance token)a}
  schema "settings_v2" do
    field :theme, :string
    field :instance, :string
    field :token, :string
    field :product_id, :string
  end

  def changeset(config, attrs \\ %{}) do
    config
    |> cast(attrs, [:theme, :instance, :token, :product_id])
    |> validate_required([:instance, :token, :product_id])
  end
end
