provider "aws" {
  region = "eu-west-1"  # Ireland region
}

resource "aws_vpc" "nadav_main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "nadav_vpc"
  }
}

resource "aws_subnet" "nadav_public_subnet_1" {
  vpc_id            = aws_vpc.nadav_main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "nadav_public_subnet_1"
  }
}

resource "aws_subnet" "nadav_public_subnet_2" {
  vpc_id            = aws_vpc.nadav_main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "nadav_public_subnet_2"
  }
}

resource "aws_subnet" "nadav_private_subnet_1" {
  vpc_id            = aws_vpc.nadav_main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "nadav_private_subnet_1"
  }
}

resource "aws_subnet" "nadav_private_subnet_2" {
  vpc_id            = aws_vpc.nadav_main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "nadav_private_subnet_2"
  }
}

resource "aws_internet_gateway" "nadav_gw" {
  vpc_id = aws_vpc.nadav_main.id

  tags = {
    Name = "nadav_internet_gateway"
  }
}

resource "aws_route_table" "nadav_public_rt" {
  vpc_id = aws_vpc.nadav_main.id

  tags = {
    Name = "nadav_public_rt"
  }
}

resource "aws_route" "nadav_public_route" {
  route_table_id         = aws_route_table.nadav_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nadav_gw.id
}

resource "aws_route_table_association" "nadav_public_subnet_1_association" {
  subnet_id      = aws_subnet.nadav_public_subnet_1.id
  route_table_id = aws_route_table.nadav_public_rt.id
}

resource "aws_route_table_association" "nadav_public_subnet_2_association" {
  subnet_id      = aws_subnet.nadav_public_subnet_2.id
  route_table_id = aws_route_table.nadav_public_rt.id
}

resource "aws_eip" "nadav_nat" {
  domain = "vpc"

  tags = {
    Name = "nadav_nat_eip"
  }
}

resource "aws_nat_gateway" "nadav_nat_gw" {
  allocation_id = aws_eip.nadav_nat.id
  subnet_id     = aws_subnet.nadav_public_subnet_1.id

  tags = {
    Name = "nadav_nat_gateway"
  }
}

resource "aws_route_table" "nadav_private_rt" {
  vpc_id = aws_vpc.nadav_main.id

  tags = {
    Name = "nadav_private_rt"
  }
}

resource "aws_route" "nadav_private_route" {
  route_table_id         = aws_route_table.nadav_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nadav_nat_gw.id
}

resource "aws_route_table_association" "nadav_private_subnet_1_association" {
  subnet_id      = aws_subnet.nadav_private_subnet_1.id
  route_table_id = aws_route_table.nadav_private_rt.id
}

resource "aws_route_table_association" "nadav_private_subnet_2_association" {
  subnet_id      = aws_subnet.nadav_private_subnet_2.id
  route_table_id = aws_route_table.nadav_private_rt.id
}

# Security Group for EC2
resource "aws_security_group" "nadav_ec2_sg" {
  vpc_id = aws_vpc.nadav_main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.nadav_public_subnet_1.cidr_block, aws_subnet.nadav_public_subnet_2.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.nadav_main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nadav_ec2_sg"
  }
}

# Security Group for Load Balancer
resource "aws_security_group" "nadav_lb_sg" {
  vpc_id = aws_vpc.nadav_main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nadav_lb_sg"
  }
}

# Security Group for SSH Access
resource "aws_security_group" "nadav_ssh_sg" {
  vpc_id = aws_vpc.nadav_main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nadav_ssh_sg"
  }
}

resource "aws_network_interface" "nadav_ec2_interface" {
  subnet_id   = aws_subnet.nadav_private_subnet_1.id
  private_ips = ["10.0.3.10"]

  security_groups = [aws_security_group.nadav_ec2_sg.id]

  tags = {
    Name = "nadav_ec2_network_interface"
  }
}

resource "aws_eip" "nadav_ec2_eip" {
  vpc = true

  tags = {
    Name = "nadav_ec2_eip"
  }
}

resource "aws_eip_association" "nadav_ec2_eip_association" {
  network_interface_id = aws_network_interface.nadav_ec2_interface.id
  allocation_id        = aws_eip.nadav_ec2_eip.id
}

resource "aws_instance" "nadav_bastion" {
  ami           = "ami-0a2202cf4c36161a1"  # Amazon Linux AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.nadav_public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.nadav_ssh_sg.id]

  key_name = "nadav-ec2-key"

  tags = {
    Name = "nadav_bastion_host"
  }
}

resource "aws_instance" "nadav_ec2" {
  ami           = "ami-0a2202cf4c36161a1"  # Amazon Linux AMI
  instance_type = "t3.micro"
  network_interface {
    network_interface_id = aws_network_interface.nadav_ec2_interface.id
    device_index         = 0
  }

  key_name = "nadav-ec2-key"

  iam_instance_profile   = aws_iam_instance_profile.nadav_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -x

              # Format and mount the EBS volume
              sudo mkfs -t ext4 /dev/sdf
              sudo mkdir /mnt/data
              sudo mount /dev/sdf /mnt/data
              sudo chown -R ec2-user:ec2-user /mnt/data

              # Install Docker
              sudo dnf update -y
              sudo dnf install -y docker
              sudo systemctl start docker
              sudo systemctl enable docker
              EOF

  tags = {
    Name = "nadav_docker_ec2"
  }
}

# Create the Load Balancer
resource "aws_lb" "nadav_lb" {
  name               = "nadav-public-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nadav_lb_sg.id]
  subnets            = [aws_subnet.nadav_public_subnet_1.id, aws_subnet.nadav_public_subnet_2.id]

  tags = {
    Name = "nadav_lb"
  }
}

# Create the Target Group
resource "aws_lb_target_group" "nadav_tg" {
  name     = "nadav-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.nadav_main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    protocol            = "HTTP"
  }

  tags = {
    Name = "nadav_tg"
  }
}

# Register the instance to the Target Group
resource "aws_lb_target_group_attachment" "nadav_tg_attachment" {
  target_group_arn = aws_lb_target_group.nadav_tg.arn
  target_id        = aws_instance.nadav_ec2.id
  port             = 80
}

# Create the Listener
resource "aws_lb_listener" "nadav_lb_listener" {
  load_balancer_arn = aws_lb.nadav_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nadav_tg.arn
  }

  tags = {
    Name = "nadav_lb_listener"
  }
}

# S3 Bucket creation with read permissions for EC2 instance

resource "aws_s3_bucket" "nadav_bucket" {
  bucket = "nadav-ec2-bucket"

  tags = {
    Name = "nadav_bucket"
  }
}

resource "aws_iam_role" "nadav_s3_read_role" {
  name = "nadav_s3_read_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "nadav_s3_read_role"
  }
}

resource "aws_iam_role_policy" "nadav_s3_read_policy" {
  name   = "nadav_s3_read_policy"
  role   = aws_iam_role.nadav_s3_read_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.nadav_bucket.arn,
          "${aws_s3_bucket.nadav_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "nadav_instance_profile" {
  name = "nadav_instance_profile"
  role = aws_iam_role.nadav_s3_read_role.name

  tags = {
    Name = "nadav_instance_profile"
  }
}

# EBS Volume creation
resource "aws_ebs_volume" "nadav_volume" {
  availability_zone = aws_instance.nadav_ec2.availability_zone
  size              = 10  # גודל ה-Volume ב-GB
  tags = {
    Name = "nadav_volume"
  }
}

# Volume attachment to EC2 instance
resource "aws_volume_attachment" "nadav_volume_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.nadav_volume.id
  instance_id = aws_instance.nadav_ec2.id
}

output "nadav_lb_dns" {
  value = aws_lb.nadav_lb.dns_name
}

output "nadav_bucket_name" {
  value = aws_s3_bucket.nadav_bucket.bucket
}

output "nadav_iam_role" {
  value = aws_iam_role.nadav_s3_read_role.arn
}
