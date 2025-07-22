defmodule PrintClient.Window.JobQueue do
  alias PrintClientWeb.{Router, Endpoint, JobQueueLive}

  use PrintClient.Window,
    window: JobQueueWindow,
    title: "Job Queue",
    size: {500, 200},
    fixed_size: true,
    url: fn -> Router.Helpers.live_url(Endpoint, JobQueueLive) end
end
