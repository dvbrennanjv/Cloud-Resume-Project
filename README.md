# Cloud Resume Project

---

## Technologies Used  
- AWS  
- Terraform  
- HTML / CSS / JavaScript  
- Python  
- Jenkins  
- GitHub
- Azure (for DNS/Hosting Jenkins)

---

## Useful Links
AWS Terraform Registry Documentation : https://registry.terraform.io/providers/hashicorp/aws/latest/docs
CloudFront Docs : https://docs.aws.amazon.com/cloudfront/
S3 Docs : https://docs.aws.amazon.com/s3/

---

## Security Best Practices

1. **Avoid exposing bucket names in public repositories**  
   Store bucket names in `terraform.tfvars` or `locals.tf` files that are excluded from version control. Public bucket names can be exploited for object brute forcing, phishing, or scams.

2. **Sanitize CloudFront configuration before publishing**  
   Remove or generalize sensitive settings such as TTLs, cookie forwarding, and caching behaviors. These details can be abused to generate unwanted traffic or cache misuse.

3. **Keep bucket policies in a separate file and add it to `.gitignore`**  
   This prevents accidental exposure of sensitive bucket permissions or ARNs in public repos.

4. **Using up to date security protocols**
   I reccomend when setting up the SSL certificate with CloudFront that you use also specify to use the latest security policy (TLSv1.2_2021 in my case) as well as using HTTP/3
   It requires no extra steps on the bucket as CloudFront will handle the negotiation automatically.

---

## How-To Guide

### Step 1: GitHub and Terraform Setup  
Create a new GitHub repository to manage your source code with version control. Clone this repository locally to organize your Terraform files, scripts, and other resources. This repo will also integrate with Jenkins later for automated deployments.

### Step 2: S3 Bucket Creation  
Use Terraform to provision an S3 bucket for hosting your static site assets (HTML, CSS, JavaScript). Keep static website hosting **disabled** since CloudFront will handle content delivery.  
*Note:* While it’s good practice to use a separate bucket for Terraform state files, for solo projects it’s acceptable to keep the state locally.

### Step 3: CloudFront Distribution Setup  
Configure CloudFront via Terraform to use your S3 bucket as the origin. Enable Origin Access Control (OAC) to restrict bucket access exclusively to CloudFront. Set viewer protocol policy to redirect all HTTP traffic to HTTPS, preparing for SSL certificate integration.

### Step 4 Purchase Domain and SSL Cert
Next we want to a custom domain name instead of just the cloudfront domain name. We can purchase a domain for as little as 12$ from Route 53. We can then use AWS Certificate Manager to generate an SSL certificate. To validate it we need to add the CNAME records to our hosted zone. I use Azure to host my DNS records for my domains and terraform to create the records but you it may be simpler to just use AWS for and add the records via the console.
*Note:* The SSL Cert needs to be requested in the North Virginia Region to work with CloudFront

### Step 5 Integrating our new Domain and SSL Cert with Cloud Front
Right, now that we have our domain and SSL certificate all ready, lets now use these for our CloudFront distribution. We'll head over to where we our hosting our DNS recordsets and create a new CNAME record and link it to our distributions domain name. Again we'll use terraform to create this record. We'll need to edit our cloudfront distribution as well and add and alias that matches our new domain name.

### Step 6 Adding a View Counter (Optional Step)

---


