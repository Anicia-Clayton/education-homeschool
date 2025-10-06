#!/usr/bin/env python3
"""Helper script to create a Cognito test user and fetch a JWT for API testing.

Usage:
  python cognito_test_user.py --user-pool-id <pool> --client-id <client> --username test1 --password 'MyStrongPassw0rd!' --region us-east-1
"""
import boto3, argparse, sys

parser = argparse.ArgumentParser()
parser.add_argument("--user-pool-id", required=True)
parser.add_argument("--client-id", required=True)
parser.add_argument("--username", default="testuser1")
parser.add_argument("--password", default="MyStrongPassw0rd!")
parser.add_argument("--region", default="us-east-1")
args = parser.parse_args()

client = boto3.client("cognito-idp", region_name=args.region)

try:
    client.sign_up(ClientId=args.client_id, Username=args.username, Password=args.password)
    print(f"User {args.username} created. Check your pool's auto-confirmation settings.")
except client.exceptions.UsernameExistsException:
    print("User already exists, skipping sign_up.")

# Try auth
resp = client.initiate_auth(
    ClientId=args.client_id,
    AuthFlow="USER_PASSWORD_AUTH",
    AuthParameters={"USERNAME": args.username, "PASSWORD": args.password},
)
id_token = resp["AuthenticationResult"]["IdToken"]
access_token = resp["AuthenticationResult"]["AccessToken"]
refresh_token = resp["AuthenticationResult"].get("RefreshToken")

print("\nTokens:")
print("ID Token:", id_token)
print("Access Token:", access_token)
if refresh_token:
    print("Refresh Token:", refresh_token)

print("\nTry calling your API with:")
print(f"curl -H 'Authorization: Bearer {id_token}' https://<api_id>.execute-api.{args.region}.amazonaws.com/secure/v1/...")
