defmodule PrintClientWeb.FormComponents do
  use PrintClientWeb, :component

  @doc """
  Renders a label form for printing.
  """
  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:actions, :list, required: true)
  attr(:printer, :string)
  attr(:rest, :global)

  def label_form(assigns) do
    ~H"""
    <.form for={@form} class="flex flex-col gap-2" {@rest}>
      <div class="grid grid-cols-[2fr_3fr] items-center">
        <span><%= gettext("Owner") %></span>
        <.input
          type="text"
          field={@form[:owner]}
          required={@form[:action].value in ["both", "owner"]}
          disabled={@form[:action].value in ["asset"]}
        />
        <span><%= gettext("Asset Tag") %></span>
        <.input
          type="text"
          field={@form[:asset]}
          required={@form[:action].value in ["both", "asset"]}
          disabled={@form[:action].value in ["owner"]}
        />
        <span><%= gettext("Serial Number") %></span>
        <.input
          type="text"
          field={@form[:serial]}
          required={@form[:action].value in ["both", "asset"]}
          disabled={@form[:action].value in ["owner"]}
        />
      </div>

      <.input type="button-group" field={@form[:action]} options={@actions} />

      <button type="submit" class="btn btn-primary btn-md w-full grow">
        <%= if @printer do %>
          <%= gettext("Print to") %> <%= @printer %>
        <% else %>
          <%= gettext("Print label(s)") %>
        <% end %>
      </button>
    </.form>
    """
  end

  @doc """
  Renders a query form for searching for assets.
  """
  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:rest, :global)

  def query_form(assigns) do
    ~H"""
    <.form for={@form} {@rest}>
      <div class="flex flex-row items-stretch">
        <.input
          type="select"
          options={@form[:fields].value}
          tabindex="0"
          field={@form[:selected_field]}
          style="border-radius: 0.5rem 0 0 0.5rem;"
        />
        <.input
          type="text"
          style="margin-left: -1px; margin-right: -0.5rem; border-radius: 0; width: 100%;"
          tabindex="0"
          field={@form[:query]}
          placeholder={gettext("Enter a search query")}
          phx-debounce="300"
        />
        <button
          type="submit"
          class={[
            "input input-bordered mt-2 -ml-[2px] !rounded-l-none"
          ]}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke-width="1.5"
            stroke="currentColor"
            class="w-6 h-6"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z"
            />
          </svg>
        </button>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a vertical timeline of jobs.
  """

  attr(:jobs, Phoenix.LiveView.LiveStream, required: true)

  def job_list(assigns) do
    ~H"""
    <ul
      id="jobs"
      class="timeline timeline-vertical timeline-compact"
      phx-update="stream"
      phx-hook="TimestampHook"
    >
      <%= for {id, job} <- @jobs do %>
        <li id={id} class="group items-end">
          <hr class="group-first:hidden" />
          <div class={[
            "timeline-start timeline-box grid gap-4",
            "grid-cols-5"
          ]}>
            <%= if job.text do %>
              <svg
                viewBox="0 0 24 24"
                class="w-6 h-6"
                stroke-width="1.5"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M3 7L3 5L17 5V7"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                </path>
                <path
                  d="M10 5L10 19M10 19H12M10 19H8"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                </path>
                <path
                  d="M13 14L13 12H21V14"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                </path>
                <path
                  d="M17 12V19M17 19H15.5M17 19H18.5"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                </path>
              </svg>
              <span class="col-span-4"><%= job.text %></span>
            <% end %>
            <%= if job.asset do %>
              <svg
                stroke-width="1.5"
                class="w-6 h-6"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M3.2 14.2222V4C3.2 2.89543 4.09543 2 5.2 2H18.8C19.9046 2 20.8 2.89543 20.8 4V14.2222M3.2 14.2222H20.8M3.2 14.2222L1.71969 19.4556C1.35863 20.7321 2.31762 22 3.64418 22H20.3558C21.6824 22 22.6414 20.7321 22.2803 19.4556L20.8 14.2222"
                  stroke-width="1.5"
                  stroke="currentColor"
                >
                </path>
                <path
                  d="M11 19L13 19"
                  stroke="currentColor"
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                </path>
              </svg>

              <p class="col-span-4">
                <span>Asset: <%= job.asset %></span>
                <br />
                <span>Serial: <%= job.serial %></span>
              </p>
            <% end %>

            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="w-6 h-6"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
              />
            </svg>
            <div
              class="col-span-4 tooltip tooltip-top"
              data-tip={job.entered_queue_at |> DateTime.to_iso8601()}
            >
              Time in queue <span data-timestamp={job.entered_queue_at}></span>
            </div>
          </div>
          <div class="timeline-middle">
            <%= case job.status do %>
              <% :deleted -> %>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  class="w-6 h-6 text-error"
                >
                  <path
                    fill-rule="evenodd"
                    d="M16.5 4.478v.227a48.816 48.816 0 0 1 3.878.512.75.75 0 1 1-.256 1.478l-.209-.035-1.005 13.07a3 3 0 0 1-2.991 2.77H8.084a3 3 0 0 1-2.991-2.77L4.087 6.66l-.209.035a.75.75 0 0 1-.256-1.478A48.567 48.567 0 0 1 7.5 4.705v-.227c0-1.564 1.213-2.9 2.816-2.951a52.662 52.662 0 0 1 3.369 0c1.603.051 2.815 1.387 2.815 2.951Zm-6.136-1.452a51.196 51.196 0 0 1 3.273 0C14.39 3.05 15 3.684 15 4.478v.113a49.488 49.488 0 0 0-6 0v-.113c0-.794.609-1.428 1.364-1.452Zm-.355 5.945a.75.75 0 1 0-1.5.058l.347 9a.75.75 0 1 0 1.499-.058l-.346-9Zm5.48.058a.75.75 0 1 0-1.498-.058l-.347 9a.75.75 0 0 0 1.5.058l.345-9Z"
                    clip-rule="evenodd"
                  />
                </svg>
              <% :complete -> %>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  class="w-6 h-6 text-success"
                >
                  <path
                    fill-rule="evenodd"
                    d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12Zm13.36-1.814a.75.75 0 1 0-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 0 0-1.06 1.06l2.25 2.25a.75.75 0 0 0 1.14-.094l3.75-5.25Z"
                    clip-rule="evenodd"
                  />
                </svg>
              <% _ -> %>
                <span class="loading loading-spinner loading-md w-6 h-6"></span>
            <% end %>
          </div>
          <hr class="group-last:hidden" />
        </li>
      <% end %>
    </ul>
    """
  end
end
