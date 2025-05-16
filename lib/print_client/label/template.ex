defmodule PrintClient.Label.Template do
  use Ecto.Schema

  import Ecto.Changeset

  require Logger

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

  def load_templates,
    do: load_templates(Application.app_dir(:print_client, "priv/static/templates/"))

  def load_templates(template_dir) do
    File.ls!(template_dir)
    |> Enum.filter(&String.ends_with?(&1, ".svg"))
    |> Enum.reduce([], fn path, acc ->
      path = Path.join(template_dir, path)

      case File.read(path) do
        {:ok, binary} ->
          [
            %{
              name: path,
              template: binary,
              required_fields: [:username, :asset, :serial]
            }
            | acc
          ]

        {:error, reason} ->
          Logger.error(
            "Label.Template: Failed to load template #{path} with reason: #{inspect(reason)}."
          )

          acc
      end
    end)
  end
end
