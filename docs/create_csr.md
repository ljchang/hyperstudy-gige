# Creating a Certificate Signing Request (CSR)

## Steps:

1. **Open Keychain Access**
   - Press `Cmd + Space` and search for "Keychain Access"
   - Or go to Applications → Utilities → Keychain Access

2. **Create CSR**
   - In Keychain Access menu bar: **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority...**

3. **Fill in the information:**
   - **User Email Address**: Your Apple ID email
   - **Common Name**: cosanlab
   - **CA Email Address**: Leave blank
   - **Request is**: Select "Saved to disk"
   - **Let me specify key pair information**: Check this box

4. **Click Continue**

5. **Save the CSR file**
   - Save as: CertificateSigningRequest.certSigningRequest
   - Save to: Desktop (or wherever you prefer)

6. **Key Pair Information**
   - **Key Size**: 2048 bits
   - **Algorithm**: RSA
   - Click Continue

7. **Click Done**

## After Creating CSR:

1. Go back to Apple Developer portal
2. Continue with certificate creation
3. Upload the CSR file you just created
4. Download the certificate
5. Double-click to install in Keychain

## Verify Installation:
```bash
security find-identity -p codesigning -v
```

This will show your new "cosanlab" certificate once installed.