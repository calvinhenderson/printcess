defmodule PrintClientWeb.TemplatesLive do
  use PrintClientWeb, :live_view

  alias PrintClient.{Label, Settings}

  require Logger

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_templates()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-7xl mx-auto pb-20">
        <div class="mb-8 border-b border-base-200 pb-6">
          <h1 class="text-3xl font-bold text-base-content">Templates</h1>
          <p class="text-base-content/60 mt-2">
            Manage label designs and configure file system search paths.
          </p>
        </div>

        <div class="mb-12">
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-xl font-bold flex items-center gap-2">
              <.icon name="hero-document-duplicate" class="w-6 h-6 text-primary" /> Available Designs
              <span class="badge badge-sm badge-ghost font-normal text-xs">
                {length(@templates)} found
              </span>
            </h2>
          </div>

          <div
            :if={@templates == []}
            class="text-center py-12 bg-base-100 border border-dashed border-base-300 rounded-box"
          >
            <div class="opacity-50 mb-2">
              <.icon name="hero-folder-open" class="w-12 h-12 mx-auto" />
            </div>
            <p class="font-bold">No templates found</p>
            <p class="text-sm text-base-content/60">Check your search paths below.</p>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div
              :for={t <- @templates}
              class="card bg-base-100 shadow-sm border border-base-200 transition-all duration-200 hover:shadow-md hover:border-primary/50 group"
            >
              <figure class="bg-base-200/50 h-56 p-6 flex items-center justify-center relative overflow-hidden">
                <div class="w-full h-full flex items-center justify-center transition-transform duration-500 group-hover:scale-105">
                  <img
                    class="max-w-full max-h-full rounded-sm shadow-sm bg-white"
                    src={
                      t.template
                      |> Base.encode64(padding: false)
                      |> then(&"data:image/svg+xml;base64,#{&1}")
                    }
                  />
                </div>
                <div class="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <span class="badge badge-xs font-mono bg-base-100 border-base-300 text-base-content/50">
                    {String.slice(t.id, 0..6)}
                  </span>
                </div>
              </figure>

              <div class="card-body p-5">
                <h3 class="card-title text-base font-bold leading-tight" title={t.name}>
                  {t.name}
                </h3>

                <div class="mt-2">
                  <p class="text-[10px] uppercase font-bold text-base-content/40 mb-1 tracking-wider">
                    Dynamic Fields
                  </p>
                  <div class="flex flex-wrap gap-1.5">
                    <span :if={t.form_fields == []} class="text-xs text-base-content/50 italic">
                      None
                    </span>
                    <span
                      :for={f <- t.form_fields}
                      class="badge badge-sm badge-ghost border-base-200 text-xs text-base-content/70"
                    >
                      {f}
                    </span>
                  </div>
                </div>

                <div class="card-actions justify-end mt-4 pt-4 border-t border-base-100">
                  <div class="join">
                    <button class="btn btn-sm join-item" title="Edit Template">
                      <.icon name="hero-pencil-square" class="w-4 h-4" />
                    </button>
                    <button
                      class="btn btn-sm join-item text-error hover:bg-error/10"
                      title="Delete Template"
                    >
                      <.icon name="hero-trash" class="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div>
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-xl font-bold flex items-center gap-2">
              <.icon name="hero-folder" class="w-6 h-6 text-primary" /> Search Paths
            </h2>
            <button class="btn btn-sm btn-primary btn-outline gap-2">
              <.icon name="hero-plus" class="w-4 h-4" /> Add Path
            </button>
          </div>

          <div class="card bg-base-100 shadow-sm border border-base-200 overflow-hidden">
            <div class="overflow-x-auto">
              <table class="table w-full">
                <thead class="bg-base-200/50 text-base-content/60">
                  <tr>
                    <th class="w-12 text-center">
                      <.icon name="hero-folder-open" class="w-4 h-4 mx-auto" />
                    </th>
                    <th>Directory Path</th>
                    <th class="w-32 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-base-100">
                  <tr :for={l <- @locations} class="hover:bg-base-50 group">
                    <td class="text-center text-base-content/40 group-hover:text-primary">
                      <.icon name="hero-folder" class="w-5 h-5 mx-auto" />
                    </td>
                    <td>
                      <div class="font-mono text-sm text-base-content/80 break-all">
                        {l.path}
                      </div>
                    </td>
                    <td class="text-right">
                      <div
                        :if={l.type == :system}
                        class="flex items-center justify-end gap-2 opacity-60 group-hover:opacity-100 transition-opacity"
                      >
                        <span class="badge badge-sm badge-neutral">system</span>
                      </div>
                      <div
                        :if={l.type == :user}
                        class="flex items-center justify-end gap-2 opacity-60 group-hover:opacity-100 transition-opacity"
                      >
                        <button class="btn btn-square btn-ghost btn-sm tooltip" data-tip="Edit Path">
                          <.icon name="hero-pencil" class="w-4 h-4" />
                        </button>
                        <button
                          class="btn btn-square btn-ghost btn-sm text-error hover:bg-error/10 tooltip"
                          data-tip="Remove Path"
                        >
                          <.icon name="hero-trash" class="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("select", %{"id" => selection_id}, socket) do
    templates =
      socket.assigns.templates
      |> Enum.map(&%{&1 | selected: &1.id == selection_id})

    {:noreply, assign(socket, templates: templates)}
  end

  def handle_event(event, _params, socket) do
    Logger.debug("[PrintClientWeb.TemplatesLive]: Unhandled event received: #{event}")
    {:noreply, socket}
  end

  defp assign_templates(socket) do
    templates =
      Label.Template.load_templates()
      |> Enum.map(&Map.put(&1, :selected, false))

    locations = [
      %{path: Label.Template.internal_templates_path(), type: :system},
      %{path: "./Templates", type: :user},
      %{path: "~/Templates", type: :user},
      %{path: "~/Documents/Templates", type: :user}
    ]

    socket
    |> assign(templates: templates)
    |> assign(:locations, locations)
  end
end
