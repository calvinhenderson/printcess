defmodule PrintClient.Window do
  @moduledoc """
  A base module for creating windows.
  """

  @default_window_size {400, 380}

  @callback opts :: [
              window: pid(),
              title: String.t(),
              size: {number(), number()},
              fixed_size?: boolean(),
              url: Function.t()
            ]

  defmacro __using__(module_opts) do
    quote do
      @behaviour PrintClient.Window

      use GenServer

      def start_link(_) do
        init(nil)
      end

      def opts, do: unquote(module_opts)

      @impl true
      def init(_opts) do
        window = Keyword.fetch!(unquote(module_opts), :window)
        title = Keyword.fetch!(unquote(module_opts), :title) <> " - Print Client"
        url = Keyword.fetch!(unquote(module_opts), :url)
        size = Keyword.get(unquote(module_opts), :size, unquote(@default_window_size))
        fixed_size = Keyword.get(unquote(module_opts), :fixed_size, false)
        menubar = Keyword.get(unquote(module_opts), :menubar, nil)
        icon_menu = Keyword.get(unquote(module_opts), :icon_menu, nil)

        result =
          [
            app: :print_client,
            id: window,
            title: title,
            size: size,
            icon: "icon.png",
            menubar: menubar,
            icon_menu: icon_menu,
            url: url
          ]
          |> Desktop.Window.start_link()
          |> dbg()

        if fixed_size do
          set_fixed_size(size)
        end

        result
      end

      def show do
        if is_nil(Process.whereis(unquote(module_opts)[:window])) do
          init(unquote(module_opts))
        end

        Desktop.Window.show(unquote(module_opts)[:window])
      end

      def hide, do: Desktop.Window.hide(unquote(module_opts)[:window])

      @spec set_fixed_size({number(), number()}) :: :ok
      def set_fixed_size(size) do
        window = Keyword.fetch!(unquote(module_opts), :window)
        :wx.set_env(Desktop.Env.wx_env())
        frame = Desktop.Window.frame(window)

        {w, _h} = :wxWindow.getSize(frame)

        # fixes wxwidgets complaining about max size < min size, vice versa
        if elem(size, 0) <= w do
          :wxWindow.setMinSize(frame, size)
          :wxWindow.setMaxSize(frame, size)
        else
          :wxWindow.setMaxSize(frame, size)
          :wxWindow.setMinSize(frame, size)
        end

        :wxWindow.setSize(frame, size)

        :ok
      end
    end
  end
end
