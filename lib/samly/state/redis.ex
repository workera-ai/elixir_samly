defmodule Samly.State.Redis do
  @moduledoc """
  Stores SAML assertion in Redis.

  This provider uses Redis to keep the authenticated SAML assertions from IdP.
  It uses Redix for Redis communication.

  ## Options

  +   `:redis_name` - Redix connection name (optional)
                      Value must be an atom
                      Defaults to `:redix`
  +   `:key_prefix` - Prefix for Redis keys (optional)
                      Value must be a string
                      Defaults to `"samly:assertion:"`
  +   `:ttl` - Time to live in seconds for assertions (optional)
               Value must be a positive integer
               Defaults to `3600`

  ## Configuration Example

      config :samly, Samly.State,
        opts: [
          redis_name: :my_redix,
          key_prefix: "samly:assertion:",
          ttl: 60
        ]

  This assumes you have a Redix connection configured and running with the given name.
  """

  alias Samly.Assertion

  @behaviour Samly.State.Store

  @default_redis_name :redix
  @default_key_prefix "samly:assertion:"
  @default_ttl 3600

  @impl Samly.State.Store
  def init(opts) do
    redis_name = Keyword.get(opts, :redis_name, @default_redis_name)
    key_prefix = Keyword.get(opts, :key_prefix, @default_key_prefix)
    ttl = Keyword.get(opts, :ttl, @default_ttl)

    if is_atom(redis_name) == false do
      raise "Samly.State.Redis redis_name must be an atom: #{inspect(redis_name)}"
    end

    if is_binary(key_prefix) == false do
      raise "Samly.State.Redis key_prefix must be a string: #{inspect(key_prefix)}"
    end

    if ttl != nil and (not is_integer(ttl) or ttl <= 0) do
      raise "Samly.State.Redis ttl must be a positive integer or nil: #{inspect(ttl)}"
    end

    [redis_name: redis_name, key_prefix: key_prefix, ttl: ttl]
  end

  @impl Samly.State.Store
  def get_assertion(_conn, assertion_key, opts) do
    redis_name = Keyword.fetch!(opts, :redis_name)
    key_prefix = Keyword.fetch!(opts, :key_prefix)
    redis_key = build_redis_key(key_prefix, assertion_key)

    case Redix.command(redis_name, ["GET", redis_key]) do
      {:ok, nil} ->
        nil

      {:ok, binary} when is_binary(binary) ->
        binary
        |> Base.decode64!()
        |> :erlang.binary_to_term()

      {:error, reason} ->
        raise "Failed to get assertion from Redis: #{inspect(reason)}"
    end
  end

  @impl Samly.State.Store
  def put_assertion(conn, assertion_key, %Assertion{} = assertion, opts) do
    redis_name = Keyword.fetch!(opts, :redis_name)
    key_prefix = Keyword.fetch!(opts, :key_prefix)
    ttl = Keyword.get(opts, :ttl)
    redis_key = build_redis_key(key_prefix, assertion_key)

    encoded_assertion =
      assertion
      |> :erlang.term_to_binary()
      |> Base.encode64()

    command =
      case ttl do
        nil -> ["SET", redis_key, encoded_assertion]
        ttl when is_integer(ttl) -> ["SETEX", redis_key, to_string(ttl), encoded_assertion]
      end

    case Redix.command(redis_name, command) do
      {:ok, "OK"} ->
        conn

      {:error, reason} ->
        raise "Failed to put assertion to Redis: #{inspect(reason)}"
    end
  end

  @impl Samly.State.Store
  def delete_assertion(conn, assertion_key, opts) do
    redis_name = Keyword.fetch!(opts, :redis_name)
    key_prefix = Keyword.fetch!(opts, :key_prefix)
    redis_key = build_redis_key(key_prefix, assertion_key)

    case Redix.command(redis_name, ["DEL", redis_key]) do
      {:ok, _} ->
        conn

      {:error, reason} ->
        raise "Failed to delete assertion from Redis: #{inspect(reason)}"
    end
  end

  defp build_redis_key(prefix, {idp_id, name_id}) do
    "#{prefix}#{idp_id}:#{name_id}"
  end
end
