variable "apps" {
  type = map(object({name=string, url=string, audience=string}))
}
