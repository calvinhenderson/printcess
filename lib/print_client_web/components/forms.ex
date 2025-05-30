defmodule PrintClientWeb.Forms do
  defmodule OptionsForm do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :bind_asset_to_user, :boolean
    end

    def changeset(options, attrs \\ %{}), do: cast(options, attrs, [:bind_asset_to_user])
  end

  defmodule LabelForm do
    use Ecto.Schema
    import Ecto.Changeset

    def changeset(fields, attrs \\ %{}) do
      from_fields(fields)
      |> cast(attrs, from_fields.data)
      |> validate_required(from_fields.data)
      |> validate_number(:copies, greater_than: 0)
    end

    def from_fields(fields) do
      Enum.reduce(fields, {%{}, %{}}, fn {field, type}, {data, types} ->
        {Map.put(data, field, ""), Map.put(types, field, field_type(type))}
      end)
      |> then(fn {data, types} ->
        {Map.put(data, "copies", 1), Map.put(types, "copies", :number)}
      end)
    end

    def field_type("number"), do: :number
    def field_type(_), do: :string
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
      |> cast(attrs, [:copies | required])
      |> validate_required([:copies | required])
      |> validate_number(:copies, greater_than: 0)
    end
  end
end
