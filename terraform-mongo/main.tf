data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user-data.sh")}"

  vars {
    mongodb_version          = "${var.mongodb_version}"
    mongodb_basedir          = "${var.mongodb_basedir}"
    mongodb_conf_logpath     = "${var.mongodb_conf_logpath}"
    mongodb_conf_engine      = "${var.mongodb_conf_engine}"
    mongodb_conf_replsetname = "${var.mongodb_conf_replsetname}"
    mongodb_conf_oplogsizemb = "${var.mongodb_conf_oplogsizemb}"
    mongodb_key_s3_object    = "${var.mongodb_key_s3_object}"
    ssl_ca_key_s3_object     = "${var.ssl_ca_key_s3_object}"
    ssl_mongod_key_s3_object = "${var.ssl_mongod_key_s3_object}"
    ssl_agent_key_s3_object  = "${var.ssl_agent_key_s3_object}"
    opsmanager_key_s3_object = "${var.opsmanager_key_s3_object}"
    opsmanager_subdomain     = "${var.opsmanager_subdomain}"
    hostname                 = "${var.route53_hostname}"
    aws_region               = "${var.aws_region}"
    config_ephemeral         = "${var.config_ephemeral}"
    config_ebs               = "${var.config_ebs}"
    role_node                = "${var.role_node}"
    role_opsmanager          = "${var.role_opsmanager}"
    role_backup              = "${var.role_backup}"
    mms_group_id             = "${var.mms_group_id}"
    mms_api_key              = "${var.mms_api_key}"
    mms_password             = "${var.mms_password}"
  }
}

resource "aws_instance" "mongodb" {
  ami                         = "${var.ec2_ami_id}"
  instance_type               = "${var.ec2_instance_type}"
  key_name                    = "mongodb"
  user_data                   = "${data.template_file.user_data.rendered}"
  iam_instance_profile        = "${var.mongodb_iam_name}"
  vpc_security_group_ids      = ["${var.mongodb_sg_id}"]
  subnet_id                   = "${var.subnet_id}"
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 64
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags {
    Name = "${var.name}"
  }

  connection {
    user     = "ubuntu"
    key_file = "{TF_VAR_key_file}"
  }
}

resource "aws_route53_record" "mongodb" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.route53_hostname}"
  type    = "CNAME"
  ttl     = 60
  records = ["${aws_instance.mongodb.public_dns}"]
}

resource "aws_route53_record" "mongodb-internal" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.route53_hostname_internal}"
  type    = "A"
  ttl     = 60
  records = ["${aws_instance.mongodb.private_ip}"]
}

output "instance_id" {
  value = "${aws_instance.mongodb.id}"
}

output "private_ip" {
  value = "${aws_instance.mongodb.private_ip}"
}

output "public_dns" {
  value = "${aws_instance.mongodb.public_dns}"
}
