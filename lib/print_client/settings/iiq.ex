defmodule PrintClient.Settings.Iiq do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: ~w(instance token)a}
  schema "incidentiq" do
    field(:instance, :string)
    field(:token, :string)
  end

  def changeset(config, attrs \\ %{}) do
    config
    |> cast(attrs, [:instance, :token])
    |> validate_required([:instance, :token])
  end
end
