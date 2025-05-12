defmodule PrintClient.Printer.SerialPrinterConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w| name path |a
  @all_fields @required_fields ++ ~w|  |a

  embedded_schema do
    field :name, :string
    field :path, :string
    field :sort, :integer, default: 0
  end

  def changeset(printer, attrs) do
    printer
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> validate_number(:sort, min: 0, max: 0)
  end
end
