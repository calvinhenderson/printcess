defmodule PrintClient.Label.Template do
  require Logger

  @type template_field :: %{binary() => {atom(), binary() | nil}}

  defstruct id: "",
            name: "",
            template: "",
            fields: [],
            form_fields: []

  @type t :: [
          id: binary(),
          name: binary(),
          template: binary(),
          fields: [template_field],
          form_fields: [atom()]
        ]

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

        formatted_name =
          template
          |> String.trim()
          |> then(&Regex.replace(~r/\.\w+$/, &1, ""))

        template_fields = dynamic_fields(binary)

        form_fields =
          template_fields
          |> Enum.reduce([], fn {_, {v, _}}, acc -> [v | acc] end)
          |> Enum.uniq()
          |> Enum.reverse()

        [
          %__MODULE__{
            id: Regex.replace(~r/[^A-z0-9_-]/, formatted_name, "_"),
            name: String.capitalize(formatted_name),
            template: binary,
            fields: template_fields,
            form_fields: form_fields
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

  defp dynamic_fields(template) do
    # TODO: Figure out a way to limit which variables can be used.
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
  end
end
