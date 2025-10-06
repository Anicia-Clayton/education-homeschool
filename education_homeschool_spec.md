# Education × Cloud Security (Homeschool Platform)
**One-page spec**

**Goal:**  
Secure a homeschool learning API for high-travel families by protecting student progress and tutor data with privacy-by-design controls.

**What you’ll build:**  
A serverless, private API that manages course progress and tutor recommendations, protected by Cognito authentication and runtime compliance checks.

**AWS (≤6):**  
API Gateway (HTTP), Lambda, DynamoDB (student-progress table), Cognito (user pools/groups), IAM (least privilege), AWS Config (CIS pack).

---

### **Success metrics**
- Cognito users and roles: parents/tutors/students segregated by least privilege.  
- DynamoDB encrypted (KMS) and not publicly accessible.  
- AWS Config: 100% compliance with baseline rules (no public resources).  
- tfsec scan: 0 high/critical findings.  

---

### **Deliverables**
- DynamoDB table: `student_progress` (partition key: student_id).  
- Lambda handlers for CRUD (get/update progress).  
- Cognito user pool + groups: **Parent**, **Student**, **Tutor**.  
- IAM policy: fine-grained table access per group.  
- AWS Config Conformance Pack (CIS AWS Foundations Benchmark).  
- tfsec report + “what we hardened” summary.  

---

### **2-week sprint**
- **Day 1–2:** Design API schema; seed DynamoDB with sample learners.  
- **Day 3–4:** Build Lambda functions; link with API Gateway.  
- **Day 5:** Add Cognito user pools/groups; implement JWT authorizer.  
- **Day 6:** Lock down IAM policies; enable KMS encryption.  
- **Day 7–8:** Deploy AWS Config conformance pack; review findings.  
- **Day 9:** Run tfsec scans; remediate; document security notes.  
- **Day 10:** Demo + export compliance reports; backlog (WAF, audit dashboards).

