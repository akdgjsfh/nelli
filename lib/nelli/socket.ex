defmodule Nelli.Socket do
  @moduledoc """
  Wrapper for plain and (maybe) tls sockets.

  Based on [elli_tcp.erl](https://github.com/knutin/elli/blob/master/src/elli_tcp.erl)
  which itself is based on [mochiweb_socket.erl](https://github.com/mochi/mochiweb/blob/master/src/mochiweb_socket.erl).
  """

  @type t :: {:plain, :inet.socket} # | {:tls, :ssl.sslsocket}

  @type packet :: charlist | binary | http_packet
  # See the description of HttpPacket in erlang:decode_packet/3 in ERTS.
  @type http_packet :: term
  @type reason :: :closed | :inet.posix
  @type peername :: {:inet.ip_address, :inet.port_number} | :inet.returned_non_ip_address

  @doc """
  Sets up a socket to listen on port on the local host.

  See [`:gen_tcp.listen/2`](http://erlang.org/doc/man/gen_tcp.html#listen-2) for more.
  """
  @spec listen(:plain, :inet.port, [:gen_tcp.option]) :: {:ok, t} | {:error, reason}
  def listen(:plain, port, opts) do
    case :gen_tcp.listen(port, opts) do
      {:ok, listen_socket} -> {:ok, {:plain, listen_socket}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Accepts an incoming connection request on a listening socket.

  See [`:gen_tcp.accept/2`](http://erlang.org/doc/man/gen_tcp.html#accept-2) for more.
  """
  @spec accept(t, Nelli.server, non_neg_integer) :: {:ok, t} | {:error, reason}
  def accept({:plain, listen_socket}, server, timeout) do
    case :gen_tcp.accept(listen_socket, timeout) do
      {:ok, accept_socket} ->
        GenServer.cast(server, :accepted)
        {:ok, {:plain, accept_socket}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Receives a packet from a socket.

  See [`:gen_tcp.recv/3`](http://erlang.org/doc/man/gen_tcp.html#recv-3) for more.
  """
  @spec recv(t, non_neg_integer, non_neg_integer) :: {:ok, packet} | {:error, reason}
  def recv({:plain, socket}, size, timeout) do
    :gen_tcp.recv(socket, size, timeout)
  end

  @doc """
  Sends a packet on a socket.

  See [`:gen_tcp.send/2`](http://erlang.org/doc/man/gen_tcp.html#send-2) for more.
  """
  @spec send(t, iodata) :: :ok | {:error, reason}
  def send({:plain, socket}, data) do
    :gen_tcp.send(socket, data)
  end

  @doc """
  Closes a TCP socket.

  See [`:gen_tcp.close/1`](http://erlang.org/doc/man/gen_tcp.html#close-1) for more.
  """
  @spec close(t) :: :ok
  def close({:plain, socket}) do
    :gen_tcp.close(socket)
  end

  @doc """
  Sets one or more options for a socket.

  See [`:inet.setopts/2`](http://erlang.org/doc/man/inet.html#setopts-2) for more.
  """
  @spec setopts(t, [:gen_tcp.option]) :: :ok | {:error, :inet.posix}
  def setopts({:plain, socket}, opts) do
    :inet.setopts(socket, opts)
  end

  @doc """
  Returns the address and port for the other end of a connection.

      iex> Nelli.Socket.peername(socket)
      {:ok, {{127, 0, 0, 1}, 38475}}

  See [`:inet.peername/1`](http://erlang.org/doc/man/inet.html#peername-1) for more.
  """
  @spec peername(t) :: {:ok, peername} | {:error, :inet.posix}
  def peername({:plain, socket}) do
    :inet.peername(socket)
  end
end
