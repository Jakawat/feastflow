-- ============================================
-- FEASTFLOW DATABASE SCHEMA
-- Restaurant Management System
-- ============================================

-- Drop existing tables if they exist
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS menu_items CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- ============================================
-- TABLE 1: Categories
-- Stores menu item categories
-- ============================================
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default categories
INSERT INTO categories (category_name) VALUES 
    ('Appetizers'),
    ('Main Dishes'),
    ('Drinks');

-- ============================================
-- TABLE 2: Menu Items
-- Stores all menu items available in the restaurant
-- ============================================
CREATE TABLE menu_items (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    category_id INTEGER NOT NULL,
    description TEXT,
    image_url TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

-- Insert sample menu items
INSERT INTO menu_items (item_name, price, category_id, description, image_url) VALUES
    ('Cheese Burger', 12.00, 2, 'Beef, cheddar, and brioche.', 'picture/burger.jpg'),
    ('French Fries', 5.00, 1, 'Sea salt and rosemary.', 'picture/fries.jpg'),
    ('Iced Cola', 2.50, 3, 'Chilled with lemon slice.', 'picture/cola.webp'),
    ('Orange Juice', 4.00, 3, '100% freshly squeezed.', 'picture/orange.jpg');

-- ============================================
-- TABLE 3: Orders
-- Stores order information for each table
-- ============================================
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    table_number INTEGER NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'New',
    order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (status IN ('New', 'In Progress', 'Fulfilled'))
);

-- ============================================
-- TABLE 4: Order Items
-- Stores individual items within each order
-- ============================================
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    item_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (quantity * item_price) STORED,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES menu_items(item_id) ON DELETE CASCADE
);

-- ============================================
-- INDEXES for better query performance
-- ============================================
CREATE INDEX idx_orders_table_number ON orders(table_number);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_menu_items_category ON menu_items(category_id);

-- ============================================
-- TRIGGER: Update timestamp on menu_items update
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_menu_items_updated_at
    BEFORE UPDATE ON menu_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE QUERIES (for testing and demonstration)
-- ============================================

-- Query 1: Get all menu items with category names
-- SELECT m.item_id, m.item_name, m.price, c.category_name, m.description, m.image_url
-- FROM menu_items m
-- JOIN categories c ON m.category_id = c.category_id
-- WHERE m.is_available = TRUE
-- ORDER BY c.category_name, m.item_name;

-- Query 2: Get all active orders with items
-- SELECT o.order_id, o.table_number, o.status, o.order_time,
--        oi.quantity, m.item_name, oi.item_price, oi.subtotal
-- FROM orders o
-- JOIN order_items oi ON o.order_id = oi.order_id
-- JOIN menu_items m ON oi.item_id = m.item_id
-- WHERE o.status != 'Fulfilled'
-- ORDER BY o.order_time DESC;

-- Query 3: Calculate total revenue
-- SELECT SUM(total_amount) as total_revenue
-- FROM orders
-- WHERE status = 'Fulfilled';

-- Query 4: Get orders for a specific table
-- SELECT o.order_id, o.status, o.total_amount, o.order_time,
--        json_agg(json_build_object(
--            'item_name', m.item_name,
--            'quantity', oi.quantity,
--            'price', oi.item_price
--        )) as items
-- FROM orders o
-- JOIN order_items oi ON o.order_id = oi.order_id
-- JOIN menu_items m ON oi.item_id = m.item_id
-- WHERE o.table_number = 1
-- GROUP BY o.order_id
-- ORDER BY o.order_time DESC;
