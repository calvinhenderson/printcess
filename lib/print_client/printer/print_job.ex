defmodule PrintClient.Printer.PrintJob do
  @moduledoc """
  Provides a structured data type for print jobs.
  """

  alias PrintClient.Label.Template

  defstruct id: 0,
            data: nil,
            template: nil,
            params: %{},
            status: :pending,
            inserted_at: DateTime.now(Calendar.UTCOnlyTimeZoneDatabase)

  @type t :: [
          id: number(),
          data: term(),
          template: Template.t(),
          params: Map.t(),
          status: :pending,
          inserted_at: DateTime.t()
        ]
end
