# Threat Model

## 0️⃣ Guiding Principle (non-negotiable)

> **This project exists to protect the user from human errors, not to create a perfect fortress.**

Everything else derives from this.

---

## 1️⃣ Assets to Protect

### 🎯 What we're protecting

- **API Keys** (LLM, messaging, OAuth)
- **Conversation history**
- **System host access** (shell, files)
- **User identity** (impersonation)

---

## 2️⃣ Real Threats Modeled

### 🧨 Primary threats

| Threat | Vector | Primary Mitigation |
|---|---|---|
| Shodan indexing | Panel exposed | Fail-Closed + Guardian |
| Auth bypass | Proxy misconfig | Circuit Breaker |
| Prompt injection → RCE | Agent + shell | Bulkhead + degradation |
| Secret theft | FS/env accessible | Secret isolation |
| Human error | "Just for a moment" | Automatic Guardian |

👉 **Priority threat:** _misconfiguration_, not "sophisticated hacker".

---

## 3️⃣ Attack Scenarios

### Scenario 1: Accidental Public Exposure

**What happens:**
- User binds control plane to `0.0.0.0` instead of `127.0.0.1`
- Nginx is accessible from public internet
- Shodan indexes the service

**How we mitigate:**
- Guardian detects public port binding
- Opens Circuit Breaker immediately
- Blocks all external access
- User sees clear error: "Public port detected, panel blocked"

**Result:** Incident not exploitable, user must explicitly fix configuration.

---

### Scenario 2: Authentication Bypass

**What happens:**
- User forgets to configure htpasswd or similar auth
- Control plane is accessible but not authenticated
- Anyone can access sensitive controls

**How we mitigate:**
- Circuit Breaker is in "Open" (blocked) state by default
- Requires explicit "close" command to enable
- Only allows traffic from allowlist (127.0.0.1) in Half-Open state
- Auth presence is part of Guardian's health check

**Result:** Panel cannot be accessed without explicit user action and auth verification.

---

### Scenario 3: Prompt Injection → RCE

**What happens:**
- Malicious input via chat interface
- LLM generates shell commands
- Commands execute on host system

**How we mitigate:**
- Bulkhead separates Control Plane from Runtime Bot
- Runtime Bot has no direct shell access
- Control Plane has restricted execution privileges
- Degradation shuts down Control Plane when risk detected

**Result:** Compromise is limited to a single compartment, host remains safe.

---

### Scenario 4: Secret Theft

**What happens:**
- Configuration file exposed via web UI or logs
- API keys, tokens, passwords accessible
- Attacker uses stolen credentials

**How we mitigate:**
- Secrets stored outside of container
- No secrets in environment variables
- Secrets not exposed in logs
- Guardian checks for secret leakage patterns

**Result:** Secrets remain isolated, even if configuration is exposed.

---

### Scenario 5: "Just for a Moment" Error

**What happens:**
- User opens panel for testing
- Forgets to close it or re-enable security
- Goes to dinner or weekend
- Panel remains exposed

**How we mitigate:**
- Guardian monitors continuously (every 30-60s)
- Detects exposure while user is away
- Auto-opens Circuit Breaker
- Panel becomes inaccessible regardless of user action

**Result:** Temporary mistake doesn't become permanent exposure.

---

## 4️⃣ Assumptions

### What we assume:

1. **macOS is secure enough**
   - We don't harden the host OS itself
   - We assume standard macOS security practices are followed

2. **User has local access**
   - We don't protect against local attackers (e.g., roommate with physical access)
   - We protect against remote exploitation

3. **Moltbot code is trusted**
   - We don't audit Moltbot's code for vulnerabilities
   - We focus on deployment and operational security

4. **User wants to cooperate**
   - We assume user is willing to follow security guidelines
   - We don't protect against malicious user intentionally exposing the system

### What we DON'T assume:

- User always configures correctly
- User will remember to re-enable security
- Local network is trusted
- Default configurations are safe

---

## 5️⃣ Threat Prioritization

### Priority 1: Critical (must prevent)

- Public internet exposure
- Auth bypass
- Secret exposure

### Priority 2: High (should prevent)

- Unintended shell execution
- Privilege escalation
- Data leakage

### Priority 3: Medium (nice to prevent)

- Information disclosure
- Denial of service (intentional)
- Resource exhaustion

### Out of scope:

- Local attacker (same machine)
- Malicious user (intentional exposure)
- Physical access to device
- Host OS vulnerabilities

---

## 6️⃣ Mitigation Effectiveness

| Threat | Circuit Breaker | Guardian | Bulkhead | Fail-Closed |
|---|---|---|---|---|
| Public exposure | P | P | - | P |
| Auth bypass | P | P | - | P |
| Prompt injection | S | - | P | - |
| Secret theft | S | P | P | P |
| Human error | P | P | - | P |

Legend:
- P = Primary mitigation
- S = Secondary mitigation
- - = Not applicable

---

## 7️⃣ Limitations

### What this threat model doesn't cover:

1. **Code-level vulnerabilities in Moltbot**
   - We protect deployment, not the application itself
   - If Moltbot has a bug, it's still exploitable (but limited)

2. **Advanced persistent threats (APT)**
   - We don't protect against sophisticated attackers targeting the user
   - Our focus is on preventing accidental exposure

3. **Supply chain attacks**
   - We don't verify dependencies or supply chain integrity
   - Users must practice good dependency management

4. **Post-exploitation**
   - If an attacker gains access, we don't detect or contain them
   - We prevent initial access, not lateral movement

---

## 8️⃣ Future Enhancements

### What we might add later:

1. **Comprehensive logging and monitoring**
   - Capture all access attempts
   - Alert on suspicious patterns
   - Export logs for external analysis

2. **Automated secret scanning**
   - Detect exposed secrets in real-time
   - Block requests containing sensitive data
   - Rotate compromised secrets automatically

3. **Multi-factor authentication**
   - Require second factor for sensitive operations
   - Integrate with common MFA providers
   - Support hardware tokens

4. **Network segmentation**
   - Separate control plane and runtime into different network namespaces
   - Implement network-level access controls
   - Support VPN integration out of the box
