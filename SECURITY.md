# Security Policy

## Supported Versions

Only the latest version of METALlama.cpp is currently supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 2.8.x   | :white_check_mark: |
| < 2.8   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in METALlama.cpp, please follow these steps:

1. **Do not disclose the vulnerability publicly**
2. **Open a security advisory** in the GitHub repository Security tab
3. **Include the following information**:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact
   - Suggestions for addressing the vulnerability (if any)

## What to Expect

- A confirmation of your report within 48 hours
- An assessment of the vulnerability within 7 days
- Regular updates on progress towards a fix
- Credit for responsibly disclosing the issue (unless you prefer to remain anonymous)

## Security Considerations

METALlama.cpp by default runs a server that is accessible on your local network (0.0.0.0). If security is a concern:

1. Edit the server configuration to bind only to localhost (127.0.0.1)
2. Use your operating system's firewall to restrict access
3. Do not expose the server to the public internet
4. Be cautious about what model files you download and run

Thank you for helping to keep METALlama.cpp secure.