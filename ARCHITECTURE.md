# Architecture

## 🎯 Project Goal

Create an **open-source starter** for running Moltbot on macOS in a way that is:

- **Secure by default**
- **Fail-closed**
- **Resistant to configuration errors**
- **Understandable and auditable**

> "We don't aim to make Moltbot 'impossible to attack', but to prevent human misconfiguration from exposing it publicly."

---

## 🧩 Root Problem

- Moltbot is an **agent with system access**
- The **control plane** (admin panel) has been:
  - Exposed without authentication
  - Indexable by Shodan
  - Vulnerable to RCE and secret theft
- The main failure was **not the code**, but:
  - Architecture
  - Insecure defaults
  - Lack of "guardrails"

👉 This is an **architectural problem**, not just a security issue.

---

## 🏛️ Approach: Patterns first, tooling second

Before Docker, Nginx, or VPN, we define **patterns** that guide everything.

---

## 1️⃣ Main Pattern: Circuit Breaker (Control Plane)

### What we protect

- The **control panel / gateway** of Moltbot
  (not the bot's core runtime)

### What we consider a "failure"

- Public network exposure
- Access without authentication
- Suspicious requests
- Incomplete configuration (proxy without auth, incorrect bind)

### Key decision

👉 **When in doubt → block access**

### Defined states

- **Closed (normal)**
  - Local/VPN access only
  - Auth active
  - Allowlist active

- **Open (blocked)**
  - Admin panel inaccessible
  - No external traffic accepted
  - System in safe mode

- **Half-open (controlled recovery)**
  - Configuration review
  - Local testing only

💡 Important:
The breaker **does not protect the attacker**, it protects the user from themselves.

---

## 2️⃣ Complementary Pattern: Fail-Closed by Default

### Master rule of the project

> _If something is not explicitly allowed, it is blocked._

Applications:

- Ports: closed by default
- Network: loopback/VPN only
- Auth: mandatory
- Shell/exec: disabled or restricted
- Secrets: inaccessible by default

This pattern explains **why** we make "uncomfortable" (but secure) decisions.

---

## 3️⃣ Pattern: Bulkhead (Compartmentation)

Separate responsibilities so a failure doesn't collapse everything.

### Clear compartments

1. **Control Plane**
  - Admin panel
  - Configuration
  - Sensitive actions

2. **Bot Runtime**
  - Processing
  - Allowed automations
  - No direct access to critical secrets

3. **Host System (macOS)**
  - Never directly exposed
  - No `$HOME` sharing
  - Separate user recommended

👉 If the control plane fails, **the host doesn't fail**.

---

## 4️⃣ Pattern: Zero Trust Local

Even though everything runs "on your Mac":

- Don't trust:
  - localhost
  - internal network
  - sibling containers

Every request to the control plane must:
  - Authenticate
  - Authorize
  - Be limited

This avoids the classic:

> "It doesn't matter, it's local..."

---

## 5️⃣ Pattern: Exposure Health Check (Guardian Pattern)

This is key and born directly from the real incident.

### Idea

An **external observer** to the system that verifies:

- What is actually exposed
- How it's bound
- Whether the breaker should open

### What it observes

- Published ports
- Network interfaces
- HTML fingerprint
- Whether auth is present

### What it does when risk is detected

- **Opens the circuit**
- Blocks the panel
- Notifies (in the future)

This pattern **does not depend on Moltbot's code**.
It's an external safety net.

---

## 6️⃣ Pattern: Safe Degradation (Safe Fallback)

When something goes wrong:

❌ NO:

- "Let's leave it open while I fix it"

✅ YES:

- Panel OFF
- Minimal functionality
- No sensitive execution

The experience is:

> "I can't access the admin"
> not
> "All my keys were stolen".

---

## 🗺️ Conceptual Architecture (without technology)

```
[ User ]     |
             | (Auth + Rate limit)
             v
[ Circuit Breaker ]     |
             | Closed → OK
             | Open   → BLOCK
             v
[ Control Plane ]     |
             | (allowed actions)
             v
[ Runtime Bot ] —— [ Bulkhead ] —— [ Host macOS ]
```

---

## 🧪 Risks this design explicitly mitigates

- Accidental Internet exposure
- Shodan indexing
- Auth bypass
- Prompt injection → RCE
- Massive secret theft
- "I left it like this for a while and forgot"

---

## 📋 Implementation plan (no code)

### Phase 0 — Design (now)

- Define patterns ✔️
- Agree on principles ✔️
- Document threat model ✔️

### Phase 1 — Circuit Breaker manual

- Breaker at the edge (proxy)
- Fail-closed
- Mandatory auth

### Phase 2 — Exposure Guardian

- Exposure checks
- Automatic breaker opening

### Phase 3 — Degradation + UX

- What the user sees when blocked
- Clear messages
- Controlled recovery

### Phase 4 — Open source polish

- Docs
- SECURITY.md
- Visible threat model
- "Why this is strict" explained

---

## 🧠 Expected project outcome

A repo that implicitly says:

> "If you use Moltbot and make a mistake, **you won't get burned**."

And explicitly:

> "This project prioritizes **not exposing you** over convenience."
