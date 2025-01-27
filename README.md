**Deployed webservers in AWS by using Infrastructure as Code using custom AMI ID**


Part - 01
Setting up the environment:
•	Creating an AWS org named root.
 ![image](https://github.com/user-attachments/assets/4acbd4d2-3319-44ea-a14a-281b661357a3)

•	Now, we create a IAM group for instructors with non-CLI access which means we can give the ReadOnlyAccess to them.
 
![image](https://github.com/user-attachments/assets/57ec5fc0-08fe-4ca9-9fa2-0ead5ee3c1ac)
 

![image](https://github.com/user-attachments/assets/2ea01321-458d-4324-b6e2-150a552f2cb1)


•	Now create a VPC with DNS support and DNS hostnames enabled with suitable CIDR with the help of Terraform script.
 

![image](https://github.com/user-attachments/assets/4ea1f28a-f518-4389-b12a-e8b7414cc31d)

![image](https://github.com/user-attachments/assets/9030c6c8-2a0e-4819-9eb4-24ddc31a8385)






•	Creating 3 Subnets of equal sizes which can talk each other 
 ![image](https://github.com/user-attachments/assets/6d5fe7ae-4af8-4663-8e52-3aac229fe5a1)
 ![image](https://github.com/user-attachments/assets/c50468a3-828b-42e5-869d-88c9ee49d643)

 

•	Now, We create a single Gateway and attach it to our VPC
 
 
![image](https://github.com/user-attachments/assets/ca57f528-41ec-48a3-a9f2-dc2e86588728)
![image](https://github.com/user-attachments/assets/b35affb2-0ad1-4c30-8f86-7b8dec480a8e)







•	Create a Routing Table and giving a public route 0.0.0.0 to the internet and also associating this public route to each subnet
 
 ![image](https://github.com/user-attachments/assets/6021c866-1e1a-4b82-9692-1305d793873a)
 ![image](https://github.com/user-attachments/assets/980112b7-3b40-4506-9044-fbfb878d1342)
 ![image](https://github.com/user-attachments/assets/d78636b5-5ddb-430d-bfd5-c818464855a4)

 

•	Creating a web-security group
 
 ![image](https://github.com/user-attachments/assets/5ec8407f-3d58-4d3a-8544-31790dff3bf6)
 ![image](https://github.com/user-attachments/assets/7854a419-9018-47d5-9928-e18e3d4f0465)

•	Creating an EC2 instance with a standard AMI 
 ![image](https://github.com/user-attachments/assets/cbab1b4f-348b-4130-9e3c-cb3d29df97f1)
 ![image](https://github.com/user-attachments/assets/ccf57f83-ee49-4f9b-a91a-7d85db1dbcb8)
 
 
For the above variables we have created a terraform.tfvars file and store in out local system and not hardcoding the values into the script.
 ![image](https://github.com/user-attachments/assets/3d78813e-f893-4e0c-84c8-4c55af0215d0)
 ![image](https://github.com/user-attachments/assets/19393c91-14b1-4984-9c02-7371e6ce7bed)


 

•	Creating appropriate dbsecurity groups
 
 ![image](https://github.com/user-attachments/assets/075d1523-fab0-4424-b044-71be3f2efc64)
 ![image](https://github.com/user-attachments/assets/10ee73ff-0be8-4416-a27f-a0e9b8ddfe0c)




Part-02
•	Baking a new AMI ID using Ansible
 ![image](https://github.com/user-attachments/assets/2303428b-f1ef-41da-858a-6629c949ee1e)

•	Installing all necessary packages and also included the If the CPU usage increases over 90% then the script should stop.
 
 ![image](https://github.com/user-attachments/assets/bca75e67-eaf1-4650-8154-0cf42140e5bc)
 ![image](https://github.com/user-attachments/assets/f5199e9d-66c1-4c57-a6ac-7c7879c5b81d)
 ![image](https://github.com/user-attachments/assets/29e39f35-aa80-4e72-ab97-825377059e50)
 ![image](https://github.com/user-attachments/assets/d5b1f67f-1399-4612-b9de-ff046a3d1fdc)

 
•	Using Terraform to create a VPC with 3 subnets
![image](https://github.com/user-attachments/assets/dddb79a2-62a9-4896-a878-4aca3b5ca7fb)
![image](https://github.com/user-attachments/assets/f7a67c1e-c4c7-4771-8462-8852096abc99)
![image](https://github.com/user-attachments/assets/b6c42115-726c-4ceb-b4f3-43127add24d2)
![image](https://github.com/user-attachments/assets/8d6331bf-8941-45ed-a825-bd0006b27581)
![image](https://github.com/user-attachments/assets/37e04f2b-386b-4207-9522-805d29489c46)
![image](https://github.com/user-attachments/assets/6b4a5d08-f06a-4c92-835f-113dbb5526d9)
![image](https://github.com/user-attachments/assets/97a49505-0f64-4d62-9fd4-33503c191297)
 
 

•	Creating Auto Scaling Group

 ![image](https://github.com/user-attachments/assets/b08e27a2-bd4c-46f9-8376-816a72f92c25)
 ![image](https://github.com/user-attachments/assets/fb0de664-cf8e-4694-9f1f-24fa8e22629a)

 
•	Similarly, created a Cloudwatch alarm for high and low cpu usage
 
 ![image](https://github.com/user-attachments/assets/dff3f8fc-6761-49c4-8d24-90ed11913426)
 ![image](https://github.com/user-attachments/assets/2d53faa9-5cbb-4d64-88c3-3a0e34eae486)
 ![image](https://github.com/user-attachments/assets/ecf41032-3f32-413f-82b5-6527b9c5f6b3)
 ![image](https://github.com/user-attachments/assets/f477980f-e8f4-4042-b8b0-43d5d6456c60)

 
 

