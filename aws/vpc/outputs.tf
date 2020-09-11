output "bastion_id" {
  value = aws_instance.benchmark_bastion.id
}

output "instance_ids" {
  value = [aws_instance.benchmark_instance.*.id]
}
