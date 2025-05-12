defmodule PrintClient.Printer.NetworkPrinterConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w| name host |a
  @all_fields @required_fields ++
                ~w| port sort |a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "printers" do
    field :name, :string
    field :host, :string
    field :port, :integer, default: 9100
    field :sort, :integer, default: 1
  end

  def changeset(printer, attrs) do
    printer
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> validate_number(:sort, min: 1)
  end
end
