defmodule PrintClient.Label.Encoder.TSPL do
  @behaviour PrintClient.Label.Encoder
  alias PrintClient.Label.Template

  @impl true
  def encode(image, opts) do
    file = random_str()
    copies = Keyword.get(opts, :copies, 1)
    dpi = Keyword.get(opts, :dpi, 300)

    with :ok <- File.write("/tmp/#{file}.svg", image) do
      %Mogrify.Image{} =
        img =
        "/tmp/#{file}.svg"
        |> Mogrify.open()
        |> Mogrify.custom("alpha", "off")
        |> Mogrify.custom("depth", "1")
        |> Mogrify.custom("type", "bilevel")
        |> Mogrify.custom("density", "200")
        |> Mogrify.custom("units", "pixelsperinch")
        |> Mogrify.custom("negate")
        |> Mogrify.format("PCX")

      Mogrify.save(img, path: "/tmp/#{file}.pcx")

      %{width: width, height: height} = Mogrify.identify("/tmp/#{file}.pcx")

      {:ok, img} = File.read("/tmp/#{file}.pcx")
      File.rm("/tmp/#{file}.svg")
      File.rm("/tmp/#{file}.pcx")

      {:ok,
       [
         <<"SIZE #{width / dpi},#{height / dpi}\r\n">>,
         <<"CLS\r\n">>,
         <<"DIRECTION 1,0\r\n">>,
         <<"DOWNLOAD \"#{file}\",#{byte_size(img)},", img::binary, "\r\n">>,
         <<"PUTPCX 0,0, \"#{file}\"\r\n">>,
         <<"PRINT #{copies}\r\n">>,
         <<"KILL \"#{file}\"\r\n">>
       ]
       |> :binary.list_to_bin()}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  # @random_chars "0123456789ABCDEFGHIMNOPQRSTUVWXYZ"
  @random_chars "ABCDEFGHIMNOPQRSTUVWXYZ" |> String.downcase()
  defp random_str(len \\ 4) when len > 0,
    do:
      for(
        _ <- 1..len,
        into: "",
        do: <<@random_chars |> String.to_charlist() |> Enum.random()>>
      )
end
