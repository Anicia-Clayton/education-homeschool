#!/usr/bin/env python3
"""Get a Cognito JWT for testing protected API routes.

This script will:
1) Ensure a user exists in the specified User Pool (creates if missing)
2) Set a permanent password (if needed)
3) Perform ADMIN_USER_PASSWORD_AUTH to fetch ID/Access tokens

Requirements:
- AWS credentials with permissions for Cognito IDP admin APIs
- App client WITHOUT secret created by the Terraform module
- Environment variables configured (see below)

Env vars:
  AWS_REGION           e.g. us-east-1
  USER_POOL_ID         e.g. us-east-1_ABC123
  APP_CLIENT_ID        e.g. 1h57kf5cpq17m0eml12EXAMPLE
  USERNAME             e.g. testuser@example.com
  PASSWORD             e.g. S0meLongerP@ssw0rd!
Optional:
  MFA_CODE             if MFA is ON and required

Usage:
  pip install -r requirements.txt
  export AWS_REGION=us-east-1 USER_POOL_ID=... APP_CLIENT_ID=... USERNAME=... PASSWORD='...'
  python tools/get_cognito_jwt.py
"""
import os, sys, json, boto3
from botocore.exceptions import ClientError

REGION = os.environ.get("AWS_REGION")
USER_POOL_ID = os.environ.get("USER_POOL_ID")
APP_CLIENT_ID = os.environ.get("APP_CLIENT_ID")
USERNAME = os.environ.get("USERNAME")
PASSWORD = os.environ.get("PASSWORD")
MFA_CODE = os.environ.get("MFA_CODE")

def die(msg):
    print(msg, file=sys.stderr)
    sys.exit(1)

for k, v in [("AWS_REGION", REGION), ("USER_POOL_ID", USER_POOL_ID), ("APP_CLIENT_ID", APP_CLIENT_ID), ("USERNAME", USERNAME), ("PASSWORD", PASSWORD)]:
    if not v:
        die(f"Missing required env var: {k}")

idp = boto3.client("cognito-idp", region_name=REGION)

def ensure_user(username):
    try:
        idp.admin_get_user(UserPoolId=USER_POOL_ID, Username=username)
        return "exists"
    except ClientError as e:
        if e.response["Error"]["Code"] == "UserNotFoundException":
            print("User not found; creating...")
            idp.admin_create_user(
                UserPoolId=USER_POOL_ID,
                Username=username,
                UserAttributes=[{"Name":"email","Value":username},{"Name":"email_verified","Value":"True"}],
                MessageAction="SUPPRESS"
            )
            # set a permanent password
            idp.admin_set_user_password(
                UserPoolId=USER_POOL_ID,
                Username=username,
                Password=PASSWORD,
                Permanent=True
            )
            return "created"
        else:
            raise

def auth(username, password):
    try:
        resp = idp.admin_initiate_auth(
            UserPoolId=USER_POOL_ID,
            ClientId=APP_CLIENT_ID,
            AuthFlow="ADMIN_USER_PASSWORD_AUTH",
            AuthParameters={"USERNAME": username, "PASSWORD": password}
        )
        if resp.get("ChallengeName") == "SOFTWARE_TOKEN_MFA":
            if not MFA_CODE:
                die("MFA required; set MFA_CODE env var then retry.")
            resp = idp.admin_respond_to_auth_challenge(
                UserPoolId=USER_POOL_ID,
                ClientId=APP_CLIENT_ID,
                ChallengeName="SOFTWARE_TOKEN_MFA",
                ChallengeResponses={"USERNAME": username, "SOFTWARE_TOKEN_MFA_CODE": MFA_CODE},
                Session=resp["Session"]
            )
        return resp["AuthenticationResult"]
    except ClientError as e:
        die(f"Auth error: {e}")

state = ensure_user(USERNAME)
print(f"User state: {state}")

tokens = auth(USERNAME, PASSWORD)
print(json.dumps({
    "IdToken": tokens.get("IdToken"),
    "AccessToken": tokens.get("AccessToken"),
    "ExpiresIn": tokens.get("ExpiresIn"),
    "TokenType": tokens.get("TokenType")
}, indent=2))
print("\nTip: Use the IdToken with API Gateway JWT authorizer, e.g.:")
print("  curl -H "Authorization: Bearer $(python tools/get_cognito_jwt.py | jq -r .IdToken)" \")
print("       "$API_BASE_URL/secure/v1/progress"")
