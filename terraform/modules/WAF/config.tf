locals {
  custom_rules = [
    {
      name   = "AllowCallback"
      type   = "MatchRule"
      action = "Allow"
      conditions = [
        {
          variable = "RequestUri"
          operator = "BeginsWith"
          values = [
            "/callback"
          ]
          negative_condition = false
        }
      ]
    },
    {
      name   = "AllowEventhub"
      type   = "MatchRule"
      action = "Allow"
      conditions = [
        {
          variable = "RequestUri"
          operator = "BeginsWith"
          values = [
            "/eventhub"
          ]
          negative_condition = false
        }
      ]
    }
  ]
}
