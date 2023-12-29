CREATE DATABASE $(MSSQL_DB);
GO
USE $(MSSQL_DB);
GO
CREATE LOGIN $(MSSQL_USER) WITH PASSWORD = '$(MSSQL_PASSWORD)';
GO
CREATE USER $(MSSQL_USER) FOR LOGIN $(MSSQL_USER);
GO
ALTER SERVER ROLE sysadmin ADD MEMBER [$(MSSQL_USER)];
GO

CREATE schema example;
GO

CREATE TABLE example.product
(
    id                      BIGINT IDENTITY (1, 1),
    name                    VARCHAR(255) NOT NULL,

    CONSTRAINT pk_product PRIMARY KEY (id)
);

CREATE TABLE example.cart
(
    id                      BIGINT IDENTITY (1, 1),
    product_id              BIGINT NOT NULL,
    quantity                INT NOT NULL DEFAULT 1,

    CONSTRAINT pk_cart PRIMARY KEY (id),
    CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES example.product (id) ON DELETE NO ACTION,
    CONSTRAINT unique_product UNIQUE (product_id)
);
GO

CREATE VIEW example.cart_product AS
    SELECT p.id as product_id, p.name as product_name, c.quantity
    FROM example.cart c JOIN example.product p on c.product_id = p.id;
GO

INSERT INTO example.product (name) VALUES ('Xbox Series X 1TB SSD Console');
INSERT INTO example.product (name) VALUES ('Samsung Galaxy Watch 5 Pro 45mm R920N');
INSERT INTO example.product (name) VALUES ('JBL Tune 510BT Wireless Bluetooth On-ear Headphones');
INSERT INTO example.product (name) VALUES ('4-Tier Metal Wire Shelf Rack');
INSERT INTO example.product (name) VALUES ('Feather & Down Blend Bed Pillows');
GO
