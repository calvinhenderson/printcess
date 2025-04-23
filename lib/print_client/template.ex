defmodule PrintClient.Template do
  @moduledoc """
  Provides the interface for defining label templates
  """
  defmacro __using__(_) do
    quote do
      @behaviour PrintClient.Template
      import PrintClient.Template
    end
  end
end
