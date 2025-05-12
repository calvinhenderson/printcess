defmodule PrintClient.Printer do
  @moduledoc """
  Interfaces with label printers through the use of protocols and adapters.
  """

  alias PrintClient.Label.Template

  @pubsub PrintClient.PubSub
  @job_topic "print_job:"

  @doc """
  Prints a template with the provided params.

  The returned job_id can be subscribed to to receive updates on its status.

  ### Arguments
  * `config`: A printing adapter struct.
  * `template`: A label template name.

  ### Returns
  * `{:ok, job_id}` if the job was successfully queued.
  * `{:error, reason}` if an error occurred.
  """
  @spec subscribe(struct(), binary(), Map.t()) :: {:ok, term()} | {:error, term()}
  def print(config, template, params \\ %{})

  @doc """
  Subscribes to a specific job topic for receiving status notifications.

  If you want to listen to all jobs, then you should subscribe to the queue's topic instead.

  ### Arguments
  * `job_id`: The id of the print.

  ### Returns
  * `:ok` if the subscription is successful.
  * `{:error, reason}` if an error occurred.
  """
  @spec subscribe(term()) :: :ok | {:error, term()}
  def subscribe(job_id), do: Phoenix.PubSub.subscribe(@pubsub, @job_topic <> job_id)
end
