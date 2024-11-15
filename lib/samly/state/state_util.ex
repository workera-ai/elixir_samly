defmodule Samly.State.StateUtil do
  @moduledoc false

  alias Samly.Assertion

  def validate_assertion_expiry(%Assertion{} = assertion, :login = _phase) do
    expiry_date = assertion.subject.notonorafter

    if has_date_passed?(expiry_date), do: nil, else: assertion
  end

  def validate_assertion_expiry(%Assertion{} = assertion, :logout = _phase) do
    expiry_date =
      Map.get(assertion.authn, "session_not_on_or_after", assertion.subject.notonorafter)

    if has_date_passed?(expiry_date), do: nil, else: assertion
  end

  defp has_date_passed?(expiry_date) do
    now = DateTime.utc_now()

    case DateTime.from_iso8601(expiry_date) do
      {:ok, expiry_date, _} ->
        if DateTime.compare(now, expiry_date) == :lt, do: false, else: true

      _ ->
        true
    end
  end
end
