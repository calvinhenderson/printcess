defmodule PrintClient.Label.Template do
  require Logger

  @type template_field :: %{binary() => {atom(), binary() | nil}}

  defstruct id: "",
            path: "",
            name: "",
            template: "",
            fields: [],
            form_fields: []

  @type t :: [
          id: binary(),
          path: binary(),
          name: binary(),
          template: binary(),
          fields: [template_field],
          form_fields: [atom()]
        ]

  @doc """
  Returns the internal template directory.
  """
  def internal_templates_path, do: Application.app_dir(:print_client, "priv/static/templates/")

  @doc """
  Lists template paths.
  """
  def list_templates, do: [internal_templates_path()] |> list_templates

  def list_templates(templates_dirs) do
    Enum.flat_map(templates_dirs, fn dir ->
      File.ls(dir)
      |> case do
        {:ok, files} ->
          files

        {:error, reason} ->
          Logger.error(
            "Label.Template: Failed to read templates from directory #{dir} with reason #{inspect(reason)}"
          )

          []
      end
      |> Enum.filter(&String.ends_with?(&1, ".svg"))
      |> Enum.map(fn path ->
        name =
          path
          |> Path.basename(".svg")
          |> String.trim()
          |> String.capitalize()

        full_path = Path.join(dir, path)

        {full_path, name}
      end)
    end)
  end

  @doc """
  Loads the embedded label templates.
  """
  def load_templates,
    do: list_templates() |> load_templates

  @doc """
  Loads label templates from the specified directory.
  """
  def load_templates(templates) do
    templates
    |> Enum.reduce([], fn template, acc ->
      maybe_load_template(acc, template)
    end)
  end

  defp maybe_load_template(templates, {template_path, template_name}) do
    template_path
    |> File.read()
    |> case do
      {:ok, binary} ->
        Logger.debug("Label.Template: Loaded template #{template_path}")

        formatted_name =
          template_path
          |> Path.basename(".svg")
          |> String.trim()

        template_fields = dynamic_fields(binary)

        form_fields =
          template_fields
          |> Enum.reduce([], fn {_, {v, _}}, acc -> [v | acc] end)
          |> Enum.uniq()
          |> Enum.reverse()

        [
          %__MODULE__{
            id: Regex.replace(~r/[^A-z0-9_-]/, String.downcase(template_name), "_"),
            path: template_path,
            name: template_name,
            template: binary,
            fields: template_fields,
            form_fields: form_fields
          }
          | templates
        ]

      {:error, reason} ->
        Logger.error(
          "Label.Template: Failed to load #{template_path} with reason: #{inspect(reason)}."
        )

        templates
    end
  end

  defp dynamic_fields(template) do
    # TODO: Figure out a way to limit which variables can be used.
    fields =
      Regex.scan(~r/{{\s*(?<variable>[^}\s]+)(?<type> \[[^}\s]+\])?\s*}}/, template)
      |> Enum.reduce(%{}, fn match, acc ->
        case match do
          [match, variable, params] ->
            var_atom = String.to_atom(variable)
            Map.put(acc, match, {var_atom, params})

          [match, variable] ->
            var_atom = String.to_atom(variable)
            Map.put(acc, match, {var_atom, nil})

          _ ->
            nil
        end
      end)

    Logger.info(inspect(fields))

    fields
  end
end
