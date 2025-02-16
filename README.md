# Lineserver

Lineserver is a **file storage and retrieval** system that allows users to **upload, view, and fetch specific lines from files**.  
It uses **Redis caching** for performance optimization and **rate limiting** to handle large user loads efficiently.

## 🚀 Getting Started

Follow these steps to set up and run the application.

---

## 📌 **System Requirements**

### **Ruby & Rails Versions**
- **Ruby**: `3.3.0`
- **Rails**: `8.0.1`
- Use **RVM** or **rbenv** to install the correct Ruby version.

```sh
rvm install 3.3.0
rvm use 3.3.0 --default
gem install rails -v 8.0.1
```

### **Dependencies**
- **PostgreSQL** (Database)
- **Redis** (Caching & Rate Limiting)

---

## 🛠 **Installation Steps**

### **1️⃣ Install Redis**
The application uses **Redis** for caching and rate limiting.

#### **Mac (Using Homebrew)**
```sh
brew install redis
brew services start redis
```

#### **Ubuntu/Debian**
```sh
sudo apt update
sudo apt install redis-server
sudo systemctl enable redis
sudo systemctl start redis
```

#### **Verify Redis is Running**
```sh
redis-cli ping
# Should return: PONG
```

### **2️⃣ Install PostgreSQL**
Ensure **PostgreSQL** is installed.

#### **Mac (Using Homebrew)**
```sh
brew install postgresql
brew services start postgresql
```

#### **Ubuntu/Debian**
```sh
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### **Create a Database User & Database**
```sh
psql postgres
CREATE USER lineserver WITH PASSWORD 'password';
ALTER ROLE lineserver SET client_encoding TO 'utf8';
ALTER ROLE lineserver SET default_transaction_isolation TO 'read committed';
ALTER ROLE lineserver SET timezone TO 'UTC';
CREATE DATABASE lineserver_development OWNER lineserver;
\q
```

### **3️⃣ Install Dependencies**
```sh
bundle install
```

---

## 🛂 **Database Setup**
```sh
rails db:create db:migrate db:seed
```

---

## 🏃‍♂️ **Running the Application**
```sh
rails s
```
Access it at: [http://localhost:3000](http://localhost:3000)

---

## 🐟 **Swagger API Documentation**
This app uses **Swagger UI** for API documentation.

- Start the server (`rails s`)
- Open Swagger UI at:  
  👉 [http://localhost:3000/api-docs](http://localhost:3000/api-docs)

You can interact with the API directly from the browser.

---

## 🎨 **Bootstrap & Frontend**
This project uses **Bootstrap 5.3.3** for UI styling.

- **Bootstrap is loaded via CDN**, so no extra setup is needed.
- All frontend files are located in `app/views/file_uploads`.

---

## 🚀 **Performance Optimizations**
### **🔹 Redis Caching**
- **Cached File List**: File metadata is stored in **Redis** for **faster retrieval**.
- **Cached Line Lookups**: Specific lines from large files are **stored in Redis**, avoiding unnecessary file reads.

### **🔹 Rate Limiting**
- **Prevents abuse** by limiting the number of requests per minute.
- Limits:
  - **100 requests per IP per minute** (`/file_uploads`)
  - **20 file uploads per minute** (`POST /file_uploads`)
  - **50 file line retrievals per 10 minutes** (`GET /file_uploads/:id/line/:line`)
- If the limit is exceeded, **HTTP 429 (Too Many Requests)** is returned.

---

## 🛠 How Does the System Work?
- Users can upload **text files**.
- File metadata (name, size, line count) is **stored in the database**.
- File **line lookups** are optimized with **Redis caching**.
- **Rate limiting** prevents system abuse.

---

## 📈 Performance Considerations
#### **Handling Large Files**
| File Size  | Performance Consideration |
|------------|---------------------------|
| **1 GB**   | Efficiently handled via **Redis caching**. Only requested lines are read. |
| **10 GB**  | Redis prevents excessive disk reads, but optimizations are needed. |
| **100 GB** | **AWS S3** or similar storage is required. Local disk operations would be too slow. |

#### **Scaling with More Users**
| Users       | Performance Consideration |
|------------|---------------------------|
| **100**    | No issues. DB & Redis handle it well. |
| **10,000** | **Rate limiting** is essential. Redis reduces DB load. |
| **1,000,000** | **Horizontal scaling** needed (load balancers, database optimization, CDN for file storage). |

---

## 📚 References & Research
- **Redis Documentation**: https://redis.io/docs/
- **Rate Limiting Strategies**: https://dev.to/joelbonetr/rate-limiting-strategies-4h80
- **PostgreSQL Indexing & Optimization**: https://www.postgresql.org/docs/
- **Rails File Uploads Best Practices**: https://guides.rubyonrails.org/active_storage_overview.html

---

## 🛠 Third-Party Libraries & Tools
- **Redis**: Chosen for **caching** and **rate limiting** to improve system speed.
- **Bootstrap**: Used for a simple and modern UI without extra frontend work.
- **Swagger (Rswag)**: Helps document and test APIs in an interactive way.
- **Oj**: Optimized JSON parsing, reducing serialization time.

---

## ⏳ Development Time & Next Steps
- **Development Time:** 1 working day. (Concept, Improvements, Incompatibilities)
- **If given more time, priorities would be:**
  1. **User Authentication** – Implement **Devise** for user management.
  2. **AWS S3 Integration** – Store files remotely for **scalability**.
  3. **Background Processing** – Optimize large file processing with **ActiveJob**.
  4. **Per-User Rate Limits** – Instead of IP-based limits, enforce per-user throttling.

---

## 🧐 Code Review & Self-Critique
- ✅ **Strengths**: Clean architecture, optimized **Redis caching**, well-documented API.
- ❗ **Improvements**:
  - **Move file storage to AWS S3** to scale beyond local disk limitations.
  - **Implement authentication** to allow user-specific file access.
  - **Optimize queries** for large datasets and indexed searches.

---

## 📌 **Contributing**
Pull requests are welcome! For major changes, please open an issue first.

---

## 📄 **License**
MIT License – free to use & modify.

---

Happy coding! 🚀

