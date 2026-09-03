#!/usr/bin/env python3
import os
import sys
import time
import base64
import subprocess
import jwt
import requests

def main():
    print("=== Sobo Society App Store Connect API Signing Setup ===")
    
    key_id = os.environ.get("APP_STORE_CONNECT_KEY_IDENTIFIER")
    issuer_id = os.environ.get("APP_STORE_CONNECT_ISSUER_ID")
    private_key_str = os.environ.get("APP_STORE_CONNECT_PRIVATE_KEY")
    bundle_id_name = os.environ.get("BUNDLE_ID", "com.sobosociety.app")

    if not key_id or not issuer_id or not private_key_str:
        print("ERROR: Missing App Store Connect API Key environment variables.")
        sys.exit(1)

    # 1. Generate JWT Token for App Store Connect API
    payload = {
        "iss": issuer_id,
        "exp": int(time.time()) + 1200,
        "aud": "appstoreconnect-v1"
    }
    headers = {
        "kid": key_id,
        "typ": "JWT"
    }
    
    try:
        token = jwt.encode(payload, private_key_str, algorithm="ES256", headers=headers)
        if isinstance(token, bytes):
            token = token.decode("utf-8")
    except Exception as e:
        print(f"ERROR: Failed to generate JWT token: {e}")
        sys.exit(1)

    api_headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # 2. Query Certificates from App Store Connect API
    print("Fetching certificates from App Store Connect API...")
    res = requests.get("https://api.appstoreconnect.apple.com/v1/certificates", headers=api_headers)
    if res.status_code != 200:
        print(f"ERROR: Failed to fetch certificates: {res.status_code} {res.text}")
        sys.exit(1)

    certs_data = res.json().get("data", [])
    print(f"Found {len(certs_data)} certificates on Apple Developer Account.")

    # Find certificates and save them as DER/PEM
    home_dir = os.path.expanduser("~")
    prov_dir = os.path.join(home_dir, "Library", "MobileDevice", "Provisioning Profiles")
    os.makedirs(prov_dir, exist_ok=True)

    imported = False
    for idx, cert in enumerate(certs_data):
        cert_type = cert.get("attributes", {}).get("certificateType")
        cert_content = cert.get("attributes", {}).get("certificateContent")
        if not cert_content:
            continue
        
        cert_bytes = base64.b64decode(cert_content)
        cer_path = f"/tmp/cert_{idx}.cer"
        pem_path = f"/tmp/cert_{idx}.pem"
        p12_path = f"/tmp/cert_{idx}.p12"

        with open(cer_path, "wb") as f:
            f.write(cert_bytes)

        # Convert DER to PEM
        subprocess.run(["openssl", "x509", "-in", cer_path, "-inform", "DER", "-out", pem_path], check=False)

        # Create P12 using sobo_private_key.key
        key_path = "sobo_private_key.key"
        if not os.path.exists(key_path):
            key_path = os.path.join("ios", "sobo_private_key.key")

        cmd = [
            "openssl", "pkcs12", "-export",
            "-out", p12_path,
            "-inkey", key_path,
            "-in", pem_path,
            "-passout", "pass:sobo123"
        ]
        res_p12 = subprocess.run(cmd, capture_output=True)
        if res_p12.returncode == 0:
            print(f"Successfully matched certificate {cert.get('id')} ({cert_type}) with private key!")
            # Import into keychain
            keychain_path = os.path.join(home_dir, "Library", "Keychains", "login.keychain-db")
            subprocess.run(["security", "import", p12_path, "-k", keychain_path, "-P", "sobo123", "-T", "/usr/bin/codesign"], check=False)
            subprocess.run(["security", "import", p12_path, "-P", "sobo123"], check=False)
            imported = True
        else:
            print(f"P12 creation result for cert {idx}: {res_p12.stderr.decode('utf-8')}")

    if not imported:
        print("WARNING: Could not match certs with P12 directly, proceeding to download profiles...")

    # 3. Query Provisioning Profiles from App Store Connect API
    print(f"Fetching provisioning profiles for {bundle_id_name}...")
    res_prof = requests.get("https://api.appstoreconnect.apple.com/v1/profiles?limit=50", headers=api_headers)
    if res_prof.status_code != 200:
        print(f"ERROR: Failed to fetch profiles: {res_prof.status_code} {res_prof.text}")
        sys.exit(1)

    profiles_data = res_prof.json().get("data", [])
    print(f"Found {len(profiles_data)} total profiles on Apple Developer Account.")

    for prof in profiles_data:
        prof_name = prof.get("attributes", {}).get("name", "")
        prof_content = prof.get("attributes", {}).get("profileContent", "")
        prof_uuid = prof.get("attributes", {}).get("uuid", "")
        
        if prof_content:
            prof_bytes = base64.b64decode(prof_content)
            target_uuid_path = os.path.join(prov_dir, f"{prof_uuid}.mobileprovision")
            target_name_path = os.path.join(prov_dir, f"{prof_name}.mobileprovision")
            
            with open(target_uuid_path, "wb") as f:
                f.write(prof_bytes)
            with open(target_name_path, "wb") as f:
                f.write(prof_bytes)
                
            print(f"Saved Provisioning Profile '{prof_name}' ({prof_uuid}) to {prov_dir}")

    print("=== Setup Signing Completed Successfully ===")

if __name__ == "__main__":
    main()
