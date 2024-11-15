defmodule Samly.StateUtilTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Plug.Test

  alias Samly.Assertion
  alias Samly.State.StateUtil

  describe "validate_assertion_expiry/2" do
    test "returns nil when assertion is expired for login request" do
      # Arrange
      not_on_or_after = DateTime.utc_now() |> DateTime.add(-8, :hour) |> DateTime.to_iso8601()

      session_not_on_or_after =
        DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()

      assertion = %Samly.Assertion{
        subject: %{notonorafter: not_on_or_after},
        authn: %{"session_not_on_or_after" => session_not_on_or_after}
      }

      # Act
      result = StateUtil.validate_assertion_expiry(assertion, :login)

      # Assert
      assert result == nil
    end

    test "returns assertion when assertion has not expired for login request" do
      # Arrange
      not_on_or_after = DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()

      session_not_on_or_after =
        DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()

      assertion = %Samly.Assertion{
        subject: %{notonorafter: not_on_or_after},
        authn: %{"session_not_on_or_after" => session_not_on_or_after}
      }

      # Act
      result = StateUtil.validate_assertion_expiry(assertion, :login)

      # Assert
      assert result == assertion
    end

    test "returns nil when assertion is expired for logout request" do
      # Arrange
      not_on_or_after = DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()

      session_not_on_or_after =
        DateTime.utc_now() |> DateTime.add(-8, :hour) |> DateTime.to_iso8601()

      assertion = %Samly.Assertion{
        subject: %{notonorafter: not_on_or_after},
        authn: %{"session_not_on_or_after" => session_not_on_or_after}
      }

      # Act
      result = StateUtil.validate_assertion_expiry(assertion, :logout)

      # Assert
      assert result == nil
    end

    test "returns assertion when assertion has not expired for logout request" do
      # Arrange
      not_on_or_after = DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()

      session_not_on_or_after =
        DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()

      assertion = %Samly.Assertion{
        subject: %{notonorafter: not_on_or_after},
        authn: %{"session_not_on_or_after" => session_not_on_or_after}
      }

      # Act
      result = StateUtil.validate_assertion_expiry(assertion, :logout)

      # Assert
      assert result == assertion
    end

    test "returns nil when session_not_on_or_after is not available but assertion subject has also expired for logout request" do
      # Arrange
      not_on_or_after = DateTime.utc_now() |> DateTime.add(-8, :hour) |> DateTime.to_iso8601()

      assertion = %Samly.Assertion{
        subject: %{notonorafter: not_on_or_after},
        authn: %{}
      }

      # Act
      result = StateUtil.validate_assertion_expiry(assertion, :logout)

      # Assert
      assert result == nil
    end

    test "returns assertion when session_not_on_or_after is not available but assertion subject has not expired for logout request" do
      # Arrange
      not_on_or_after = DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()

      assertion = %Samly.Assertion{
        subject: %{notonorafter: not_on_or_after},
        authn: %{}
      }

      # Act
      result = StateUtil.validate_assertion_expiry(assertion, :logout)

      # Assert
      assert result == assertion
    end
  end
end
