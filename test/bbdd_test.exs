defmodule BbddTest do
  use ExUnit.Case
  doctest Bbdd

  test "basic operation" do
    uuid1 = UUID.uuid4()
    uuid2 = UUID.uuid4()

    assert {:ok, false} = Bbdd.marked?(uuid1)
    assert {:ok, false} = Bbdd.marked?(uuid2)
    assert {:ok, true} = Bbdd.clear?(uuid1)
    assert {:ok, true} = Bbdd.clear?(uuid2)

    assert :ok = Bbdd.mark(uuid1)

    assert {:ok, true} = Bbdd.marked?(uuid1)
    assert {:ok, false} = Bbdd.marked?(uuid2)
    assert {:ok, false} = Bbdd.clear?(uuid1)
    assert {:ok, true} = Bbdd.clear?(uuid2)

    assert :ok = Bbdd.clear(uuid1)
    assert :ok = Bbdd.mark(uuid2)

    assert {:ok, false} = Bbdd.marked?(uuid1)
    assert {:ok, true} = Bbdd.marked?(uuid2)
    assert {:ok, true} = Bbdd.clear?(uuid1)
    assert {:ok, false} = Bbdd.clear?(uuid2)
  end

  test "cache hijinx" do
    uuid1 = UUID.uuid4()
    uuid2 = UUID.uuid4()

    assert {:ok, false} = Bbdd.marked?(uuid1, cache: :none)
    assert {:ok, false} = Bbdd.marked?(uuid2)
    assert {:ok, true} = Bbdd.clear?(uuid1)
    assert {:ok, true} = Bbdd.clear?(uuid2)

    assert :ok = Bbdd.mark(uuid1, cache: :none)

    assert {:ok, true} = Bbdd.marked?(uuid1)
    assert {:ok, false} = Bbdd.marked?(uuid2)
    assert {:ok, false} = Bbdd.clear?(uuid1)
    assert {:ok, true} = Bbdd.clear?(uuid2)

    assert :ok = Bbdd.clear(uuid1)
    assert :ok = Bbdd.mark(uuid2, cache: :none)

    assert {:ok, false} = Bbdd.marked?(uuid1)
    assert {:ok, true} = Bbdd.marked?(uuid2)
    assert {:ok, true} = Bbdd.clear?(uuid1)
    assert {:ok, false} = Bbdd.clear?(uuid2)

    ## And this is why you don't mix cache: :none with a real cache
    assert :ok = Bbdd.clear(uuid2, cache: :none)
    assert {:ok, true} = Bbdd.marked?(uuid2)
  end
end
