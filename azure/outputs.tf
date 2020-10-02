output "ip" {
  value = data.azurerm_public_ip.benchmark_public_ip.ip_address
}
