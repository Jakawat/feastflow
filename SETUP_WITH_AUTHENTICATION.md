# FEASTFLOW - Setup Guide with Authentication

## 🔐 New Features

Your app now has a proper login system that matches your ERD model!

- ✅ Landing page with role selection
- ✅ Customer access (no login required)
- ✅ Kitchen Staff login (username/password)
- ✅ Admin login (username/password)
- ✅ No more URL hashes (#/kitchen, #/admin)
- ✅ Proper authentication matching your ERD

## 📦 Quick Setup (5 Steps)

### Step 1: Create Database with Users Table

1. Open **pgAdmin4**
2. If you already have `feastflow_db`, **DROP IT** and recreate:
   ```sql
   DROP DATABASE IF EXISTS feastflow_db;
   CREATE DATABASE feastflow_db;
   ```
3. Open Query Tool on the NEW `feastflow_db`
4. Copy and run the entire `database-with-auth.sql` file
5. Verify you see 5 tables:
   - ✅ users
   - ✅ categories
   - ✅ menu_items
   - ✅ orders
   - ✅ order_items

### Step 2: Update Backend Database Password

1. Open `backend/server.js`
2. Line ~20: Change `password: 'your_password'` to your PostgreSQL password
3. Save the file

### Step 3: Install & Start Backend

```bash
cd backend
npm install
npm start
```

You should see:
```
✅ Database connected successfully
🚀 Server running on http://localhost:5000
```

### Step 4: Install & Start Frontend

Open a NEW terminal:

```bash
cd Feastflow-main
npm install
npm run dev
```

### Step 5: Test the App

Open browser: `http://localhost:5173/`

You should see a beautiful landing page with:
- 🍽️ Big "I'm a Customer" button
- Small "Kitchen Staff Login" and "Admin Login" links

## 🔑 Default Login Credentials

### Admin Login:
- **Username:** `admin`
- **Password:** `admin123`

### Kitchen Staff Login:
- **Username:** `kitchen`
- **Password:** `kitchen123`

## 🎯 User Flow

### Customer Flow:
1. Click "I'm a Customer" button
2. Enter table number
3. Browse menu and order
4. Click "Exit" to return to landing page

### Kitchen Staff Flow:
1. Click "Kitchen Staff Login"
2. Enter username: `kitchen` password: `kitchen123`
3. View and manage orders
4. Click "Logout" to return to landing page

### Admin Flow:
1. Click "Admin Login"
2. Enter username: `admin` password: `admin123`
3. Manage menu items and view revenue
4. Click "Logout" to return to landing page

## 📊 What Changed

### Database:
- Added `users` table with username, password, role
- Two default users: admin and kitchen

### Frontend:
- ✅ New `Login.jsx` component with beautiful UI
- ✅ Role selection screen
- ✅ Separate login forms for admin/kitchen
- ✅ Logout buttons for all roles
- ❌ Removed URL hash navigation (#/kitchen, #/admin)

### Backend:
- ✅ Added authentication endpoints
- ✅ Login validation
- ✅ Simple token-based auth

## 🎤 For Your Presentation

### Show Your ERD:
Point to the **User** entity and explain:

> "Our system has role-based authentication. The User table stores credentials for Admin and Kitchen Staff. Customers don't need login - they just enter their table number."

### Demo the Flow:

1. **Landing Page**
   - Show the role selection screen
   - Explain: "Customer button is prominent for easy access"

2. **Customer Access**
   - Click "I'm a Customer"
   - Show: No login required, just table number

3. **Staff Login**
   - Go back
   - Click "Kitchen Staff Login"
   - Enter credentials (show on screen)
   - Show SQL: `SELECT * FROM users WHERE username = 'kitchen'`

4. **Kitchen View**
   - Demonstrate order management
   - Show Logout button

5. **Admin Login**
   - Click Logout
   - Login as Admin
   - Show menu management
   - Show SQL: `SELECT * FROM users WHERE username = 'admin' AND role = 'admin'`

## 🗄️ SQL Queries to Show

### For Login (Kitchen/Admin):
```sql
-- Verify user credentials
SELECT user_id, username, role 
FROM users 
WHERE username = 'kitchen' 
  AND password = 'kitchen123'
  AND role = 'kitchen';
```

### Check All Users:
```sql
SELECT user_id, username, role, created_at 
FROM users 
ORDER BY user_id;
```

### View User Activity (if tracking):
```sql
-- This shows admin manages menu
SELECT u.username, u.role, COUNT(m.item_id) as items_managed
FROM users u
CROSS JOIN menu_items m
WHERE u.role = 'admin'
GROUP BY u.username, u.role;
```

## 🔒 Security Notes

**Current Implementation (For Demo):**
- Passwords stored as plain text
- Simple token-based auth
- Perfect for academic presentation

**Production Recommendations:**
- Use bcrypt for password hashing
- Use JWT (JSON Web Tokens)
- Add HTTPS
- Add session timeout
- Add password reset functionality

## 🐛 Troubleshooting

### "Invalid credentials" error:
- Check you're using correct username/password
- Verify `users` table exists: `SELECT * FROM users;`
- Check role matches (admin for admin, kitchen for kitchen)

### Landing page not showing:
- Clear browser cache (Ctrl+Shift+R or Cmd+Shift+R)
- Check browser console for errors
- Verify frontend is running on port 5173

### Backend connection error:
- Ensure backend is running on port 5000
- Check PostgreSQL password in server.js
- Verify database name is `feastflow_db`

## 📸 Screenshots to Take for Presentation

1. **Landing Page** - Role selection screen
2. **Customer Flow** - Table number entry
3. **Kitchen Login** - Login form
4. **Kitchen Dashboard** - Order queue
5. **Admin Login** - Login form  
6. **Admin Dashboard** - Menu management
7. **pgAdmin Query** - SELECT from users table
8. **ERD Diagram** - With User entity highlighted

## ✅ Matches Your ERD

Your ERD shows:
- ✅ User entity (user_id, username, password, role)
- ✅ Admin ISA User
- ✅ Kitchen Staff ISA User
- ✅ Customer (represented by table_number, no login)

Your implementation now has:
- ✅ users table in database
- ✅ Login system for Admin and Kitchen
- ✅ No login for Customers
- ✅ Role-based access control

Perfect alignment! 🎉

## 🚀 You're Ready!

Your app now has:
- Professional authentication system
- Beautiful landing page
- Proper role separation
- Database matching your ERD
- Ready for demo and submission

Good luck with your presentation! 🌟
