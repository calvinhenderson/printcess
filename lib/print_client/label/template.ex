defmodule PrintClient.Label.Template do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :template, :string
    field :required_fields, {:array, Ecto.Enum}, values: [:username, :asset, :serial]
  end

  def changeset(template, attrs) do
    template
    |> cast(attrs, [:name, :template, :required_fields])
    |> validate_required([:name, :template, :required_fields])
  end
end
