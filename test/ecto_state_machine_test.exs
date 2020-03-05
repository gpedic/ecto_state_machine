defmodule EctoStateMachineTest do
  use ExUnit.Case, async: true

  alias Dummy.User

  import Dummy.Factories

  setup_all do
    {
      :ok,
      unconfirmed_user: insert(:user, %{ rules: "unconfirmed" }),
      confirmed_user:   insert(:user, %{ rules: "confirmed" }),
      blocked_user:     insert(:user, %{ rules: "blocked" }),
      admin:            insert(:user, %{ rules: "admin" })
    }
  end

  describe "events" do
    test "#confirm", context do
      changeset = User.confirm(context[:unconfirmed_user])
      assert changeset.valid?            == true
      assert changeset.changes.rules     == "confirmed"
      assert Map.keys(changeset.changes) == ~w(confirmed_at rules)a

      changeset = User.confirm(context[:confirmed_user])
      assert changeset.valid? == false
      assert changeset.errors == [rules: {"Invalid state transition :confirmed to :confirmed", []}]

      changeset = User.confirm(context[:blocked_user])
      assert changeset.valid? == false
      assert changeset.errors == [rules: {"Invalid state transition :blocked to :confirmed", []}]

      changeset = User.confirm(context[:admin])
      assert changeset.valid? == false
      assert changeset.errors == [rules: {"Invalid state transition :admin to :confirmed", []}]
    end

    test "#block", context do
      changeset = User.block(context[:unconfirmed_user])
      assert changeset.valid? == false
      assert changeset.errors == [rules: {"Invalid state transition :unconfirmed to :blocked", []}]

      changeset = User.block(context[:confirmed_user])
      assert changeset.valid?            == true
      assert changeset.changes.rules     == "blocked"

      changeset = User.block(context[:blocked_user])
      assert changeset.valid? == false
      assert changeset.errors == [rules: {"Invalid state transition :blocked to :blocked", []}]

      changeset = User.block(context[:admin])
      assert changeset.valid?            == true
      assert changeset.changes.rules     == "blocked"
    end

    test "#make_admin", context do
      changeset = User.make_admin(context[:unconfirmed_user])
      assert changeset.valid? == false
      assert changeset.errors == [rules: {"Invalid state transition :unconfirmed to :admin", []}]

      changeset = User.make_admin(context[:confirmed_user])
      assert changeset.valid?            == true
      assert changeset.changes.rules     == "admin"

      changeset = User.make_admin(context[:blocked_user])
      assert changeset.valid? == false
      assert changeset.errors == [rules: {"Invalid state transition :blocked to :admin", []}]

      changeset = User.make_admin(context[:admin])
      assert changeset.valid? == false
      assert changeset.errors == [rules: {"Invalid state transition :admin to :admin", []}]
    end
  end

  describe "can_?" do
    test "#can_confirm?", context do
      assert User.can_confirm?(context[:unconfirmed_user])    == true
      assert User.can_confirm?(context[:confirmed_user])      == false
      assert User.can_confirm?(context[:blocked_user])        == false
      assert User.can_confirm?(context[:admin])               == false
    end

    test "#can_block?", context do
      assert User.can_block?(context[:unconfirmed_user])      == false
      assert User.can_block?(context[:confirmed_user])        == true
      assert User.can_block?(context[:blocked_user])          == false
      assert User.can_block?(context[:admin])                 == true
    end

    test "#can_make_admin?", context do
      assert User.can_make_admin?(context[:unconfirmed_user]) == false
      assert User.can_make_admin?(context[:confirmed_user])   == true
      assert User.can_make_admin?(context[:blocked_user])     == false
      assert User.can_make_admin?(context[:admin])            == false
    end
  end

  describe "valid_?" do
    test "#valid_transition?", context do
      refute User.valid_transition?(context[:blocked_user], :admin)
      refute User.valid_transition?(context[:blocked_user], :blocked)
      refute User.valid_transition?(context[:blocked_user], :confirmed)
      refute User.valid_transition?(context[:blocked_user], :does_not_exist)

      assert User.valid_transition?(context[:unconfirmed_user], :confirmed)
      assert User.valid_transition?(context[:confirmed_user], :admin)
      assert User.valid_transition?(context[:confirmed_user], :blocked)
    end
  end

  test "#resolve_transition", context do
    assert {:ok, %{name: :confirm}} = User.resolve_transition(context[:unconfirmed_user], :confirmed)
  end

  test "#apply_transition", context do
    assert %{valid?: true} = User.apply_transition(context[:unconfirmed_user], :confirm)
    assert %{valid?: false} = User.apply_transition(context[:unconfirmed_user], :make_admin)
  end

  test "#states" do
    assert User.rules_states == [:unconfirmed, :confirmed, :blocked, :admin]
  end

  test "#events" do
    assert User.rules_events == [:confirm, :block, :make_admin]
  end
end
