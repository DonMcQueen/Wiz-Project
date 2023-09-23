# Wiz-Project Read Me

Thanks for stopping by! This is a walkthrough of the technical project assigned by the Wiz team for the CSA role. In this Read Me, you will find:  
- What we are building. Think of the tools, services, software, etc. required to complete the assessment  
- Notes. Which parts were difficult to build, which parts were more straightforward, which parts were ambiguous, etc.  
- References to other files used in the project. These could be IAM role json, terraform files, secrets files, Cloud Provider files, etc.  
- Final Thoughts.  

## Technologies that are being used

1. MongoDB: NoSQL Database to be used alongside Django application.  
2. Kubernetes: Cloud Native application orchestrator used to managed containerized applications at scale.  
3. AWS: S3 is being used to store database backups. Permissions must allow public read so that anyone can read from the bucket. EKS is the AWS service being used to manage the control plane nodes responsible for scheduling containers, managing application availability, and will ultimately be running our Django application. VPC is the AWS service that will allow for logically isolating our cloud resources and will the ground work for our environment's underlying network capabilities.  
4. Linux: Operating System that the containers are running on, bash script within the bastion host and MongoDB VM.  
5. Terraform: Using Terraform as the Infrastructure as Code delivery.  

Check out my Trello board which covered a majority of the steps that were completed to build out the requirements of the Technical Assessment: https://trello.com/b/laXu4oST/wiz-assessment  

### Phase 1 Basic Setup - Step 1

1. Find Linux image that is over one year old.  

I was able to find an Ubuntu 16.04 image (Xenial) that was last updated on April 5th, 2021. This can be found in the AWS Marketplace by the author 'Supported Images'.  

2. Find a MongoDB package that is older than 6 months old.  

I was able to find a MongoDB package that was older than 6 months. This was a bit more challenging. I was able to find plenty of MongoDB versions that met this criteria, however it would also need to support an equivalent Operating System that was supported for the MongoDB version. I ended up choosing MongoDB version 4.4.16, and when deploying the ami on any new Virtual Machine, it will automatically pull down the latest version, so we can essentially bootstrap the following downgrade command for any new Virtual Machines that deploy the ami. Example shown below:  

    sudo apt-get install -y mongodb-org=4.4.16 mongodb-org-server=4.4.16 mongodb-org-shell=4.4.16 mongodb-org-mongos=4.4.16 mongodb-org-tools=4.4.16 --allow-downgrades  

3. Install MongoDB package onto Linux Operating System.  

This was a straightforward process once the MongoDB version and Operating System aligned. I was able to follow the steps outlined in this documentation with little trouble. https://www.mongodb.com/docs/v4.4/tutorial/install-mongodb-on-ubuntu/   

4. Create AMI of 6+ month old MongoDB version onto 1+ year old Linux version.  

This was a straightforward step as well. Once all installation configurations have been met, we can essentially use this Amazon Machine Image to remake the server that we just created. This helps cut down on time and allows our process to be more scalable should more requirements change in the near future.  

Security Concerns  

A. Security Vulnerabilities: using an outdated Linux distribution you expose your systemt to potential exploits and compromise security of your environment.  
B. Lack of Support: If you encounter issues or require assistance, the likelihood of getting the help you require is more challenging as there are better, more stable versions that one can leverage.  
C. Limited Hardware Compatibility: Older Linux distributions may not support newer hardware components or peripherals. Before your company can take advantage of the latest and greatest in hardware, the scalability of your tech stack will be stunted.  
D. Outdated Software: Similarly to 'Limited Hardware Compatibility' you also won't have access to the latest software versions that might be more performant or secure in an enterprise environment.  
E. Lack of Performance Improvements: Newer Linux distributions have performance enhancements, optimization, etc. Without upgrading, a company might be creating their own virtual bottleneck for internal and customer facing solutions.  
F. Compliance and Regulatory: Industries have compliance and regulatory requirements that require using the latest/safest tools and services. Violating these rules put both the enterprise, their clients, and their future business opportunities to both cyber and legal risk.  

### Phase 1 Basic Setup - Step 2

1. Create a bucket that will hold the MongoDB backups which you will need to automate. Change permissions on the bucket to allow for PUBLIC READ (anyone can read from the bucket).  

Use the following AWS policy to allow anyone to access the bucket and it's objects.

    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "PublicReadGetObject",
                "Effect": "Allow",
                "Principal": "*",
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::wizdemobucketpublic/*"
            },
            {
                "Sid": "AllowPublicRead",
                "Effect": "Allow",
                "Principal": "*",
                "Action": [
                    "s3:PutBucketAcl",
                    "s3:PutBucketPolicy"
                ],
                "Resource": "arn:aws:s3:::wizdemobucketpublic"
            },
            {
                "Sid": "allow-inspector",
                "Effect": "Allow",
                "Principal": {
                    "Service": "inspector2.amazonaws.com"
                },
                "Action": [
                    "s3:PutObject",
                    "s3:PutObjectAcl",
                    "s3:AbortMultipartUpload"
                ],
                "Resource": "arn:aws:s3:::wizdemobucketpublic/*",
                "Condition": {
                    "StringEquals": {
                        "aws:SourceAccount": "481234287216"
                    },
                    "ArnLike": {
                        "aws:SourceArn": "arn:aws:inspector2:us-east-1:481234287216:report/*"
                    }
                }
            }
        ]
    }

This policy grants read access to anyone for objects within the defined bucket. This policy will make all objects in the bucket publicly accessible, which means anyone that has the object's URL can read it's contents. Additionally, there are permissions set to allow AWS Inspector Vulnerability Scans to be exported within the 'securityfindings/' folder path. I would love to compare what AWS finds as vulnerabilities within the HELLO ALHAJI!

Security Concerns  

Depending on what information or data you have stored in S3 will depend on the type of security you want. Below are 2 examples of when you would want to use a public S3 bucket, and when you would not want to use a public S3 bucket.

Public Bucket examples:  
1. You generate public facing marketing content and pull from images, files and documents from this bucket. If someone were to have the URL, no private information would be compromised and everyone that wants to access it, can access it. You'll find this common with digital menu's at restaurants. Customers scan a QR code with their phone, at or outside of the restaurant and it directs them to the S3 object URL for the menu.
2. You generate public facing web content that you want users to be able to access. Having this bucket as public will allow everyone to access all required files for a good web page browsing experience. You'll find this common with static web sites that people host such as their own resumes, public blogs, or landing pages.  

Private Bucket examples:  
1. You are a store owner and you have data records involving customer transactions. Having a private bucket with strict policies will allow this information to only be accessed by those who are authorized to use it.
2. A company makes public facing marketing content, and they are announcing a new product that they are working on, however they want to release this information in a month. Keeping content related to product releases impacts shareholders, customers, and the company itself. To make the largest impact once the announcement is made, they want to have marketing and announcement material made, but they need to keep it hidden from the public before the big announcement in a month. Keeping this content in a private bucket helps maintain the security of that content.  

Related to Step 2, it is definitely not an industry best practice to store database backups in a publicly accessible S3 bucket unless the project or initiative is explicitly open-source. For this exercise and project, there will be login credentials and user specific information that gets generated and stored, so keeping this information publicly accessible is definitely not a recommended approach to storing database backups. Additionally, even if the database has utmost security, exists in a private subnet with strict security group and network access control list rules, has encryption at transit and at rest, if the backups go to a publicly exposed object, none of that matters.


### Phase 1 Basic Setup - Step 3

This part was relatively difficult as I do not have a lot of experience using Kubernetes, however I do have limited experience with EKS and running simple commands. For this, I need to become familiar with a few concepts: 1) What goal was I trying to accomplish?, 2) How could I accomplish that goal? and 3) How can I connect all of the components to make sure it works as expected?

Needless to say, I ran into a surprising number of problems in this step, one of which is you cannot use t2.micro's (at least without significant manipulation) as t2.micro's do not have enough resources to allow for additional pods outside of the default Kubernetes pods, which required me to upgrade my node size to at least t3.medium.  

I followed various tutorials, researched various commands, and collaborated with some friends and colleagues who are knowledgeable in Kubernetes. This is not an easy application orchestrator to try and figure out on the fly. It comes with a lot of nuances. When it is working as expected, it is great, but when troubleshooting it can be very complex. 

I learned a lot about eksctl and kubectl via the command line along with some extremely helpful commands to understand what is currently running in your environment. My favorite command by far is 'kubectl get all -A' because it shows just about everything I need to see to get an understanding of what is going on in the cluster. Three other commands I really enjoy using are 'aws eks list-clusters' (lists which eks clusters you have), 'kubectl config current-context' (shows which cluster you are currently working within) and 'aws eks update-kubeconfig --name CLUSTER_NAME' (command used to change clusters). 

Security Concerns  

The EKS Cluster is currently running in a private subnet. Private subnets are used for security and isolation of resources by restricting internet access to resources within the private subnet, while still allowing for network communication with other resources within the private subnet. Publicly exposing the applications that are running on the cluster using a public facing load balancer defeats the purpose and allows anyone to access the cluster. Second, the load balancer is operating on port 80, allowing traffic from the application to be unencrypted from whatever network a user is accessing the application from. If someone is inspecting network traffic on that same network, they can view details of the information a user obtains from the application in plain text, which is not secure.  

### Phase 1 Basic Setup - Step 4

1. Deploy the container-based web application to the managed Kubernetes cluster.  

I created a Python/Django 'Todo List' web application. I was able to follow along with a great tutorial made by Dennis Ivy, I would recommend checking out his video here: https://www.youtube.com/watch?v=4RWFvXDUmjo&ab_channel=DennisIvy . Once I had it up and running on my local machine, it was time to package it up within a Docker container, and try to run it locally from Docker. Following the containerization part, I sent the image to both my personal Docker respository and my personal AWS public ECR repository, however the container definition contains the AWS ECR url to pull the image.  

2. Configure the routing to allow for public access into the managed cluster using service type load balancer.  

This required appropriate Security Group and Subnet NACL rules, routing tables to allow traffic to go from the private subnet to a NAT gateway in the public subnet, and eventually to the Internet gatway, as well as other services within the public subnet that could use that access. Using 'service type load balancer' was defined in the 'wiz-deployment.yaml' file under the 'Service' kind of resource being applied to my Kubernetes cluster.  


## Phase 2 - Identity & Secrets Setup

## Phase 2 Identity & Secrets Setup - Step 1

1. Configure the container as admin.  

To configure the container as admin, you need to use 'ClusterRoleBinding' as denoted in the 'wiz-deployment.yaml' file. According to the Kubernetes documention, Cluster Role Binding is "To grant permissions across a whole cluster, you can use a ClusterRoleBinding. The following ClusterRoleBinding allows any user in the group "manager" to read secrets in any namespace."  

The provided documentation within the Technical Assessment was very helpful in identifying what is required for admin permissions. I'd like to learn more about the other roles and see what I can/cannot gain access to within the cluster. As a first course of action, I'd ideally like to study for the Kubernetes and Cloud Native Associate exam, followed by the Certified Kubernetes Administrator exam to solidify my knowledge of Kubernetes by way of professional skill building.   

## Phase 2 Identity and Secrets Setup - Step 2

1. Configure the MongoDB VM as highly privileged. Configure permissions which 
allow this virtual machine to create and delete other virtual machines.  

I created a role within AWS called 'EC2OverkillRole' that allows all the required actions to create and delete EC2 instances. I proceeded to attach that role to the EC2 instance that MongoDB is installed and running on called 'MongoDBServer v2'.  

## Phase 2 Identity and Secrets Setup - Step 3

1. MongoDB Connection String: Launch a Bastion Host to connect to your MongoDB isntance. Create a script which remote connects to the MongoDB Instance, creates a backup using Mongodump and uploads this to the storage bucket that you created earlier.  

For this task, I created two bash scripts. The first bash script runs on the Bastion Host and executes upon successful SSH to the Bastion Host. The script in the Bastion Host SSH's to the MongoDBServer v2 EC2 instance and runs a script on the MongoDB server which kicks off the mongodump backup and uploads that backup to the public s3 bucket which has been configured. 

