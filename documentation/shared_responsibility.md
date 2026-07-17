# Cloud Security Shared Responsibility Matrix

This document outlines the security responsibilities between the cloud service provider (AWS) and our organization for the 3-Tier hardened infrastructure deployment.

## 1. Overview: Security "OF" the Cloud vs. Security "IN" the Cloud
*   **The Cloud Provider (AWS)** is responsible for the physical security, hardware, global infrastructure, and virtualization layer that runs the cloud services (Security **OF** the Cloud).
*   **The Customer (Our Organization)** is responsible for configuring, maintaining, and protecting the virtual resources, access controls, network rules, operating systems, and data deployed within that infrastructure (Security **IN** the Cloud).

---

## 2. Multi-Cloud Shared Responsibility Comparison

| Layer / Component | AWS Responsibility | Customer (Our) Responsibility |
| :--- | :--- | :--- | :--- | :--- |
| **Physical & Data Center Security** | Physical security of AWS regions, edge locations, and physical host hardware. We assume zero physical management. |
| **Network Infrastructure (Underlay)** | Logical isolation of virtual networks (VPC underlay routing, physical switches). | Isolation of physical fabric networks, SDN planes, and cloud routers. | Core global private WAN, SDN isolation, physical routing, and edge points. | **VPC Configuration**: Constructing subnets, routing tables, Network ACLs, security group policies, and internet egress controls. |
| **Identity & Access Management (Control Plane)** | Providing the IAM policy engine, MFA framework, and authentication APIs. | Providing Cloud IAM infrastructure and service account management planes. | **Least-Privilege Configuration**: Mapping custom roles (`CloudSecAuditRole`, `PlatformOpsRole`), defining permission boundaries, and enforcing MFA policies. |
| **Storage & Data Integrity** | S3 bucket isolation, KMS service availability, EBS physical volume lifecycle. | Cloud Storage multi-tenancy validation, Cloud KMS operational availability. | **Data Protection**: Enforcing S3 encryption (SSE-KMS), block public access configuration, enabling bucket object locks, and key rotation management. |
| **Compute / Virtual Machines (Guest OS)** | Bare-metal host patching and virtualization hypervisor security. | Host OS virtualization layer security | **OS & App Hardening**: Patching guest operating systems, maintaining secure container base images, and managing internal application software code. |

---

## 3. Scope of Our Target 3-Tier Workload (IaaS)
Because we are utilizing **IaaS (Infrastructure as a Service)** components (Amazon EC2/ECS, Amazon VPC, and Customer-Managed KMS keys) for our 3-tier application, our responsibility profile is high:
1.  **Network Layer:** We must build the subnets, routes, and security groups to keep the application private and isolated.
2.  **Access Layer:** We must write zero-trust IAM policies with strict permission sets.
3.  **Data Layer:** We must configure and rotate KMS keys and enforce strict server-side encryption with access logging.