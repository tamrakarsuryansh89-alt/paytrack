# PayTrack – Technical Design Document

**Project Name:** PayTrack – Invoicing and Collections Platform

**Client:** Meridian Supplies

**Team Client:** Event Ticketing Agency

**Release:** v1.0.0

**Phase:** Phase 1

**Date:** 14 November 2026

**Status:** Draft – Pending Mentor Review

---

## 1. Project Overview

PayTrack is a multi-tenant invoicing and collections platform developed using Java and Spring Boot.

The system allows distributors to manage business customers, create invoices, calculate GST, generate invoice PDFs and manage credit notes.

Each distributor is treated as a separate tenant. Users can access only the data belonging to their organisation.

The platform also supports customer advance deposits for the Event Ticketing Agency.

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
| Testing | JUnit 5, Mockito |
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

Tenant-based access restrictions will be enforced centrally.

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

### Intra-State Transaction

When the supplier and place of supply are in the same state:

- CGST = Half of the GST rate.
- SGST = Half of the GST rate.

Example:

Taxable Amount = ₹1,000

GST Rate = 18%

CGST = ₹90

SGST = ₹90

Total Tax = ₹180

### Inter-State Transaction

When the supplier and place of supply are in different states:

- IGST = Full GST rate.

Example:

Taxable Amount = ₹1,000

GST Rate = 18%

IGST = ₹180

### Rounding Rule

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

### Numbering Rules

1. No duplicate invoice numbers.
2. Numbers must be consecutive.
3. Each organisation maintains its own series.
4. Number allocation happens inside a database transaction.
5. Database locking will prevent concurrent requests from generating duplicate numbers.

A concurrency test will issue 20 invoices in parallel and verify 20 consecutive numbers.

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

### Business Rules

1. Customers can pay advance deposits.
2. Deposits are stored separately from invoice balances.
3. Deposits can be applied to future invoices.
4. The applied amount cannot exceed the available deposit.
5. Remaining deposits can be used for later invoices.
6. Every deposit application must be recorded.

### Example

Initial Deposit = ₹10,000

Invoice Amount = ₹7,000

Applied Deposit = ₹7,000

Remaining Deposit = ₹3,000

The remaining amount can be applied to a future invoice.

Deposit application will be transactional to prevent over-application.

## 11. Testing Strategy

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
10. PostgreSQL integration tests using Testcontainers.

The target service test coverage is 70%.

## 12. Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Tenant data leakage | Tenant isolation and automated tests |
| Duplicate invoice numbers | Database locking |
| Incorrect GST calculation | Tax calculation tests |
| Money rounding errors | BigDecimal and rounding rules |
| Deposit over-application | Transactional validation |
| Database migration errors | Flyway migrations |

## 13. Conclusion

PayTrack will provide a secure and reliable multi-tenant invoicing platform.

The proposed architecture, security rules, tax calculation, invoice numbering and client-specific advance deposit functionality will guide the Phase 1 implementation.

**Document Status: Draft – Pending Mentor Review.**