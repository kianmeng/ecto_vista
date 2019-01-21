defmodule EctoVistaTest do
  use ExUnit.Case, async: true
  doctest EctoVista

  alias Ecto.Integration.TestRepo

  defmodule Category do
    use Ecto.Schema
    import Ecto.Changeset

    schema "categories" do
      field(:name, :string)
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:name])
    end
  end

  defmodule Product do
    use Ecto.Schema
    import Ecto.Changeset

    schema "products" do
      field(:name, :string)
      belongs_to(:category, Category)
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:name, :category_id])
    end
  end

  defmodule Catalog do
    use Ecto.Schema
    use EctoVista, repo: TestRepo

    schema "catalog" do
      field(:name, :string)
      field(:product_count, :integer)
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)

    {:ok, category} =
      %Category{}
      |> Category.changeset(%{name: "test"})
      |> TestRepo.insert()

    {:ok, product} =
      %Product{}
      |> Product.changeset(%{name: "test_product", category_id: category.id})
      |> TestRepo.insert()

    {:ok, category: category, product: product}
  end

  test "it returns view source" do
    assert Catalog.source() == "catalog"
  end

  test "it refreshes materialized view", %{category: category} do
    refute TestRepo.one(Catalog)
    assert {:ok, :success} = Catalog.refresh()

    assert %Catalog{id: category_id, name: category_name, product_count: 1} =
             TestRepo.one(Catalog)

    assert category_id == category.id
    assert category_name == category_name
  end
end
