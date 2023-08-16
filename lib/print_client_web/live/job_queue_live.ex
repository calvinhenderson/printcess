defmodule PrintClientWeb.JobQueueLive do
  use PrintClientWeb, :live_view

  alias PrintClient.Printer.Queue

  require Logger

  @impl true
  def mount(_params, _assigns, socket) do
    if connected?(socket), do: Queue.subscribe()

    jobs = Queue.list_jobs()

    socket =
      socket
      |> stream(:jobs, jobs, at: -1)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <table id="jobs" class="w-full text-left overflow-scroll max-w-max" phx-hook="TimestampHook">
    <thead>
      <tr class="font-bold">
        <th class="min-w-[10rem]">Value</th>
        <th class="min-w-[8rem]">Printer</th>
        <th class="w-12">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </th>
        <th class="max-w-min">Copies</th>
        <th class="min-w-max"></th>
      </tr>
    </thead>
    <tbody id="jobs-queue" phx-update="stream">
      <tr :for={{job_id, job} <- @streams.jobs} id={job_id}>
        <td>
          <%= case job do
            %{text: text} -> text
            %{asset: asset, serial: serial} -> asset <> "," <> serial
          end %>
        </td>
        <td>
          <%= job.printer.name %>
        </td>
        <td data-timestamp={job.entered_queue_at |> DateTime.to_iso8601()}></td>
        <td>
          <%= job.copies %>
        </td>
        <td>
            <.button type="button"
                     phx-click="delete-job"
                     phx-value-job-id={job_id}
                     phx-disable-with="..."
                     class="text-base-content w-8 h-8 flex justify-center items-center !p-2 phx-no-feedback:disabled phx-click-loading:disabled ml-2">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
              </svg>
            </.button>
        </td>
      </tr>
    </tbody>
    </table>
    """
  end

  @impl true
  def handle_event("delete-job", %{"job-id" => "jobs-" <> job_id}, socket) do
    {id, _} = Integer.parse(job_id)
    Queue.delete_job(id)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:push, job}, socket) do
    {:noreply, stream_insert(socket, :jobs, job)}
  end

  @impl true
  def handle_info({:delete, job_id}, socket) do
    Logger.debug("job deleted: #{inspect(job_id)}")
    {:noreply, stream_delete_by_dom_id(socket, :jobs, "jobs-" <> job_id)}
  end
end
