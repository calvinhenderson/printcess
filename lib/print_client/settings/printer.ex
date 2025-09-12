defmodule PrintClient.Settings.Printer do
  use Ecto.Schema

  import Ecto.Changeset

  @derive {Jason.Encoder, only: ~w(name hostname port)a}
  schema "printers_v2" do
    field :name, :string
    field :hostname, :string
    field :port, :integer
    field :serial_port, :string
    field :vendor_id, :string
    field :product_id, :string
    field :encoding, :string
    field :autoconnect, :boolean
    field :type, Ecto.Enum, values: [:network, :serial, :usb]
  end

  def changeset(printer, attrs \\ %{}) do
    type =
      case attrs do
        %{"type" => type} when is_binary(type) -> String.to_existing_atom(type)
        %{"type" => type} -> type
        %{type: type} when is_binary(type) -> String.to_existing_atom(type)
        %{type: type} -> type
        _ -> nil
      end

    type
    |> case do
      nil -> Map.get(printer, :type, :network)
      type -> type
    end
    |> case do
      nil -> network_printer_changeset(printer, attrs)
      :network -> network_printer_changeset(printer, attrs)
      :serial -> serial_printer_changeset(printer, attrs)
      :usb -> usb_printer_changeset(printer, attrs)
    end
  end

  def network_printer_changeset(printer, attrs \\ %{}) do
    printer
    |> cast(attrs, [:name, :hostname, :port, :encoding, :autoconnect])
    |> validate_required([:name, :hostname])
    |> unique_constraint([:hostname, :encoding])
    |> put_change(:type, :network)
  end

  def serial_printer_changeset(printer, attrs \\ %{}) do
    printer
    |> cast(attrs, [:name, :serial_port, :encoding, :autoconnect])
    |> validate_required([:name, :serial_port])
    |> unique_constraint([:serial_port, :encoding])
    |> put_change(:type, :serial)
  end

  def usb_printer_changeset(printer, attrs \\ %{}) do
    printer
    |> cast(attrs, [:name, :vendor_id, :product_id, :encoding, :autoconnect])
    |> validate_required([:name, :vendor_id, :product_id])
    |> unique_constraint([:vendor_id, :product_id, :encoding])
    |> put_change(:type, :usb)
  end
end
