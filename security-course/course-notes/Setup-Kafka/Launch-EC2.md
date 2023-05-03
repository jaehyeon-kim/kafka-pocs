## AWS infrastructure setup
### AWS account
https://aws.amazon.com  
click "Sign in to the Console"
either login to your account, or signup if you don't have an account yet

### EC2 instance
choose your region (on the top right)  
go to service "EC2" and click "launch instance"  
go to "AWS marketplace" and search for "ubuntu"  
choose Ubuntu 16.04  

_verify if you are fine with the pricing for a *T2 Large* instance_
* select t2.large  

click "Next: Configure Instance Details"
=> keep defaults
click "Add Storage"
=> keep defaults
click "Add Tags"
add Tag => key = "Name" , value = "kafka-security-vm"
=> this tag simplifies the identification of the instance later on

click "Configure security Group"  
create new one, "kafka-security" (name+description)  
* for existing rule on port 22 select "MyIP"  to only allow ssh from your local workstation

click "Review and Launch"
click "Launch"  

!! key pair !!  
select "Create a new key pair"  
* Key pair name: "kafka-security"  

click "Download Key Pair" and save it locally  
click "Launch instances"  
click "View Instances" (=> EC2 Dashboard)

### assign an elastic IP address
in EC2 Dashboard click on "Elastic IPs" in chapter "Network&Security"  
click "Allocate new address"
click "Allocate" + "Close"
Elastic IPs overview now shows the gathered IP
select your Elastic IP and click "Actions" => "Associate address"
fill in the dialog:
"Resource Type" => "Instance"
"Instance" => choose your recently launched instance from drop-down box
"Private IP" => select the private IP of your instance, where the Elastic IP will be associated to
click "Associate"

click on "Instances" in left main navigation bar to get back to the overview of EC2 Instances

check that the "IPv4 Public IP" has changed (to the same as shown under "Elastic IP"), as well as "Public DNS"


### connect to your instance
```
export PEMFILE=~/Downloads/kafka-security.pem
chmod 600 $PEMFILE
ssh -i $PEMFILE ubuntu@Elastic-IP-of-your-instance

```
