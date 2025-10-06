# Education × Cloud Security – Homeschool API (Minimal AWS Stack + AWS Config)
**Goal:** Secure homeschooling API for high-travel families with anonymized progress and tutor matching, plus **AWS Config** runtime checks.

## Stack
- API Gateway (HTTP) → Lambda
  - `GET /v1/progress` (anonymized progress)
  - `POST /v1/tutor-match` (recommendations)
- DynamoDB (encrypted with KMS CMK); CloudWatch logs
- **AWS Config baseline** (recorder+delivery+managed rules + small conformance pack)

## Deploy (dev)
1) Configure backend in `infra/envs/dev/providers.tf` `backend "s3"`.
2) Build Lambda zip:
   ```bash
   cd infra/modules/api/package
   zip -r lambda.zip lambda_function.py
   ```
3) Apply:
   ```bash
   cd infra/envs/dev
   terraform init
   terraform apply -auto-approve
   ```
4) Test:
   ```bash
   curl "$API_BASE_URL/v1/progress"
   curl -X POST "$API_BASE_URL/v1/tutor-match" -d '{"student_id":"123"}'
   ```

## Security
- Pseudonymous student IDs
- KMS CMK for DynamoDB SSE
- IAM least-privilege for Lambda (table-scoped)
- **AWS Config**: S3 SSE, DynamoDB KMS, Lambda no public access, S3 no public read
- tfsec workflow in `.github/workflows/terraform-security-check.yml`


## Optional: Add Cognito (parents/students/tutors)
1) Open `infra/examples/enable_cognito.tf` and keep the module block enabled.
2) `terraform apply`.
3) Next step: add an API Gateway **JWT authorizer** referencing the User Pool to protect routes.


## Optional: Protect routes with Cognito JWT authorizer
1) Ensure Cognito is enabled via `infra/examples/enable_cognito.tf`.
2) Enable authorizer: `infra/examples/enable_authorizer.tf` (creates `/secure/v1/*` routes protected by JWT).
3) Deploy: run `terraform apply` again.
4) Call with a valid `Authorization: Bearer <JWT>` from your User Pool.


## Helper: Get a Cognito JWT for testing
1) Ensure Cognito and JWT authorizer are enabled (see Optional sections above).
2) Install deps and fetch a token:
```bash
cd tools
pip install -r requirements.txt
export AWS_REGION=us-east-1 USER_POOL_ID=<from outputs> APP_CLIENT_ID=<from outputs> \\
       USERNAME=testparent@example.com PASSWORD='S0meLongerP@ssw0rd!'
python get_cognito_jwt.py | jq -r .IdToken
```
3) Call a protected route:
```bash
export IDTOKEN=$(python get_cognito_jwt.py | jq -r .IdToken)
curl -H "Authorization: Bearer $IDTOKEN" "$API_BASE_URL/secure/v1/progress"
```
