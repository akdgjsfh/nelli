defmodule Nelli.Request do
  defstruct [
    :method, :path, :version, :pid, :socket, :handler, :buffer, :headers
  ]
end
