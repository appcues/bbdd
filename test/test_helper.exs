ExUnit.start()

ExAws.Dynamo.delete_table("bbdd_test") |> ExAws.request()

ExAws.Dynamo.create_table(
  "bbdd_test",
  [prefix: :hash],
  [prefix: :string],
  1,
  1
)
|> ExAws.request!()
