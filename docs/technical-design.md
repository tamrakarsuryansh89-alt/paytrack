# PayTrack – Technical Design Document

**Project Name:** PayTrack – Invoicing and Collections Platform

**Client:** Meridian Supplies

**Team Client:** Event Ticketing Agency

**Release:** v1.0.0

**Phase:** Phase 1

**Date:** 14 November 2026

**Status:** Updated Draft – Pending Mentor Review

---

## 1. Project Overview

PayTrack is a multi-tenant invoicing and collections platform developed using Java and Spring Boot.

The system allows distributors to manage business customers, create invoices, calculate GST, generate invoice PDFs and manage credit notes.

Each distributor is treated as a separate tenant. Users can access only the data belonging to their organisation.

The platform also supports customer advance deposits for the Event Ticketing Agency as a client-specific requirement.

## 2. Technology Stack

| Component | Technology |
|---|---|
| Programming Language | Java 21 |
| Backend | Spring Boot 3 |
| Security | Spring Security |
| Database | PostgreSQL |
| ORM | Spring Data JPA |
| Migration | Flyway |
| Cache | Redis |
| Messaging | RabbitMQ |
| Frontend | React 18, TypeScript |
| Testing | JUnit 5, Mockito, Testcontainers |
| Deployment | Docker, GitHub Actions, Render |

## 3. System Architecture

The application follows a layered architecture.

1. Controller Layer – Handles HTTP requests.
2. Service Layer – Contains business logic.
3. Repository Layer – Communicates with the database.
4. Database Layer – Stores application data.

### Architecture Flow

React Frontend

↓

Spring Boot REST API

↓

Spring Security

↓

Controller Layer

↓

Service Layer

↓

Repository Layer

↓

PostgreSQL Database

Redis will be used for caching and rate limiting. RabbitMQ will handle asynchronous processing.

## 4. Database Design

The main database entities are:

| Entity | Description |
|---|---|
| Organisation | Stores distributor information |
| User | Stores user details and roles |
| Customer | Stores customer information |
| Invoice | Stores invoice details |
| InvoiceItem | Stores invoice line items |
| CreditNote | Stores invoice corrections |
| InvoiceNumberSeries | Manages invoice numbering |
| Deposit | Stores customer advance deposits |
| DepositApplication | Tracks deposit applications |

Every tenant-owned financial record will contain an organisation ID.

### 4.1 Tenant Isolation and Security

Tenant isolation will be enforced centrally using Spring Security and service-layer validation.

The following approach will be implemented:

1. Every user will be associated with an organisation.
2. After successful authentication, the system will identify the authenticated user using the JWT token.
3. The organisation ID will be obtained from the authenticated user's database record.
4. The organisation ID will be stored in the authenticated security context.
5. The frontend will not be trusted to provide the organisation ID for authorization.
6. Every tenant-owned database query will include the authenticated user's organisation ID.
7. Repository and service-layer checks will ensure that users can access only records belonging to their organisation.
8. Cross-tenant access attempts will be rejected with an appropriate HTTP 403 response.

### 4.2 Tenant Isolation Testing

Automated integration tests will verify that:

- Organisation A users can access their own invoices.
- Organisation B users can access their own invoices.
- Organisation A users cannot read Organisation B invoices.
- Users cannot modify or delete another organisation's records.

This will ensure that one distributor cannot access another distributor's financial data.

## 5. API Design

All REST APIs will use the `/api/v1` prefix.

| Method | Endpoint | Description |
|---|---|---|
| POST | /api/v1/customers | Create customer |
| GET | /api/v1/customers | Get customers |
| POST | /api/v1/invoices | Create invoice |
| GET | /api/v1/invoices | Get invoices |
| POST | /api/v1/invoices/{id}/issue | Issue invoice |
| POST | /api/v1/customers/{id}/deposits | Create deposit |
| GET | /api/v1/customers/{id}/deposits | View deposits |
| POST | /api/v1/invoices/{id}/apply-deposit | Apply deposit |

All API requests will be validated using Bean Validation.

## 6. Permission Matrix

The application supports five roles:

- Owner
- Finance Manager
- Accountant
- Collector
- Read-only

| Action | Owner | Finance Manager | Accountant | Collector | Read-only |
|---|---|---|---|---|---|
| View invoices | Yes | Yes | Yes | Yes | Yes |
| Create invoices | Yes | Yes | Yes | No | No |
| Issue invoices | Yes | Yes | Yes | No | No |
| Manage customers | Yes | Yes | Yes | No | No |
| Create credit notes | Yes | Yes | Yes | No | No |
| View deposits | Yes | Yes | Yes | Yes | Yes |
| Apply deposits | Yes | Yes | Yes | No | No |
| Manage users | Yes | No | No | No | No |

**Note:** This is a proposed permission matrix and requires mentor approval.

## 7. GST Tax Calculation

GST will be calculated separately for each invoice line item.

### 7.1 Intra-State Transaction

When the supplier and place of supply are in the same state:

- CGST = Half of the GST rate.
- SGST = Half of the GST rate.

Example:

Taxable Amount = ₹1,000

GST Rate = 18%

CGST = ₹90

SGST = ₹90

Total Tax = ₹180

### 7.2 Inter-State Transaction

When the supplier and place of supply are in different states:

- IGST = Full GST rate.

Example:

Taxable Amount = ₹1,000

GST Rate = 18%

IGST = ₹180

### 7.3 Rounding Rule

- Use BigDecimal for monetary calculations.
- Round each line's tax amount to two decimal places.
- Use RoundingMode.HALF_UP.
- Calculate invoice totals using rounded line amounts.

The rounding rule requires mentor approval.

## 8. Invoice Numbering

Invoice numbers will follow a configurable series for each organisation and financial year.

Example:

- INV/2026-27/001
- INV/2026-27/002
- INV/2026-27/003

### 8.1 Numbering Rules

1. No duplicate invoice numbers.
2. Numbers must be consecutive.
3. Each organisation maintains its own series.
4. Number allocation happens inside a database transaction.
5. Database locking will prevent concurrent requests from generating duplicate numbers.

### 8.2 Concurrency and Rollback Handling

To maintain consecutive invoice numbers and prevent duplicate allocation, the following approach will be implemented:

1. The InvoiceNumberSeries table will maintain the next available invoice number for each organisation and financial year.
2. During invoice issuance, the corresponding InvoiceNumberSeries row will be locked using PostgreSQL `SELECT FOR UPDATE`.
3. Only one transaction at a time can allocate a number from the same organisation's series.
4. The invoice number will be allocated and the series counter will be updated within the same database transaction.
5. Invoice creation and number allocation will be committed together.
6. If the transaction fails or rolls back, the counter update will also be rolled back.
7. A unique database constraint on organisation ID, financial year and invoice number will prevent duplicate invoice numbers.
8. Different organisations can generate invoice numbers independently.

Issued invoice numbers will never be reused. If an issued invoice is voided, its number will remain recorded.

This approach will prevent numbering gaps caused by failed transactions and duplicate numbers during concurrent requests.

### 8.3 Concurrency Testing

A concurrency integration test using PostgreSQL Testcontainers will issue 20 invoices in parallel.

Expected result:

- 20 invoices successfully issued.
- 20 unique invoice numbers.
- 20 consecutive invoice numbers.
- No duplicate numbers.

## 9. Invoice Lifecycle

Invoice statuses:

- Draft
- Issued
- Partially Paid
- Paid
- Void

An issued invoice cannot be modified. Corrections will be made using a linked credit note.

## 10. Client-Specific Requirement – Advance Deposit

The Event Ticketing Agency requires advance deposits to be maintained as separate customer balances.

### 10.1 Business Rules

1. Customers can pay advance deposits.
2. Deposits are stored separately from invoice balances.
3. Deposits can be applied to future invoices.
4. The applied amount cannot exceed the available deposit.
5. Remaining deposits can be used for later invoices.
6. Every deposit application must be recorded.
7. Deposit application will be transactional to prevent over-application.

### 10.2 Example

Initial Deposit = ₹10,000

Invoice Amount = ₹7,000

Applied Deposit = ₹7,000

Remaining Deposit = ₹3,000

The remaining amount can be applied to a future invoice.

### 10.3 Deposit Refunds and Reversals

The following rules will handle refunds, reversals and duplicate deposit applications:

1. Refunds will be allowed only against the available, unallocated deposit balance.
2. A customer cannot receive a refund greater than the available deposit balance.
3. Every refund will be recorded as a separate financial transaction.
4. Deposit application reversals will be recorded separately to maintain transaction history.
5. Existing deposit and application records will not be permanently deleted.
6. Reversed applications will restore the corresponding amount to the available deposit balance.
7. Unique transaction references or idempotency keys will prevent duplicate deposit applications and duplicate refund processing.
8. A deposit cannot be applied for more than its available balance.
9. Deposit application, reversal and invoice balance updates will happen within a single database transaction.
10. Database row-level locking will prevent concurrent requests from applying the same deposit balance more than once.

These rules will maintain accurate customer deposit balances and provide a clear financial transaction history.

## 11. Client Relationship Clarification

The project requirements identify Meridian Supplies as the primary distributor client.

The Team Workspace identifies Event Ticketing Agency as the team-assigned client-specific scenario.

The Event Ticketing Agency has an additional business requirement involving customer advance deposits.

The exact relationship between Meridian Supplies and Event Ticketing Agency, including whether they represent separate tenants or a distributor-customer relationship, requires mentor confirmation.

The tenant and customer mapping will be finalized after this clarification to ensure that the implementation follows the correct business model.

## 12. Testing Strategy

The following tests will be implemented:

1. User authentication tests.
2. Role-based permission tests.
3. Tenant isolation tests.
4. Customer validation tests.
5. GST calculation tests.
6. Invoice numbering concurrency tests.
7. Invoice lifecycle tests.
8. Credit note tests.
9. Advance deposit tests.
10. Deposit refund and reversal tests.
11. Duplicate deposit application tests.
12. PostgreSQL integration tests using Testcontainers.

The target service test coverage is 70%.

## 13. Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Tenant data leakage | Tenant isolation and automated tests |
| Duplicate invoice numbers | Database locking and unique constraints |
| Invoice numbering gaps | Transactional number allocation |
| Incorrect GST calculation | Tax calculation tests |
| Money rounding errors | BigDecimal and rounding rules |
| Deposit over-application | Transactional validation and row locking |
| Duplicate deposit transactions | Unique transaction references |
| Database migration errors | Flyway migrations |
| Concurrent deposit applications | Database locking and transactional processing |

## 14. Conclusion

PayTrack will provide a secure and reliable multi-tenant invoicing platform.

The proposed architecture, tenant-level security, tax calculation, invoice numbering and client-specific advance deposit functionality will guide the Phase 1 implementation.

The additional security, concurrency and financial transaction rules will help maintain data integrity and prevent incorrect financial operations.

**Document Status: Updated Draft – Pending Mentor Review.**