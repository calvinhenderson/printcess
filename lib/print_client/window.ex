defmodule PrintClient.Window do
  @moduledoc """
  A base module for creating windows.
  """

  @default_window_size {900, 950}

  @type frame_size :: {number(), number()} | nil

  @callback opts :: [
              window: pid(),
              title: String.t(),
              initial_size: frame_size,
              min_size: frame_size,
              max_size: frame_size,
              url: Function.t()
            ]

  defmacro __using__(module_opts) do
    quote do
      @behaviour PrintClient.Window

      @type frame_size :: {number(), number()} | nil

      use GenServer

      def start_link(_) do
        init(nil)
      end

      def opts, do: unquote(module_opts)

      @impl true
      def init(_opts) do
        window = Keyword.fetch!(unquote(module_opts), :window)
        title = Keyword.fetch!(unquote(module_opts), :title)
        url = Keyword.fetch!(unquote(module_opts), :url)
        initial_size = Keyword.get(unquote(module_opts), :size, unquote(@default_window_size))
        min_size = Keyword.get(unquote(module_opts), :min_size)
        max_size = Keyword.get(unquote(module_opts), :max_size)
        menubar = Keyword.get(unquote(module_opts), :menubar, PrintClient.MenuBar)
        icon_menu = Keyword.get(unquote(module_opts), :icon_menu, PrintClient.Menu)

        result =
          [
            app: :print_client,
            id: window,
            title: title,
            initial_size: initial_size,
            min_size: min_size,
            max_size: max_size,
            icon: "icon.png",
            menubar: menubar,
            icon_menu: icon_menu,
            url: fn -> Path.join(PrintClientWeb.Endpoint.url(), url) end
          ]
          |> Desktop.Window.start_link()

        set_window_size(initial_size, min_size, max_size)

        result
      end

      def show do
        if is_nil(Process.whereis(unquote(module_opts)[:window])) do
          init(unquote(module_opts))
        end

        Desktop.Window.show(unquote(module_opts)[:window])
      end

      def hide, do: Desktop.Window.hide(unquote(module_opts)[:window])

      def load_url(url) do
        window = Keyword.fetch!(unquote(module_opts), :window)
        :wx.set_env(Desktop.Env.wx_env())
        webview = Desktop.Window.webview(window)

        :wxWebView.loadURL(webview, Path.join(PrintClientWeb.Endpoint.url(), url))
      end

      @spec set_window_size(frame_size, frame_size, frame_size) :: :ok
      def set_window_size(initial_size, min_size, max_size) do
        window = Keyword.fetch!(unquote(module_opts), :window)
        :wx.set_env(Desktop.Env.wx_env())
        frame = Desktop.Window.frame(window)

        if initial_size, do: :wxWindow.setSize(frame, initial_size)
        if min_size, do: :wxWindow.setMinSize(frame, min_size)
        if max_size, do: :wxWindow.setMaxSize(frame, max_size)
      end
    end
  end
end
