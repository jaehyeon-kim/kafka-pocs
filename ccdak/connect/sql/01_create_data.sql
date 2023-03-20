CREATE TABLE purchases (
  product_id      SERIAL PRIMARY KEY,
  product         VARCHAR(100) NOT NULL,
  quantity        SMALLINT NOT NULL,
  purchase_time   TIMESTAMP NOT NULL,
  updated_ts      TIMESTAMP NOT NULL
);

INSERT INTO purchases (product, quantity, purchase_time, updated_ts) 
  VALUES 
    ('plums', 8, current_timestamp, current_timestamp),
    ('apples', 10, current_timestamp, current_timestamp),
    ('pears', 7, current_timestamp, current_timestamp);
