defmodule PrintClient.Settings.Printer do
  use Ecto.Schema

  import Ecto.Changeset

  schema "printers" do
    field :name, :string
    field :hostname, :string
    field :port, :integer
    field :selected, :integer
  end

  def changeset(printer, attrs \\ %{}) do
    printer
    |> cast(attrs, [:name, :hostname, :port, :selected])
    |> validate_required([:name, :hostname])
    |> unique_constraint([:hostname])
  end
end
