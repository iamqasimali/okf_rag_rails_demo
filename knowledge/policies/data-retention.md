---
type: policy
title: Data Retention
description: Canonical retention windows for customer data and audit logs.
resource: "flowbase://policies/data-retention"
tags:
  - retention
  - data
  - privacy
  - compliance
  - policy
timestamp: "2026-07-07"
---

# Data Retention

Flowbase keeps deleted workspace data in recoverable backups for 30 days. After
30 days, backup snapshots are permanently rotated out of the recovery set.

Automation run logs are retained for 90 days on Starter, 180 days on Growth, and
365 days on Enterprise. Enterprise customers may request a shorter retention
period through their customer success manager.

Security incident investigations follow the [support escalation path](../support/escalation-path.md)
when a customer asks for urgent log preservation.
