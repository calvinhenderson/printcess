defmodule Mix.Tasks.Bundle do
  @moduledoc "Bundles the app for desktop distribution: `mix bundle`"

  use Mix.Task

  @os :os.type()

  def run(_) do
    case :os.type() do
      {:unix, :darwin} ->
        run_macosx()

      _ ->
        log(:warn, "nothing to do", "app bundles are only supported on macOS.")
        :ok
    end
  end

  # defp bundle_dir() when {:unix, _} == @os, do: Path.join(Mix.Project.app_path(), "rel/bundle/#{@os |> elem(1)}")
  # defp bundle_dir() when {:win32, _} == @os, do: Path.join(Mix.Project.app_path(), "rel/bundle/#{@os |> elem(0)")
  defp build_dir(), do: Mix.Project.build_path()
  defp bundle_dir(), do: Path.join(Mix.Project.build_path(), "bundle")

  defp run_macosx do
    %{
      app: Mix.Project.config()[:app],
      name: "Print Client",
      bundle_identifier: "org.etownschools.exprint",
      version: Mix.Project.config()[:version]
    }
    |> setup_dirs
    |> copy_files
    |> build_icns_file
    |> build_info_plist
    |> create_start_script

    :ok
  end

  defp setup_dirs(config) do
    bundle = bundle_dir()
    build = build_dir()

    log(:info, "cleaning", "old bundle files")

    for file <- Path.wildcard(Path.join(bundle, "*"), match_dot: true) do
      if file != "." and file != "..", do: File.rm_rf(file)
    end

    unless File.dir?(bundle) do
      File.mkdir_p!(bundle)
    end

    app_base_path = Path.join(bundle, "#{config.name}.app")

    File.mkdir_p!(Path.join([app_base_path, "Contents", "MacOS"]))
    File.mkdir_p!(Path.join([app_base_path, "Contents", "Resources"]))

    unless File.dir?(build) do
      log(:error, "release not found", build)
    end

    config
    |> Map.put(:app_base_path, app_base_path)
  end

  defp copy_files(config) do
    res_path = Path.join(build_dir(), "rel/app")
    rel_path = Path.join(config.app_base_path, "Contents/Resources")

    File.cp_r!(res_path, rel_path)

    config
  end

  defp build_icns_file(config) do
    icns_file = Path.join(config.app_base_path, "Contents/Resources/icon.icns")

    unless File.dir?(Path.dirname(icns_file)) do
      File.mkdir_p!(Path.dirname(icns_file))
    end

    icon_dir = Path.join(build_dir(), "icon.iconset")

    unless File.dir?(icon_dir) do
      File.mkdir_p!(icon_dir)
    end

    icon_file = Application.app_dir(:print_client, "priv/icon.png")

    sizes = [16, 32, 64, 128, 256, 512, 1024]
    retina = [16, 32, 128, 256, 512]

    # Create regular icons
    for size <- sizes do
      cmd("sips -z #{size} #{size} #{icon_file} --out #{icon_dir}/icon_#{size}x#{size}.png")
    end

    # Create retina icons
    for size <- retina do
      cmd(
        "sips -z #{size * 2} #{size * 2} #{icon_file} --out #{icon_dir}/icon_#{size}x#{size}@2x.png"
      )
    end

    log(:info, "iconutil", cmd("iconutil -c icns #{icon_dir} -o \"#{icns_file}\""))

    # File.rm_rf!(icon_dir)

    log(:info, "created", "macOS app icon: \"#{icns_file}\"")

    Map.merge(%{icns_file: icns_file}, config)
  end

  defp build_info_plist(config) do
    data = ~s(<?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http\\://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key>
        <string>start</string>
        <key>CFBundleDisplayName</key>
        <string>#{config.name}</string>
        <key>CFBundleIdentifier</key>
        <string>#{config.bundle_identifier}</string>
        <key>CFBundleName</key>
        <string>#{config.name}</string>
        <key>CFBundleVersion</key>
        <string>#{config.version}</string>
        <key>CFBundleIconFile</key>
        <string>#{Path.basename(config.icns_file)}</string>
        <key>NSHighResolutionCapable</key>
        <string>True</string>
        <key>LSMinimumSystemVersion</key>
        <string>10</string>
        <key>LSArchitecturePriority</key>
        <array>
          <string>x86_64</string>
        </array>
        <key>NSAppTransportSecurity</key>
        <dict>
          <key>NSAllowsArbitraryLoads</key>
          <true/>
        </dict>
      </dict>
      </plist>)

    plist_file = Path.join(config.app_base_path, "Contents/Info.plist")

    File.write!(plist_file, data, [:write, :utf8])

    log(:info, "created", "Info.plist")

    Map.merge(%{info_plist: plist_file}, config)
  end

  defp create_start_script(config) do
    script =
      ~s"""
      #!/usr/bin/env sh
      SELF=$(readlink "$0" || true)
      if [ -z "$SELF" ]; then SELF="$0"; fi
      ROOT="$(cd "$(dirname "$SELF")" && pwd -P)"

      COMMAND="$1"
      if [ -z "$COMMAND" ]; then COMMAND="start"; fi

      "$ROOT/../Resources/bin/app" $COMMAND
      """
      |> String.trim()

    start_path = Path.join(config.app_base_path, "Contents/MacOS/start")

    File.mkdir_p!(Path.dirname(start_path))
    File.write!(start_path, script)
    File.chmod!(start_path, 0o755)

    log(:info, "created", "app start script")

    config
  end

  defp cmd(command) do
    :os.cmd(to_charlist(command))
  end

  defp log(:info, title, message), do: log(:info, IO.ANSI.green(), title, message)
  defp log(:warn, title, message), do: log(:error, IO.ANSI.yellow(), title, message)
  defp log(:error, title, message), do: log(:error, IO.ANSI.red(), title, message)

  defp log(level, col, title, message) do
    log(level, "#{col} * #{title}#{IO.ANSI.reset()} #{message}")
  end

  defp log(:info, message), do: Mix.Shell.IO.info(message)
  defp log(:error, message), do: Mix.Shell.IO.error(message)
end
