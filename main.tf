
# Create a Custom VPC

resource "aws_vpc" "mainVPC" {
  cidr_block = var.cidr
}

resource "aws_subnet" "sub1" {
  vpc_id = aws_vpc.mainVPC.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-southeast-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id = aws_vpc.mainVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-2b"
  map_public_ip_on_launch = true
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.mainVPC.id

  tags = {
    Name = "main"
  }
}

# Attaching Internet Gateway 
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.mainVPC.id
  route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}

#Creating Security group

resource "aws_security_group" "web-sg" {
  name = "web"
  vpc_id = aws_vpc.mainVPC.id 

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Open To Outside World"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#Launching Instances

resource "aws_instance" "webserver1" {
  ami                    = "ami-093dc6859d9315726"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  subnet_id              = aws_subnet.sub1.id
  user_data              = base64encode(file("update.sh"))
}

resource "aws_instance" "webserver2" {
  ami                    = "ami-093dc6859d9315726"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  subnet_id              = aws_subnet.sub2.id
  user_data              = base64encode(file("update.sh"))
}

#Creating EBS Volume
resource "aws_ebs_volume" "my-ebs" {
  availability_zone = "ap-southeast-2a"
  size              = 40
}

#Attaching EBS Volume
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.my-ebs.id
  instance_id = aws_instance.webserver1.id
}
/*
#Creating Custom SQL Database

data "aws_rds_orderable_db_instance" "custom-sqlserver" {
  engine                     = "custom-sqlserver-se" # CEV engine to be used
  engine_version             = "15.00.4249.2.v1"     # CEV engine version to be used
  storage_type               = "gp3"
  preferred_instance_classes = ["db.r5.xlarge", "db.r5.2xlarge", "db.r5.4xlarge"]
}


data "aws_kms_key" "by_id" {
  key_id = kms-key.id 
}

resource "aws_db_instance" "example" {
  allocated_storage           = 500
  auto_minor_version_upgrade  = false                                  
  custom_iam_instance_profile = "AWSRDSCustomSQLServerInstanceProfile"
  backup_retention_period     = 7
  db_subnet_group_name        = local.sub1.id 
  engine                      = data.aws_rds_orderable_db_instance.custom-sqlserver.engine
  engine_version              = data.aws_rds_orderable_db_instance.custom-sqlserver.engine_version
  identifier                  = "sql-instance-demo"
  instance_class              = data.aws_rds_orderable_db_instance.custom-sqlserver.instance_class
  kms_key_id                  = data.aws_kms_key.by_id.arn
  multi_az                    = false 
  password                    = "PASS123"
  storage_encrypted           = true
  username                    = "test"

  timeouts {
    create = "3h"
    delete = "3h"
    update = "3h"
  }
}

*/
