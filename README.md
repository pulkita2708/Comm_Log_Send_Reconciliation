# Comm-Log Send Reconciliation

## 📌 Project Overview

- Reconciled Finance's expected `target_base = 22` for **Merchant 501** for **October 2026**.
- Used **MySQL** to analyze campaign and communication-log data.
- Started with a naive communication-log count of **30 records**.
- Investigated the discrepancy between the raw count and Finance's expected value.
- Identified campaign eligibility and retry relationships as the key reasons for the difference.
- Built SQL logic to reproduce the final Finance target without hard-coding the answer.

---

## 🎯 Business Objective

- Determine the correct number of qualifying communication events/customers for:
  - **Merchant:** 501
  - **Period:** October 2026
  - **Communication Type:** Campaign (`communication_type = '2'`)
- Reconcile the raw communication-log count with Finance's expected `target_base` of **22**.

---

## 📂 Dataset

### Campaign Table
- Contains campaign-level information.
- Important columns:
  - `id`
  - `merchant_id`
  - `parent_id`
  - `name`
  - `creation_status`
  - `processing_status`

### Communication Log Table
- Contains individual communication/send records.
- Important columns:
  - `id`
  - `merchant_id`
  - `communication_id`
  - `customer_id`
  - `communication_type`
  - `delivery_status`
  - `sent_time`

---

## 🔍 Investigation Approach

- Calculated the initial **naive count = 30** using the communication log.
- Joined `communication_log` with `campaign` to validate campaign eligibility.
- Identified campaign `9004` as `approval_awaiting`.
- Found **4 communication records** associated with campaign `9004`.
- Excluded those records because the campaign had not completed the required creation/approval workflow.
- Final eligible records after status filtering = **26**.
- Investigated `parent_id` relationships to identify retry campaigns.
- Identified two retry families:
  - `9001 → 9002 → 9003`
  - `9201 → 9202`
- Identified `9101` as a standalone campaign.

---

## 🔄 Retry Handling

### Retry Family: 9001 → 9002 → 9003

- Raw communication attempts = **13**
- Unique customers = **10**
- Since these campaigns represent retries of the same underlying communication, customers were counted only once.
- Adjustment = **-3**

### Standalone Campaign: 9101

- Communication events = **7**
- Repeated customer records were retained.
- Since the campaign is standalone, each send is treated as a separate event.
- Adjustment = **0**

### Retry Family: 9201 → 9202

- Raw communication attempts = **6**
- Unique customers = **5**
- Retry attempts were deduplicated at the customer level.
- Adjustment = **-1**

---

## 📊 Reconciliation Bridge

| Step | Description | Count |
|------|-------------|------:|
| 1 | Naive October communication-log count | 30 |
| 2 | Exclude `9004` (`approval_awaiting`) | -4 |
| 3 | Deduplicate retry family `9001 → 9002 → 9003` | -3 |
| 4 | Retain standalone campaign `9101` events | 0 |
| 5 | Deduplicate retry family `9201 → 9202` | -1 |
| | **Final Target Base** | **22** |

### Final Calculation

```text
30 - 4 - 3 + 0 - 1 = 22
