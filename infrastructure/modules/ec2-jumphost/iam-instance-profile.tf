resource "aws_iam_instance_profile" "instance-profile" {
  name = "Swiggy_Clone_Jumphost_Instance_Profile"
  role = aws_iam_role.iam-role.name
}
