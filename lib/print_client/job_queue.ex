defmodule PrintClient.JobQueue do
  @moduledoc """
  Manages the Job Queue window.
  """

  alias PrintClientWeb.{Router, Endpoint, JobQueueLive}

  @doc """
  Starts/opens the job queue window.

  ## Example:

      iex> init()
      {:ok, pid}
  """
  def init() do
    Desktop.Window.start_link(
      app: :print_client,
      id: JobQueueWindow,
      title: "Job Queue",
      min_size: {500, 200},
      size: {500, 200},
      icon: "icon.png",
      menubar: nil,
      icon_menu: nil,
      url: Router.Helpers.live_url(Endpoint, JobQueueLive)
    )
    |> case do
      {:error, {:already_started, pid}} ->
        Desktop.Window.show(pid)
        {:ok, pid}

      ok_or_error ->
        ok_or_error
    end
  end
end
