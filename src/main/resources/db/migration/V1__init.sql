
-- PayTrack Database Initialization

-- 1. Organisations Table
CREATE TABLE organisations (
                               organisation_id BIGSERIAL PRIMARY KEY,
                               name VARCHAR(150) NOT NULL,
                               created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Users Table
CREATE TABLE users (
                       id BIGSERIAL PRIMARY KEY,
                       organisation_id BIGINT NOT NULL,
                       name VARCHAR(100) NOT NULL,
                       email VARCHAR(150) UNIQUE NOT NULL,
                       password VARCHAR(255) NOT NULL,
                       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                       CONSTRAINT fk_users_organisation
                           FOREIGN KEY (organisation_id)
                               REFERENCES organisations(organisation_id)
);

-- 3. Customers Table
CREATE TABLE customers (
                           id BIGSERIAL PRIMARY KEY,
                           organisation_id BIGINT NOT NULL,
                           name VARCHAR(150) NOT NULL,
                           email VARCHAR(150),
                           phone VARCHAR(20),
                           address TEXT,
                           created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                           CONSTRAINT uq_customer_org UNIQUE (id, organisation_id),

                           CONSTRAINT fk_customers_organisation
                               FOREIGN KEY (organisation_id)
                                   REFERENCES organisations(organisation_id)
);

-- 4. Invoices Table
CREATE TABLE invoices (
                          id BIGSERIAL PRIMARY KEY,
                          organisation_id BIGINT NOT NULL,
                          customer_id BIGINT NOT NULL,
                          invoice_number VARCHAR(50) UNIQUE NOT NULL,
                          invoice_date DATE NOT NULL,
                          due_date DATE NOT NULL,
                          total_amount DECIMAL(12,2) NOT NULL,
                          status VARCHAR(20) DEFAULT 'PENDING',
                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                          CONSTRAINT fk_invoice_organisation
                              FOREIGN KEY (organisation_id)
                                  REFERENCES organisations(organisation_id),

                          CONSTRAINT fk_invoice_customer
                              FOREIGN KEY (customer_id, organisation_id)
                                  REFERENCES customers(id, organisation_id)
);
