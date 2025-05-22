defmodule PrintClient.Settings.Config do
  use Ecto.Schema

  import Ecto.Changeset

  @available_themes ~w(
    system light dark
  )a

  @derive {Jason.Encoder, only: ~w(theme instance token)a}
  schema "settings_v2" do
    field :theme, Ecto.Enum, values: @available_themes, default: @available_themes |> List.first()
    field :instance, :string
    field :token, :string
    field :product_id, :string
  end

  def preferences_changeset(config, attrs \\ %{}) do
    config
    |> cast(attrs, [:theme])
    |> validate_inclusion(:theme, @available_themes)
  end

  def available_themes, do: @available_themes

  def api_changeset(config, attrs \\ %{}) do
    changeset =
      config
      |> cast(attrs, [:instance, :token, :product_id])

    fields = [:instance, :token, :product_id]

    has_all_or_none? =
      Enum.all?(fields, &field_missing?(changeset, &1)) or
        Enum.all?(fields, fn field ->
          get_field(changeset, field)
          |> case do
            nil ->
              false

            val when is_binary(val) ->
              String.length(val) > 0
          end
        end)

    if has_all_or_none? do
      changeset
    else
      Enum.reduce(
        fields,
        changeset,
        &add_error(&2, &1, "must have all related fields set or none.")
      )
    end
  end
end
