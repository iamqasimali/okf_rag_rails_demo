---
type: policy
title: Escalation Path
description: Required escalation routing for urgent or high-risk customer issues.
resource: "flowbase://support/escalation-path"
tags:
  - escalation
  - support
  - urgent
  - security
  - sla
timestamp: "2026-07-07"
---

# Escalation Path

Billing disputes over USD 500 must be escalated to Billing Operations within 4
business hours. Security or privacy incidents must be escalated to Security
Response immediately, with the customer told that a specialist will follow up.

Production outages affecting more than one customer workspace must be escalated
to Engineering On Call as P1. Single-workspace automation failures are P3 unless
they block payroll, healthcare operations, or a public-sector deadline.

Retention-related urgency should reference the [data retention policy](../policies/data-retention.md).
