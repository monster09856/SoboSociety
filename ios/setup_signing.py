#!/usr/bin/env python3
import os
import sys
import time
import base64
import subprocess
import traceback

def main():
    print("=== Sobo Society Automated REST API Signing Setup ===")
    
    print("Environment variables matching APP/STORE/KEY/ISSUER:")
    for k in sorted(os.environ.keys()):
        if any(w in k.upper() for w in ["APP", "STORE", "KEY", "ISSUER", "CONNECT"]):
            val = os.environ[k]
            preview = val[:10] + "..." if len(val) > 10 else val
            print(f"  {k} = {preview}")

    key_id = (
        os.environ.get("APP_STORE_CONNECT_KEY_IDENTIFIER") or
        os.environ.get("APP_STORE_CONNECT_KEY_ID") or
        os.environ.get("APP_STORE_CONNECT_KEY") or
        os.environ.get("KEY_ID")
    )
    issuer_id = (
        os.environ.get("APP_STORE_CONNECT_ISSUER_ID") or
        os.environ.get("ISSUER_ID")
    )
    private_key_str = (
        os.environ.get("APP_STORE_CONNECT_PRIVATE_KEY") or
        os.environ.get("APP_STORE_CONNECT_KEY") or
        os.environ.get("PRIVATE_KEY")
    )
    bundle_id_name = os.environ.get("BUNDLE_ID", "com.sobosociety.app")

    print(f"Resolved -> Key ID: {key_id is not None}, Issuer ID: {issuer_id is not None}, Private Key: {private_key_str is not None}")

    if not key_id or not issuer_id or not private_key_str:
        print("ERROR: Missing App Store Connect API Key environment variables.")
        sys.exit(1)

    # Clean key string
    if "\\n" in private_key_str:
        private_key_str = private_key_str.replace("\\n", "\n")
    if "-----BEGIN" not in private_key_str:
        private_key_str = "-----BEGIN PRIVATE KEY-----\n" + private_key_str.strip() + "\n-----END PRIVATE KEY-----\n"

    try:
        import jwt
        import requests
    except ImportError:
        print("Installing required python modules: pyjwt, requests, cryptography...")
        subprocess.run(["pip3", "install", "--break-system-packages", "pyjwt", "requests", "cryptography"], check=False)
        import jwt
        import requests

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
        print("Successfully generated App Store Connect JWT token.")
    except Exception as e:
        traceback.print_exc()
        print(f"ERROR: Failed to generate JWT token: {e}")
        sys.exit(1)

    api_headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # 2. Ensure local RSA Private Key and CSR exist
    key_path = "sobo_private_key.key"
    if not os.path.exists(key_path):
        key_path = os.path.join("ios", "sobo_private_key.key")
    
    csr_path = "/tmp/request.csr"
    if not os.path.exists(key_path):
        print("Generating fresh RSA 2048 private key...")
        subprocess.run(["openssl", "genrsa", "-out", key_path, "2048"], check=True)
    
    print("Generating CSR from private key...")
    subprocess.run([
        "openssl", "req", "-new", "-key", key_path,
        "-out", csr_path,
        "-subj", "/emailAddress=sedaterdemci98@gmail.com, CN=Sedat ERDEMCI, C=TR"
    ], check=True)

    with open(csr_path, "r") as f:
        csr_pem = f.read()

    # 3. Query existing certificates from App Store Connect API
    print("Fetching existing certificates...")
    res = requests.get("https://api.appstoreconnect.apple.com/v1/certificates", headers=api_headers)
    certs_data = res.json().get("data", []) if res.status_code == 200 else []
    print(f"API Certificate fetch status: {res.status_code}, Found: {len(certs_data)}")

    matching_cert_id = None
    cert_der_bytes = None

    # Try matching existing certificates with key_path
    for idx, cert in enumerate(certs_data):
        cert_content = cert.get("attributes", {}).get("certificateContent")
        if not cert_content:
            continue
        c_bytes = base64.b64decode(cert_content)
        cer_p = f"/tmp/test_{idx}.cer"
        pem_p = f"/tmp/test_{idx}.pem"
        p12_p = f"/tmp/test_{idx}.p12"
        with open(cer_p, "wb") as f:
            f.write(c_bytes)
        subprocess.run(["openssl", "x509", "-in", cer_p, "-inform", "DER", "-out", pem_p], check=False)
        res_p12 = subprocess.run([
            "openssl", "pkcs12", "-export", "-out", p12_p,
            "-inkey", key_path, "-in", pem_p, "-passout", "pass:sobo123"
        ], capture_output=True)
        
        if res_p12.returncode == 0:
            print(f"Matched existing Certificate {cert.get('id')} with local Private Key!")
            matching_cert_id = cert.get("id")
            cert_der_bytes = c_bytes
            break

    # If no certificate matches local Private Key, create a new IOS_DISTRIBUTION certificate via API
    if not matching_cert_id:
        print("No matching certificate found for local private key. Creating new IOS_DISTRIBUTION certificate via REST API...")
        
        # Revoke old certificates if limit (2) reached
        dist_certs = [c for c in certs_data if c.get("attributes", {}).get("certificateType") in ["IOS_DISTRIBUTION", "DISTRIBUTION"]]
        if len(dist_certs) >= 2:
            print(f"Distribution certificate limit reached ({len(dist_certs)}). Revoking oldest certificate...")
            oldest_id = dist_certs[0].get("id")
            del_res = requests.delete(f"https://api.appstoreconnect.apple.com/v1/certificates/{oldest_id}", headers=api_headers)
            print(f"Revoked certificate {oldest_id}: status {del_res.status_code}")

        # Post new certificate request
        csr_clean = csr_pem.replace("-----BEGIN CERTIFICATE REQUEST-----", "").replace("-----END CERTIFICATE REQUEST-----", "").replace("\r", "").replace("\n", "").strip()
        cert_post_body = {
            "data": {
                "type": "certificates",
                "attributes": {
                    "certificateType": "IOS_DISTRIBUTION",
                    "csrContent": csr_clean
                }
            }
        }
        create_res = requests.post("https://api.appstoreconnect.apple.com/v1/certificates", headers=api_headers, json=cert_post_body)
        if create_res.status_code in [200, 201]:
            new_cert_data = create_res.json().get("data", {})
            matching_cert_id = new_cert_data.get("id")
            cert_content = new_cert_data.get("attributes", {}).get("certificateContent")
            cert_der_bytes = base64.b64decode(cert_content)
            print(f"Successfully created new Certificate {matching_cert_id} via API!")
        else:
            print(f"ERROR: Failed to create certificate via API: {create_res.status_code} {create_res.text}")

    # 4. Import P12 into Keychain
    home_dir = os.path.expanduser("~")
    prov_dir = os.path.join(home_dir, "Library", "MobileDevice", "Provisioning Profiles")
    os.makedirs(prov_dir, exist_ok=True)
    keychain_path = os.path.join(home_dir, "Library", "Keychains", "login.keychain-db")

    if cert_der_bytes:
        cer_path = "/tmp/final_cert.cer"
        pem_path = "/tmp/final_cert.pem"
        p12_path = "/tmp/final_cert.p12"
        with open(cer_path, "wb") as f:
            f.write(cert_der_bytes)
        subprocess.run(["openssl", "x509", "-in", cer_path, "-inform", "DER", "-out", pem_path], check=True)
        subprocess.run([
            "openssl", "pkcs12", "-export", "-out", p12_path,
            "-inkey", key_path, "-in", pem_path, "-passout", "pass:sobo123"
        ], check=True)
        print("Importing P12 bundle into Mac Keychain...")
        subprocess.run(["security", "import", p12_path, "-k", keychain_path, "-P", "sobo123", "-T", "/usr/bin/codesign"], check=False)
        subprocess.run(["security", "import", p12_path, "-P", "sobo123"], check=False)

    # 5. Query or Create Provisioning Profile for com.sobosociety.app
    print(f"Fetching provisioning profiles for {bundle_id_name}...")
    res_prof = requests.get("https://api.appstoreconnect.apple.com/v1/profiles?limit=50", headers=api_headers)
    profiles_data = res_prof.json().get("data", []) if res_prof.status_code == 200 else []

    saved_count = 0
    for prof in profiles_data:
        prof_name = prof.get("attributes", {}).get("name", "")
        prof_content = prof.get("attributes", {}).get("profileContent", "")
        prof_uuid = prof.get("attributes", {}).get("uuid", "")
        
        if prof_content:
            prof_bytes = base64.b64decode(prof_content)
            target_uuid_path = os.path.join(prov_dir, f"{prof_uuid}.mobileprovision")
            target_name_path = os.path.join(prov_dir, f"{prof_name}.mobileprovision")
            target_spec_path = os.path.join(prov_dir, "SoboSociety AppStore.mobileprovision")
            
            with open(target_uuid_path, "wb") as f:
                f.write(prof_bytes)
            with open(target_name_path, "wb") as f:
                f.write(prof_bytes)
            with open(target_spec_path, "wb") as f:
                f.write(prof_bytes)
                
            print(f"Saved Provisioning Profile '{prof_name}' ({prof_uuid}) to {prov_dir}")
            saved_count += 1

    print(f"=== Setup Signing Completed Successfully. Saved {saved_count} profiles. ===")

if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        traceback.print_exc()
        print(f"CRITICAL ERROR IN SIGNING SETUP: {exc}")
        sys.exit(1)
