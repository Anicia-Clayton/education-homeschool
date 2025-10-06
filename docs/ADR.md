# Architecture Decision Record (ADR)
## Project: Education × Cloud Security

### ADR-001: Implement Role-Based Access Control
**Context:** Different permissions needed for Parents, Students, and Tutors.  
**Decision:** Use Cognito groups and JWT-based authorizers.  
**Rationale:** Enforces least privilege and separation of duties.

### ADR-002: Apply CIS AWS Conformance Pack
**Context:** Must validate compliance continuously.  
**Decision:** Use AWS Config CIS pack.  
**Rationale:** Simplifies compliance reporting and alerts.

### ADR-003: Enforce MFA for All Users
**Context:** Data involves minors and educational progress.  
**Decision:** Require Cognito MFA.  
**Rationale:** Prevents credential misuse or unauthorized access.
