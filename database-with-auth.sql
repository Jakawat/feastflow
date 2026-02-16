-- ============================================
-- FEASTFLOW DATABASE SCHEMA WITH AUTHENTICATION
-- Restaurant Management System
-- ============================================

-- Drop existing tables if they exist
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS menu_items CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================
-- TABLE 1: Users (Authentication)
-- Stores user login credentials
-- ============================================
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'kitchen')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default users (password for both is: password123)
-- In production, these should be hashed!
INSERT INTO users (username, password, role) VALUES 
    ('admin', '$2a$10$rX5X8z8vY.5yY5.yY5.yY.OqKqKqKqKqKqKqKqKqKqKqKqKqKqKq', 'admin'),
    ('kitchen', '$2a$10$rX5X8z8vY.5yY5.yY5.yY.OqKqKqKqKqKqKqKqKqKqKqKqKqKqKq', 'kitchen');

-- For now, let's use plain text for easier testing (CHANGE LATER!)
UPDATE users SET password = 'admin123' WHERE username = 'admin';
UPDATE users SET password = 'kitchen123' WHERE username = 'kitchen';

-- ============================================
-- TABLE 2: Categories
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
-- TABLE 3: Menu Items
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
-- TABLE 4: Orders
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
-- TABLE 5: Order Items
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
CREATE INDEX idx_users_username ON users(username);

-- ============================================
-- TRIGGERS AND FUNCTIONS
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
-- DEFAULT CREDENTIALS (FOR TESTING)
-- ============================================
-- Username: admin    | Password: admin123    | Role: Admin
-- Username: kitchen  | Password: kitchen123  | Role: Kitchen Staff
-- 
-- NOTE: In production, use hashed passwords!
-- ============================================
