# Security policy

This is a pre-release source implementation with no completed native build/device audit. No supported release/security-response SLA is claimed yet. Use only public Apple APIs. Keyboard text must never enter logs, analytics, files or network requests.

If a GitHub repository is published with private vulnerability reporting enabled, use its **Security → Report a vulnerability** workflow. Until a verified private contact exists, avoid posting typed text, secrets, proof containing personal input, or exploitable details in public issues. Use a sanitized public issue only to request a private reporting channel if needed. This repository supplies no invented maintainer address.

Reports should describe the affected commit/OS, reproducible steps, sandbox/Full Access state, minimal sanitized input and expected versus actual behavior. Important areas include theme validation, unexpected filesystem access, persistence races, data disclosure, network access and keyboard lifecycle failures. Never attach signing keys or provisioning credentials.

Before public release, establish a private reporting contact, enable private GitHub advisories, complete the device/privacy checklist and publish supported versions and response expectations.
