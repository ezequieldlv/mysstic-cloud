output "database_endpoint" {
  value       = module.database.database_endpoint
  description = "Endpoint de conexión para la base de datos RDS PostgreSQL"
}
