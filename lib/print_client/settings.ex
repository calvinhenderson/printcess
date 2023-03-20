defmodule PrintClient.Settings do
  alias PrintClient.Repo

  alias PrintClient.Settings.Printer

  import Ecto.Query

  def all_printers() do
    Repo.all(from p in Printer,
      select: p,
      order_by: p.selected,
      order_by: p.id
    )
  end

  def update_printer(printer, attrs) do
    printer
    |> Printer.changeset(attrs)
    |> Repo.update()
  end

  def create_printer(attrs) do
    %Printer{}
    |> Printer.changeset(attrs)
    |> Repo.insert()
  end

  def set_selected_printer(printer) do
    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:unset_selected_all,
        Printer, set: [selected: 0])
    |> Ecto.Multi.update(:set_selected,
        Printer.changeset(printer, %{selected: true}))
    |> Repo.transaction()
  end
end
