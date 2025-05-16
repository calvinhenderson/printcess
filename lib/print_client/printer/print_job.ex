defmodule PrintClient.Printer.PrintJob do
  defstruct id: 0, data: nil, inserted_at: DateTime.now(Calendar.UTCOnlyTimeZoneDatabase)
  @type t :: [id: number(), data: term(), inserted_at: DateTime.t()]
end
