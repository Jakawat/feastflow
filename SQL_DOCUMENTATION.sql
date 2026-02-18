-- ============================================
-- SECTION 1: DATABASE CREATION
-- ============================================

-- Command 1.1: Create database
CREATE DATABASE feastflow_db;

-- ============================================
-- SECTION 2: TABLE CREATION
-- ============================================

-- Command 2.1: Create Categories Table
-- Purpose: Store menu item categories (Appetizers, Main Dishes, Drinks)
-- Related UI: Admin - Add Menu Item (Category dropdown)
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Command 2.2: Create Menu Items Table
-- Purpose: Store all menu items with prices and descriptions
-- Related UI: Customer - Menu Display, Admin - Menu Management
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

-- Command 2.3: Create Orders Table
-- Purpose: Store order headers with table number and status
-- Related UI: Customer - Order History, Kitchen - Order Queue, Admin - Sales Dashboard
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    table_number INTEGER NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'New',
    order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (status IN ('New', 'In Progress', 'Fulfilled'))
);

-- Command 2.4: Create Order Items Table
-- Purpose: Store individual items within each order
-- Related UI: Customer - Order Summary, Kitchen - Order Details
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
-- SECTION 3: INDEXES FOR PERFORMANCE
-- ============================================

-- Command 3.1: Index on table_number for faster table-specific queries
-- Related UI: Customer - View orders for specific table
CREATE INDEX idx_orders_table_number ON orders(table_number);

-- Command 3.2: Index on order status for kitchen filtering
-- Related UI: Kitchen - Show only active orders
CREATE INDEX idx_orders_status ON orders(status);

-- Command 3.3: Index on order_id in order_items for joins
-- Related UI: All views that display order details
CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- Command 3.4: Index on category for menu filtering
-- Related UI: Customer - Filter menu by category
CREATE INDEX idx_menu_items_category ON menu_items(category_id);

-- ============================================
-- SECTION 4: TRIGGERS AND FUNCTIONS
-- ============================================

-- Command 4.1: Create function to auto-update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Command 4.2: Trigger for menu_items updates
-- Purpose: Automatically update timestamp when menu item is modified
-- Related UI: Admin - Edit menu item
CREATE TRIGGER update_menu_items_updated_at
    BEFORE UPDATE ON menu_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Command 4.3: Trigger for orders updates
-- Purpose: Automatically update timestamp when order status changes
-- Related UI: Kitchen - Update order status
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SECTION 5: SAMPLE DATA INSERTION
-- ============================================

-- Command 5.1: Insert categories
-- Related UI: All menu displays
INSERT INTO categories (category_name) VALUES 
    ('Appetizers'),
    ('Main Dishes'),
    ('Drinks');

-- Command 5.2: Insert sample menu items
-- Related UI: Customer - Initial menu display
INSERT INTO menu_items (item_name, price, category_id, description, image_url) VALUES
    ('Cheese Burger', 12.00, 2, 'Beef, cheddar, and brioche.', 'picture/burger.jpg'),
    ('French Fries', 5.00, 1, 'Sea salt and rosemary.', 'picture/fries.jpg'),
    ('Iced Cola', 2.50, 3, 'Chilled with lemon slice.', 'picture/cola.webp'),
    ('Orange Juice', 4.00, 3, '100% freshly squeezed.', 'picture/orange.jpg');

-- ============================================
-- SECTION 6: CUSTOMER SIDE QUERIES
-- ============================================

-- Query 6.1: Get all menu items with categories
-- Related UI: Customer - View Menu (http://localhost:5173/)
-- Purpose: Display all available menu items grouped by category
SELECT 
    m.item_id, 
    m.item_name, 
    m.price, 
    c.category_name,
    m.description,
    m.image_url
FROM menu_items m
JOIN categories c ON m.category_id = c.category_id
WHERE m.is_available = TRUE
ORDER BY c.category_name, m.item_name;

-- Query 6.2: Create new order
-- Related UI: Customer - Confirm Order button
-- Step 1: Insert order header
INSERT INTO orders (table_number, total_amount, status) 
VALUES (1, 19.50, 'New') 
RETURNING order_id;

-- Step 2: Insert order items (example for order_id = 1)
INSERT INTO order_items (order_id, item_id, quantity, item_price) 
VALUES 
    (1, 1, 1, 12.00),  -- 1x Cheese Burger
    (1, 3, 3, 2.50);   -- 3x Iced Cola

-- Query 6.3: Get orders for specific table
-- Related UI: Customer - Order Tracker
-- Purpose: Show order history for current table
SELECT 
    o.order_id,
    CONCAT('Table ', o.table_number) as table_id,
    o.total_amount,
    o.status,
    TO_CHAR(o.order_time, 'HH24:MI:SS') as order_time,
    json_agg(
        json_build_object(
            'item_name', m.item_name,
            'quantity', oi.quantity,
            'price', oi.item_price
        )
    ) as items
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN menu_items m ON oi.item_id = m.item_id
WHERE o.table_number = 1
GROUP BY o.order_id
ORDER BY o.order_time DESC;

-- Query 6.4: Add items to existing order
-- Related UI: Customer - Place another order from same table
-- Purpose: Update existing unfulfilled order instead of creating new one
UPDATE orders 
SET total_amount = total_amount + 12.00, 
    status = 'New',
    updated_at = CURRENT_TIMESTAMP
WHERE table_number = 1 
  AND status != 'Fulfilled';

-- ============================================
-- SECTION 7: KITCHEN SIDE QUERIES
-- ============================================

-- Query 7.1: Get all active orders (not fulfilled)
-- Related UI: Kitchen - Order Queue (http://localhost:5173/#/kitchen)
-- Purpose: Display all orders that need to be prepared
SELECT 
    o.order_id,
    CONCAT('Table ', o.table_number) as table_id,
    o.table_number,
    o.total_amount,
    o.status,
    TO_CHAR(o.order_time, 'HH24:MI:SS') as time,
    json_agg(
        json_build_object(
            'item_name', m.item_name,
            'quantity', oi.quantity,
            'price', oi.item_price
        )
    ) as items
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN menu_items m ON oi.item_id = m.item_id
WHERE o.status != 'Fulfilled'
GROUP BY o.order_id, o.table_number, o.total_amount, o.status, o.order_time
ORDER BY o.order_time ASC;

-- Query 7.2: Update order status to "In Progress"
-- Related UI: Kitchen - "Start Preparation" button
-- Purpose: Mark order as being prepared
UPDATE orders 
SET status = 'In Progress', 
    updated_at = CURRENT_TIMESTAMP
WHERE order_id = 1;

-- Query 7.3: Update order status to "Fulfilled"
-- Related UI: Kitchen - "Ready for Pickup" button
-- Purpose: Mark order as completed
UPDATE orders 
SET status = 'Fulfilled', 
    updated_at = CURRENT_TIMESTAMP
WHERE order_id = 1;

-- Query 7.4: Get order details for specific order
-- Related UI: Kitchen - Order card details
-- Purpose: Show all items in a specific order
SELECT 
    oi.quantity,
    m.item_name,
    oi.item_price,
    oi.subtotal
FROM order_items oi
JOIN menu_items m ON oi.item_id = m.item_id
WHERE oi.order_id = 1
ORDER BY m.item_name;

-- ============================================
-- SECTION 8: ADMIN SIDE QUERIES
-- ============================================

-- Query 8.1: Get all menu items for management
-- Related UI: Admin - Menu List (http://localhost:5173/#/admin)
-- Purpose: Display all menu items with ability to delete
SELECT 
    item_id,
    item_name,
    price,
    image_url
FROM menu_items
ORDER BY item_name;

-- Query 8.2: Add new menu item
-- Related UI: Admin - "Add New Item" form
-- Purpose: Add new item to menu
INSERT INTO menu_items (item_name, price, category_id, description, image_url)
VALUES ('Grilled Chicken', 15.00, 2, 'Herb-marinated chicken breast', 'picture/chicken.jpg')
RETURNING item_id, item_name, price;

-- Query 8.3: Delete menu item
-- Related UI: Admin - "Delete" button next to menu item
-- Purpose: Remove item from menu
DELETE FROM menu_items 
WHERE item_id = 5;

-- Query 8.4: Get all orders with totals
-- Related UI: Admin - Revenue table
-- Purpose: Display all orders for sales tracking
SELECT 
    o.order_id,
    CONCAT('Table ', o.table_number) as table_id,
    o.total_amount,
    o.status,
    TO_CHAR(o.order_time, 'HH24:MI:SS') as time
FROM orders o
ORDER BY o.order_time DESC;

-- Query 8.5: Calculate total revenue
-- Related UI: Admin - Revenue display
-- Purpose: Sum all order totals
SELECT 
    COALESCE(SUM(total_amount), 0) as total_revenue
FROM orders;

-- Query 8.6: Calculate revenue by status
-- Related UI: Admin - Revenue breakdown
-- Purpose: Show revenue split by order status
SELECT 
    status,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue
FROM orders
GROUP BY status
ORDER BY status;

-- Query 8.7: Reset all sales data
-- Related UI: Admin - "Reset Sales" button
-- Purpose: Clear all orders (CASCADE deletes order_items)
DELETE FROM orders;

-- Query 8.8: Get top-selling items
-- Related UI: Admin - Analytics (if implemented)
-- Purpose: Show most popular menu items
SELECT 
    m.item_name,
    SUM(oi.quantity) as total_sold,
    SUM(oi.subtotal) as revenue
FROM order_items oi
JOIN menu_items m ON oi.item_id = m.item_id
GROUP BY m.item_id, m.item_name
ORDER BY total_sold DESC
LIMIT 10;

-- ============================================
-- SECTION 9: ADVANCED QUERIES
-- ============================================

-- Query 9.1: Get daily sales summary
-- Purpose: Revenue grouped by date
SELECT 
    DATE(order_time) as sale_date,
    COUNT(*) as total_orders,
    SUM(total_amount) as daily_revenue
FROM orders
WHERE status = 'Fulfilled'
GROUP BY DATE(order_time)
ORDER BY sale_date DESC;

-- Query 9.2: Get average order value
-- Purpose: Calculate average spending per order
SELECT 
    AVG(total_amount) as avg_order_value,
    MIN(total_amount) as min_order,
    MAX(total_amount) as max_order
FROM orders;

-- Query 9.3: Get orders by table with status
-- Purpose: See all tables' current orders
SELECT 
    table_number,
    COUNT(*) as active_orders,
    SUM(total_amount) as table_total,
    status
FROM orders
WHERE status != 'Fulfilled'
GROUP BY table_number, status
ORDER BY table_number;

-- Query 9.4: Get menu items with order count
-- Purpose: Show how many times each item has been ordered
SELECT 
    m.item_name,
    m.price,
    COUNT(oi.order_item_id) as times_ordered,
    COALESCE(SUM(oi.quantity), 0) as total_quantity_sold
FROM menu_items m
LEFT JOIN order_items oi ON m.item_id = oi.item_id
GROUP BY m.item_id, m.item_name, m.price
ORDER BY total_quantity_sold DESC;

-- ============================================
-- SECTION 10: MAINTENANCE QUERIES
-- ============================================

-- Query 10.1: View all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Query 10.2: Count records in each table
SELECT 
    (SELECT COUNT(*) FROM categories) as categories_count,
    (SELECT COUNT(*) FROM menu_items) as menu_items_count,
    (SELECT COUNT(*) FROM orders) as orders_count,
    (SELECT COUNT(*) FROM order_items) as order_items_count;

-- Query 10.3: Check foreign key constraints
SELECT
    tc.table_name, 
    tc.constraint_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY';

-- Query 10.4: View all indexes
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ============================================
-- SECTION 11: DATA VALIDATION QUERIES
-- ============================================

-- Query 11.1: Find orders with mismatched totals
-- Purpose: Data integrity check
SELECT 
    o.order_id,
    o.total_amount as recorded_total,
    SUM(oi.subtotal) as calculated_total,
    o.total_amount - SUM(oi.subtotal) as difference
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING o.total_amount != SUM(oi.subtotal);

-- Query 11.2: Find menu items without a category
-- Purpose: Data integrity check
SELECT item_id, item_name
FROM menu_items
WHERE category_id IS NULL;

-- Query 11.3: Find orders without items
-- Purpose: Data integrity check
SELECT o.order_id, o.table_number, o.total_amount
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_item_id IS NULL;