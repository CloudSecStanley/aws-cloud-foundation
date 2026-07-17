# STRIDE Threat Model: Hardened 3-Tier Application

This document decomposes our secure 3-tier architecture into its core components and applies the **STRIDE methodology** to identify potential threats and document their specific cloud-native mitigations.

## 1. System Boundary and Data Flow

[User Request] ➔ [Public Internet] ➔ (WAF/ALB Trust Boundary) ➔ [App Servers (Private Subnet)] ➔ [RDS Database (Isolated Subnet)]
│
└─➔ [S3 Logs & CloudTrail (Encrypted Store)]


---

## 2. STRIDE Threat and Mitigation Matrix

| Threat Category | Target Component | Threat Scenario | Impact / Blast Radius | Technical Mitigation (Our Countermeasures) |
| :--- | :--- | :--- | :--- | :--- |
| **S**poofing | AWS Console & API Access | Compromise of administrator identity due to weak authentication or leaked access credentials. | Full account takeover, data deletion, and malicious infrastructure creation. | **Zero Static Credentials:** Disable local IAM user access keys. Enforce AWS Single Sign-On (SSO) with Multi-Factor Authentication (MFA). |
| **S**poofing | ALB / Web Front-end | Attackers intercepting or spoofing traffic destined for the public application load balancer. | Man-in-the-Middle (MitM) attacks, data interception in transit. | **Strict TLS & WAF:** Implement AWS Certificate Manager (ACM) to enforce strictly **TLS 1.3** and attach AWS WAF to the ALB to block bad actors. |
| **T**ampering | S3 Logging Buckets | An attacker (or compromised role) attempts to delete or modify CloudTrail logs to cover their tracks. | Total loss of non-repudiation and compromised forensic analysis capability. | **S3 Object Lock & SSE-KMS:** Configure S3 log buckets in **Compliance Mode with Object Lock (WORM)**, write a bucket policy denying `s3:DeleteObject`, and encrypt using KMS CMKs. |
| **T**ampering | RDS Database | Unauthorized database modification, manipulation of records, or configuration updates. | Loss of database integrity, application malfunction. | **Subnet Isolation & Network Micro-segmentation:** Host database in Isolated Subnets (no internet routes) and bind a Security Group that *only* accepts inbound traffic from the app servers on port 3306. |
| **R**epudiation | Cloud Infrastructure API | An unauthorized user performs a privileged configuration action (e.g., terminating a firewall rule) and denies doing so. | Inability to establish legal liability or trace the origin of a system breach. | **Multi-Region CloudTrail Logging:** Deploy AWS CloudTrail across all regions and forward logs immediately to an encrypted, read-only S3 bucket with strict MFA delete configurations. |
| **I**nformation Disclosure | S3 Storage & Database Backup | Sensitive customer data or logging datasets are left publicly readable on S3 or unencrypted on disk. | Exposure of personally identifiable information (PII), compliance violations, and data leak. | **S3 Block Public Access & KMS CMK Encryption:** Apply S3 Block Public Access at the account level. Force AES-256 encryption using Customer Managed Keys (CMKs) with automatic annual rotation. |
| **D**enial of Service | Application Entry Point | Large-scale volumetric or HTTP application layer flood (DDoS) targeting the application endpoint. | Application outage and service unavailability to legitimate users. | **AWS Shield Standard & Auto Scaling:** Place the application backend behind an ALB with an Auto Scaling Group, and leverage AWS Route 53 with AWS WAF for perimeter rate limiting. |
| **E**levation of Privilege | App Servers (EC2/ECS Tasks) | An application-level exploit allows an attacker to gain control of the hosting environment and inherit its permissions. | Attacker can query the AWS metadata service and assume highly privileged IAM Roles. | **Task Role Isolation:** Assign a granular IAM Task Role to the container runtime containing only the specific policies needed to function (e.g., read Secrets, write to DB), blocking access to structural management APIs. |

---

## 3. Next Steps
These threat mitigations will be translated directly into Infrastructure as Code (Terraform) configurations. Before any code is committed, **Checkov** static analysis will be run to verify that all mitigations defined in this matrix are physically represented in our HCL configuration.