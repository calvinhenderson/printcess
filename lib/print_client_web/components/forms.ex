defmodule PrintClientWeb.Forms do
  defmodule OptionsForm do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :bind_asset_to_user, :boolean
    end

    def changeset(options, attrs \\ %{}), do: cast(options, attrs, [:bind_asset_to_user])
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
