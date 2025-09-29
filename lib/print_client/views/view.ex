defmodule PrintClient.Views.View do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias PrintClient.Repo
  alias PrintClient.Settings.Printer

  schema "views_v2" do
    field :template, :string
    field :printer_ids, {:array, :string}, virtual: true

    many_to_many :printers, Printer,
      join_through: "views_printers_v2",
      on_replace: :delete

    timestamps(updated_at: nil)
  end

  def changeset(view, attrs \\ %{}) do
    printer_ids =
      (get_in(attrs, ["printer_ids"]) ||
         get_in(attrs, [:printer_ids]) ||
         [])
      |> Enum.uniq()

    printers =
      case printer_ids do
        [_id | _rest] = ids ->
          Repo.all(
            from p in Printer,
              select: p,
              where: p.id in ^ids
          )

        _ ->
          []
      end

    view
    |> cast(attrs, [:template, :printer_ids])
    |> validate_required([:template])
    |> put_assoc(:printers, printers)
    |> dbg()
  end
end
