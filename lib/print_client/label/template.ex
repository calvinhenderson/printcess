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

  @doc """
  Loads the embedded label templates.
  """
  def load_templates,
    do: load_templates(Application.app_dir(:print_client, "priv/static/templates/"))

  @doc """
  Loads label templates from the specified directory.
  """
  def load_templates(template_dir) do
    File.ls(template_dir)
    |> case do
      {:ok, files} ->
        files

      {:error, reason} ->
        Logger.error(
          "Label.Template: Failed to read templates from directory #{template_dir} with reason #{inspect(reason)}"
        )

        []
    end
    |> Enum.filter(&String.ends_with?(&1, ".svg"))
    |> Enum.reduce([], fn path, acc ->
      maybe_load_template(acc, template_dir, path)
    end)
  end

  defp maybe_load_template(templates, template_dir, template) do
    template_dir
    |> Path.join(template)
    |> File.read()
    |> case do
      {:ok, binary} ->
        Logger.debug("Label.Template: Loaded template #{template} in #{template_dir}")

        [
          %__MODULE__{
            name: template,
            template: binary,
            required_fields: [:username, :asset, :serial]
          }
          | templates
        ]

      {:error, reason} ->
        Logger.error(
          "Label.Template: Failed to load template #{template} with reason: #{inspect(reason)}."
        )

        templates
    end
  end
end
