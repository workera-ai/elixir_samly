defmodule Samly.State.StateUtil do
  @moduledoc false

  alias Samly.Assertion

  def validate_login_assertion_expiry(%Assertion{subject: %{notonorafter: expiry_date}}) do
    if date_passed?(expiry_date), do: :expired, else: :valid
  end

  def validate_logout_assertion_expiry(%Assertion{authn: authn, subject: subject}) do
    expiry_date =
      Map.get(authn, "session_not_on_or_after", subject.notonorafter)

    if date_passed?(expiry_date), do: :expired, else: :valid
  end

  defp date_passed?(expiry_date) do
    now = DateTime.utc_now()

    case DateTime.from_iso8601(expiry_date) do
      {:ok, expiry_date, _} ->
        if DateTime.compare(now, expiry_date) == :lt, do: false, else: true

      _ ->
        true
    end
  end
end
