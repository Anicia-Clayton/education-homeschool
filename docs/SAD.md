# Solutions Architecture Document (SAD)
## Project: Education × Cloud Security (Homeschool Platform)

### 1. Overview
Secure, private API for high-travel homeschool families.  
Protects learner progress, tutor profiles, and resource data using identity-based access and encryption.

### 2. Goals
- Isolate user access by role (Parent, Student, Tutor).
- Encrypt all data at rest and in transit.
- Maintain compliance with CIS AWS Foundations Benchmark.
- Achieve 0 critical findings in tfsec scan.

### 3. Architecture Summary
**Pattern:** Serverless microservice with role-based access.  
**Stack:** API Gateway → Lambda → DynamoDB (KMS) + Cognito + AWS Config.

### 4. Data Flow
1. Cognito authenticates user (Parent/Student/Tutor).  
2. API Gateway validates JWT → Lambda executes CRUD operation.  
3. Data stored in encrypted DynamoDB.  
4. AWS Config monitors for policy violations.

### 5. Key AWS Services
| Layer | Service | Purpose |
|-------|----------|----------|
| Identity | Cognito | Role-based auth with MFA |
| Compute | Lambda | Process requests |
| Storage | DynamoDB (KMS) | Secure learner data |
| Security | IAM | Fine-grained access control |
| Compliance | AWS Config | Continuous runtime compliance |

### 6. Security & Compliance
- Cognito MFA & group segregation.
- IAM fine-grained access (resource-level).
- tfsec scanning & CI/CD gating.
- AWS Config Conformance Pack (CIS Benchmark).

### 7. Future Enhancements
- Integrate WAF for API protection.
- Add audit dashboards for activity tracking.
- Extend Config to monitor Cognito drift.
