use Mix.Config

config :bbdd, table: "bbdd_test"

config :ex_aws, :dynamodb,
  access_key_id: "who",
  secret_access_key: "cares",
  host: "localhost",
  scheme: "http://",
  port: 32123,
  region: "us-west-2"
