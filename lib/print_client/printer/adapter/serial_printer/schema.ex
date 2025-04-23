defmodule PrintClient.Printer.Adapter.SerialPrinter.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w| name path |a
  @all_fields @required_fields ++ ~w|  |a

  embedded_schema do
    field :name, :string
    field :path, :string
  end

  def changeset(printer, attrs) do
    printer
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
